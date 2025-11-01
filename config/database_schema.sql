--
-- Esquema de la base de datos para cleodocker
--

-- Tabla de usuarios para la autenticación del panel web
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para el catálogo de software
CREATE TABLE IF NOT EXISTS software_catalog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    docker_image TEXT NOT NULL,
    compose_fragment TEXT NOT NULL, -- Fragmento YAML de Docker Compose
    version TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para registrar las aplicaciones instaladas por el usuario
CREATE TABLE IF NOT EXISTS installed_software (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    catalog_id INTEGER,
    container_name TEXT NOT NULL,
    install_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'installed',
    FOREIGN KEY (catalog_id) REFERENCES software_catalog(id)
);

-- Tabla de logs del sistema para auditoría y monitorización
CREATE TABLE IF NOT EXISTS system_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    level TEXT NOT NULL, -- INFO, WARN, ERROR, CRITICAL
    source TEXT NOT NULL, -- e.g., 'web_app', 'cli', 'installer'
    message TEXT NOT NULL,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla de configuración clave-valor
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Insertar configuraciones iniciales
INSERT OR IGNORE INTO settings (key, value) VALUES ('app_version', '1.0.0');
INSERT OR IGNORE INTO settings (key, value) VALUES ('auto_update', 'false');

-- Poblar el catálogo con algunos ejemplos (se deberían añadir muchos más)
INSERT OR IGNORE INTO software_catalog (name, category, description, docker_image, compose_fragment) VALUES
('Portainer', 'Containers', 'Herramienta de gestión de contenedores Docker.', 'portainer/portainer-ce:latest', 
'portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  ports:
    - "9443:9443"
    - "8000:8000"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - portainer_data:/data
  restart: unless-stopped
volumes:
  portainer_data:'),
('Uptime Kuma', 'Monitoring', 'Herramienta de monitorización de estado de servicios.', 'louislam/uptime-kuma:1',
'uptime-kuma:
  image: louislam/uptime-kuma:1
  container_name: uptime-kuma
  ports:
    - "3001:3001"
  volumes:
    - uptime_kuma_data:/app/data
  restart: unless-stopped
volumes:
  uptime_kuma_data:');

-- Añadir más inserts para las 20 categorías y 200+ apps...