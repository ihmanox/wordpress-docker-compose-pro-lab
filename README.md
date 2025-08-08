# wordpress-docker-compose


proyecto/
├── 📄 docker-compose.yml     # Configuración principal
├── 📄 .env                   # Variables de entorno
├── 🚀 install.sh             # Instalador automático
├── 💾 backup.sh              # Backup automático
├── 🔄 restore.sh             # Restauración automática
├── 🔐 generate-ssl.sh        # Certificados SSL
├── wordpress/                # 🔄 Desarrollo bidireccional
│   ├── themes/              # Temas personalizados
│   ├── plugins/             # Plugins personalizados
│   ├── uploads/             # Archivos subidos
│   └── mu-plugins/          # Must-use plugins
├── config/
│   ├── nginx/               # Configuración Nginx
│   └── php/                 # Configuración PHP
├── backups/                 # Backups automáticos
├── logs/                    # Logs de aplicación
└── ssl/                     # Certificados SSL
