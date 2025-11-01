#
# web/app.py - Panel de Administración de cleodocker
#
import os
import sqlite3
import json
import docker
from flask import Flask, render_template, jsonify, request, g, session, redirect, url_for, flash
from functools import wraps
import logging
from logging.handlers import RotatingFileHandler
import psutil
import platform
from werkzeug.security import generate_password_hash, check_password_hash
import secrets

# --- Configuración de la Aplicación ---
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(24))
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DATABASE = os.environ.get('DATABASE_PATH', os.path.join(BASE_DIR, '..', 'config', 'cleodocker.db'))
SCHEMA_PATH = os.path.join(BASE_DIR, '..', 'config', 'database_schema.sql')
LOG_DIR = os.path.join(BASE_DIR, '..', 'logs')
LOG_FILE = os.path.join(LOG_DIR, 'cleodocker_web.log')

# --- Configuración de Logging ---
def setup_logging():
    """Configura el sistema de logs estructurados."""
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR)
    handler = RotatingFileHandler(LOG_FILE, maxBytes=10000000, backupCount=5)
    log_format = logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
    )
    handler.setFormatter(log_format)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)

# --- Gestión de la Base de Datos ---
def get_db():
    """Obtiene una conexión a la base de datos."""
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    """Cierra la conexión a la base de datos al final de la petición."""
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def init_db():
    """Inicializa la base de datos con el esquema."""
    with app.app_context():
        db = get_db()
        with app.open_resource(SCHEMA_PATH, mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()
        app.logger.info("Base de datos inicializada.")
        
        # Crear usuario admin por defecto si no existe
        cursor = db.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", ('admin',))
        if cursor.fetchone() is None:
            hashed_password = generate_password_hash('admin')
            cursor.execute(
                "INSERT INTO users (username, password_hash, is_admin) VALUES (?, ?, ?)",
                ('admin', hashed_password, 1)
            )
            db.commit()
            app.logger.info("Usuario 'admin' por defecto creado con contraseña 'admin'. ¡Cámbiala!")

# --- Gestión de Autenticación ---
def login_required(f):
    """Decorador para requerir autenticación en ciertas rutas."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        db = get_db()
        user = db.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()
        
        if user and check_password_hash(user['password_hash'], password):
            session.clear()
            session['user_id'] = user['id']
            session['username'] = user['username']
            app.logger.info(f"Inicio de sesión exitoso para el usuario '{username}'")
            return redirect(url_for('dashboard'))
        else:
            app.logger.warning(f"Intento de inicio de sesión fallido para el usuario '{username}'")
            flash('Credenciales inválidas. Por favor, inténtalo de nuevo.', 'error')
            return render_template('login.html')
            
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Has cerrado sesión.', 'info')
    return redirect(url_for('login'))

# --- Rutas de la Interfaz Web ---
@app.route('/')
@login_required
def dashboard():
    """Renderiza el panel principal."""
    return render_template('dashboard.html')

@app.route('/software')
@login_required
def software():
    """Renderiza el catálogo de software."""
    return render_template('software.html')

@app.route('/logs')
@login_required
def logs_page():
    """Renderiza la página de visualización de logs."""
    return render_template('logs.html')

# --- API Endpoints ---

# API: Estado del Sistema
@app.route('/api/system/status')
@login_required
def system_status():
    """Devuelve el estado actual del sistema (CPU, RAM, Disco)."""
    try:
        cpu_usage = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'cpu_percent': cpu_usage,
            'ram_percent': ram.percent,
            'ram_total_gb': round(ram.total / (1024**3), 2),
            'ram_used_gb': round(ram.used / (1024**3), 2),
            'disk_percent': disk.percent,
            'disk_total_gb': round(disk.total / (1024**3), 2),
            'disk_used_gb': round(disk.used / (1024**3), 2),
            'platform': f"{platform.system()} {platform.release()}",
            'architecture': platform.machine()
        })
    except Exception as e:
        app.logger.error(f"Error al obtener el estado del sistema: {e}")
        return jsonify({'error': str(e)}), 500

# API: Gestión de Contenedores
@app.route('/api/containers')
@login_required
def list_containers():
    """Devuelve una lista de todos los contenedores Docker."""
    try:
        client = docker.from_env()
        containers = client.containers.list(all=True)
        container_list = []
        for c in containers:
            container_list.append({
                'id': c.short_id,
                'name': c.name,
                'image': c.image.tags[0] if c.image.tags else 'N/A',
                'status': c.status,
                'ports': c.ports
            })
        return jsonify(container_list)
    except Exception as e:
        app.logger.error(f"Error al listar contenedores: {e}")
        return jsonify({'error': 'No se pudo conectar al socket de Docker. ¿Está Docker en ejecución?'}), 500

@app.route('/api/containers/<container_id>/<action>', methods=['POST'])
@login_required
def container_action(container_id, action):
    """Ejecuta una acción (start, stop, restart, remove) en un contenedor."""
    try:
        client = docker.from_env()
        container = client.containers.get(container_id)
        
        if action == 'start':
            container.start()
            msg = f"Contenedor {container.name} iniciado."
        elif action == 'stop':
            container.stop()
            msg = f"Contenedor {container.name} detenido."
        elif action == 'restart':
            container.restart()
            msg = f"Contenedor {container.name} reiniciado."
        elif action == 'remove':
            container.remove(force=True)
            msg = f"Contenedor {container.name} eliminado."
        else:
            return jsonify({'error': 'Acción no válida'}), 400
            
        app.logger.info(msg)
        return jsonify({'message': msg})
    except docker.errors.NotFound:
        return jsonify({'error': 'Contenedor no encontrado'}), 404
    except Exception as e:
        app.logger.error(f"Error en la acción '{action}' para el contenedor '{container_id}': {e}")
        return jsonify({'error': str(e)}), 500

# API: Logs
@app.route('/api/logs')
@login_required
def get_app_logs():
    """Devuelve las últimas líneas del log de la aplicación web."""
    try:
        with open(LOG_FILE, 'r') as f:
            lines = f.readlines()
            # Devolver las últimas 100 líneas
            return jsonify({'logs': lines[-100:]})
    except FileNotFoundError:
        return jsonify({'logs': ['Archivo de log no encontrado.']})
    except Exception as e:
        app.logger.error(f"Error al leer el archivo de log: {e}")
        return jsonify({'error': str(e)}), 500

# --- Punto de Entrada de la Aplicación ---
if __name__ == '__main__':
    setup_logging()
    # Crear la base de datos si no existe
    if not os.path.exists(DATABASE):
        try:
            init_db()
        except Exception as e:
            app.logger.critical(f"No se pudo inicializar la base de datos: {e}")
    
    app.logger.info("Iniciando servidor Flask de cleodocker.")
    app.run(host='0.0.0.0', port=5000, debug=True)