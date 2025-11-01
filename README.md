# 🐳 cleodocker - Instalador Universal Docker

![GitHub](https://img.shields.io/github/license/cazique/cleodocker)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)
![Multiplatform](https://img.shields.io/badge/Platform-macOS%20|%20Linux%20|%20Windows-success)
![Version](https://img.shields.io/badge/Version-1.0.0-orange)

---

## 🌎 Selecciona tu Idioma

| Idioma | English | Español | Français | Deutsch | Italiano |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **Bandera** | [![English](https://img.shields.io/badge/English-blue?style=flat-square)](README_en.md) | [![Español](https://img.shields.io/badge/Español-blue?style=flat-square)](README.md) | [![Français](https://img.shields.io/badge/Français-blue?style=flat-square)](README_fr.md) | [![Deutsch](https://img.shields.io/badge/Deutsch-blue?style=flat-square)](README_de.md) | [![Italiano](https://img.shields.io/badge/Italiano-blue?style=flat-square)](README_it.md) |
| **Enlace** | [🇺🇸 ReadMe](README_en.md) | [🇪🇸 ReadMe](README.md) | [🇫🇷 Lisez-moi](README_fr.md) | [🇩🇪 Liesmich](README_de.md) | [🇮🇹 Leggimi](README_it.md) |

---

**cleodocker** es un instalador inteligente y multiplataforma que automatiza la configuración completa de entornos Docker con un panel de administración web integrado. Diseñado para ser simple, potente y comunitario.

---

## ✨ Características Principales

### 🚀 **Instalación Inteligente**
- ✅ **Auto-detección** de plataforma (macOS, Linux, Windows)
- ✅ **Configuración automática** de recursos (CPU, RAM, disco)
- ✅ **Verificación** de dependencias y requisitos
- ✅ **Instalación** con un solo comando

### 🎯 **Multiplataforma Completa**
```bash
# macOS - Optimizado con Colima y soporte GPU
# Linux - Docker nativo con optimizaciones
# Windows - WSL2 y Docker Desktop opcional
```

### 🖥️ **Panel de Administración Web**
- 📊 **Monitorización en tiempo real** (CPU, RAM, disco, red)
- 🐳 **Gestión visual** de contenedores Docker
- 📝 **Visualización de logs** con filtros avanzados
- 🔒 **Autenticación** segura con 2FA opcional
- 💾 **Sistema de backup/restore** integrado

### 📦 **Catálogo de Software**
20 categorías con las mejores aplicaciones open-source:
| Categoría | Aplicaciones |
|-----------|--------------|
| **🧠 AI/ML** | Ollama, TensorFlow, Jupyter |
| **🗄️ Bases de Datos** | PostgreSQL, MySQL, MongoDB, Redis |
| **📊 Monitoring** | Grafana, Prometheus, Uptime Kuma |
| **🌐 CMS** | WordPress, Directus, Strapi |
| **💾 Storage** | MinIO, Nextcloud, SeaweedFS |
| **🛡️ Security** | Vault, Trivy, CrowdSec |
| **🎮 Gaming** | Minecraft, Terraria, Factorio |
| **📺 Media** | Jellyfin, Plex, PhotoPrism |
*(Y muchas más...)*

---

## 🚀 Instalación Rápida

### **Linux / macOS / WSL**
```bash
curl -fsSL https://raw.githubusercontent.com/cazique/cleodocker/main/install.sh | bash
```

### **Windows PowerShell**
```powershell
irm https://raw.githubusercontent.com/cazique/cleodocker/main/install.ps1 | iex
```

### **Instalación Avanzada**
```bash
# Clonar repositorio
git clone https://github.com/cazique/cleodocker.git
cd cleodocker

# Instalación manual
chmod +x install.sh
./install.sh --advanced
```

---

## 🎮 Uso Rápido

### **Interfaz Web**
```bash
# Acceder al panel web (después de instalación)
cleo web
# ➡️ Abre http://localhost:5000
```

### **Interfaz de Línea de Comandos**
```bash
# Ver estado del sistema
cleo status

# Instalar software del catálogo
cleo install portainer
cleo install ollama

# Gestión de contenedores
cleo containers list
cleo containers start nginx
cleo containers logs mysql

# Backup y restore
cleo backup create
cleo backup restore latest
```

---

## 🏗️ Arquitectura
```
cleodocker/
├── 🐚 install.sh              # Instalador principal
├── ⚡ install.ps1             # Instalador Windows
├── 🖥️ cleo                    # CLI principal
├── 🌐 web/                    # Panel web Flask
│   ├── app.py                # Aplicación principal
│   ├── templates/            # Vistas HTML
│   └── static/               # CSS, JS, imágenes
├── 🔧 modules/               # Módulos funcionales
│   ├── docker_setup.sh       # Configuración Docker
│   ├── software_catalog.sh   # Gestión catálogo
│   └── colima_manager.sh     # Gestión macOS
└── ⚙️ config/                # Configuración
    ├── database.db           # SQLite
    └── i18n/                 # Traducciones
```

---

## 🌍 Internacionalización

cleodocker está disponible en 5 idiomas:

- 🇪🇸 **Español** (predeterminado)
- 🇺🇸 **English**
- 🇫🇷 **Français**
- 🇩🇪 **Deutsch**
- 🇮🇹 **Italiano**

```bash
# Cambiar idioma
cleo config set language en
```

---

## 🔧 Características Técnicas

### **✅ Componentes Obligatorios**
- 🐳 Docker Engine + Docker Compose
- 🔥 Firewall configurado automáticamente
- 🔒 SSL/TLS con Let's Encrypt
- 🌐 Proxy reverso (Nginx + Traefik)
- 📊 Sistema de logging centralizado
- 🛡️ Autenticación segura (Authelia)

### **🎛️ Funcionalidades Avanzadas**
- 🔍 **Detección automática de GPU** (NVIDIA, AMD, Intel, Apple Silicon)
- 💾 **Sistema de backup incremental**
- 📱 **Responsive design** (compatible móvil/tablet)
- 🔄 **Actualizaciones automáticas**
- 🧪 **Modo dry-run** para pruebas
- 📈 **Sistema de alertas** por umbrales

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [📖 INSTALL.md](docs/INSTALL.md) | Guía de instalación detallada |
| [🛠️ CLI_REFERENCE.md](docs/CLI_REFERENCE.md) | Referencia completa de comandos |
| [🌐 API_REFERENCE.md](docs/API_REFERENCE.md) | Documentación API panel web |
| [🚀 GETTING_STARTED.md](docs/tutorials/getting_started.md) | Tutorial inicio rápido |
| [🔧 ADVANCED_CONFIG.md](docs/tutorials/advanced_config.md) | Configuración avanzada |

---

## 🤝 Contribuir

¡cleodocker es un proyecto comunitario!

### **¿Cómo contribuir?**
1. 🍴 Haz fork del proyecto
2. 🌿 Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. 💾 Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push a la rama (`git push origin feature/AmazingFeature`)
5. 🔀 Abre un Pull Request

### **Áreas de contribución:**
- 🐛 **Reportar bugs** - [Abrir Issue](https://github.com/cazique/cleodocker/issues)
- 💡 **Sugerir features** - [Ver Discussions](https://github.com/cazique/cleodocker/discussions)
- 🌍 **Traducciones** - Mejorar i18n
- 📦 **Nuevas apps** - Añadir al catálogo

---

## 🛠️ Desarrollo

### **Requisitos de desarrollo**
```bash
# Clonar y configurar
git clone https://github.com/cazique/cleodocker.git
cd cleodocker

# Modo desarrollo
./cleo --dev

# Ejecutar tests
./cleo test
```

### **Estructura para desarrolladores**
```bash
.
├── src/ # Código fuente
├── tests/ # Tests automatizados
├── docs/ # Documentación
├── scripts/ # Scripts de build
└── examples/ # Ejemplos de uso
```

---

## 📊 Estadísticas

![GitHub forks](https://img.shields.io/github/forks/cazique/cleodocker?style=social)
![GitHub stars](https://img.shields.io/github/stars/cazique/cleodocker?style=social)
![GitHub issues](https://img.shields.io/github/issues/cazique/cleodocker)
![GitHub pull requests](https://img.shields.io/github/issues-pr/cazique/cleodocker)

---

## 🆘 Soporte

### **Canales de ayuda:**
- 📖 [Documentación oficial](docs/README.md)
- 💬 [Discussions](https://github.com/cazique/cleodocker/discussions) - Preguntas y respuestas
- 🐛 [Issues](https://github.com/cazique/cleodocker/issues) - Reportar problemas
- 🔧 [Wiki](https://github.com/cazique/cleodocker/wiki) - Guías avanzadas

### **Comandos de diagnóstico:**
```bash
# Ver logs del sistema
cleo logs system

# Diagnóstico completo
cleo diagnose

# Ver información del sistema
cleo system info
```

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

---

## 🙏 Agradecimientos

- **Docker Community** - Por el ecosistema increíble
- **DietPi** - Inspiración para la interfaz TUI
- **CasaOS** - Referencia para el diseño visual
- **Todos los contribuidores** - Que hacen este proyecto posible

---

## 🚀 Próximas Características

- [ ] 🔍 **Motor de búsqueda** en catálogo
- [ ] 📱 **App móvil** companion
- [ ] 🌩️ **Sincronización cloud** de configuraciones
- [ ] 🤖 **Asistente AI** para troubleshooting
- [ ] 🎨 **Temas personalizables** para el panel web

---

<div align="center">
**¿Te gusta cleodocker? ¡Dale una ⭐ al repositorio!**
[![Star History Chart](https://api.star-history.com/svg?repos=cazique/cleodocker&type=Date)](https://star-history.com/#cazique/cleodocker&Date)
</div>
