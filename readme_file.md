# WordPress con Docker, Nginx y PostgreSQL

![WordPress](https://img.shields.io/badge/WordPress-6.4-blue.svg)
![PHP](https://img.shields.io/badge/PHP-8.3-purple.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-green.svg)
![Nginx](https://img.shields.io/badge/Nginx-1.25-red.svg)
![Docker](https://img.shields.io/badge/Docker-Latest-blue.svg)

Configuración profesional de WordPress optimizada para **servidores Linux y WSL** con las últimas versiones de todas las tecnologías.

## 🚀 Características

✅ **WordPress 6.4** con PHP 8.3-FPM  
✅ **PostgreSQL 16** como base de datos  
✅ **Nginx 1.25** optimizado para alto rendimiento  
✅ **Redis 7** para cache avanzado  
✅ **Adminer** para gestión de base de datos  
✅ **WP-CLI** para administración por línea de comandos  
✅ **Volúmenes bidireccionales** para desarrollo  
✅ **Backup y restauración automática**  
✅ **Configuración SSL/HTTPS** opcional  
✅ **Optimizado para Linux/WSL** con permisos correctos  

## ⚡ Instalación de Un Solo Comando

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/wordpress-docker-pro.git
cd wordpress-docker-pro

# Ejecutar instalación automática
chmod +x install.sh && ./install.sh
```

**¡Eso es todo!** En menos de 5 minutos tendrás WordPress funcionando completamente.

## 📋 Requisitos Previos

- **Docker** 20.10.13+ con Docker Compose
- **Usuario con permisos** de Docker (sin sudo)
- **Linux** o **WSL2** 
- **Puertos disponibles**: 8080, 8090 (configurables)

### Verificar Requisitos

```bash
# Verificar Docker
docker --version
docker compose version

# Verificar permisos (no debe requerir sudo)
docker ps

# Si necesitas permisos:
sudo usermod -aG docker $USER
newgrp docker
```

## ⚙️ Configuración

### Archivo .env (Pre-instalación)

Antes de ejecutar `install.sh`, puedes personalizar estas configuraciones clave en `.env`:

```bash
# Credenciales de base de datos
POSTGRES_USER=tu_usuario
POSTGRES_PASSWORD=tu_password_seguro
POSTGRES_DB=tu_database

# Credenciales de WordPress
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=password_admin_seguro
WP_ADMIN_EMAIL=admin@tusitio.com

# Puertos personalizados
WORDPRESS_PORT=8080      # Puerto para WordPress
ADMINER_PORT=8090        # Puerto para Adminer

# Configuración del proyecto
COMPOSE_PROJECT_NAME=mi-wordpress
```

> **⚠️ IMPORTANTE**: Cambia todas las contraseñas por defecto antes de la instalación

### Configuración Automática

El script `install.sh` configura automáticamente:

- ✅ **Permisos de usuario** (PUID/PGID)
- ✅ **Verificación de puertos**
- ✅ **Estructura de directorios**
- ✅ **Instalación de WordPress**
- ✅ **Configuración de permalinks**
- ✅ **Plugins de desarrollo**
- ✅ **Cache Redis**

## 📁 Estructura del Proyecto

```
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
```

## 🎯 Acceso a Servicios

Una vez instalado:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **WordPress** | http://localhost:8080 | Ver archivo `.env` |
| **Adminer** (DB) | http://localhost:8090 | PostgreSQL / Ver `.env` |
| **HTTPS** | https://localhost:8443 | Solo si SSL habilitado |

## 🔧 Comandos Útiles

### Gestión del Proyecto

```bash
# Ver estado de servicios
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Reiniciar Nginx
docker compose restart nginx

# Acceder via HTTPS
# https://localhost:8443 (aceptar certificado autofirmado)
```

### Para Producción con Let's Encrypt

```bash
# 1. Configurar dominio real en .env
WP_SITE_URL=https://tudominio.com

# 2. Instalar certbot en el servidor
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# 3. Obtener certificado SSL
sudo certbot --nginx -d tudominio.com

# 4. Renovación automática
sudo crontab -e
# Agregar: 0 2 * * * /usr/bin/certbot renew --quiet --post-hook "docker compose restart nginx"
```

## 🎨 Desarrollo de Temas y Plugins

### Desarrollo de Temas

```bash
# Crear nuevo tema
mkdir wordpress/themes/mi-tema-custom
cd wordpress/themes/mi-tema-custom

# Crear style.css básico
cat > style.css << EOF
/*
Theme Name: Mi Tema Custom
Description: Tema personalizado para mi sitio
Version: 1.0
Author: Tu Nombre
*/
EOF

# Crear index.php básico
cat > index.php << EOF
<?php
get_header();
echo '<h1>Mi Tema Personalizado</h1>';
get_footer();
EOF

# El tema aparecerá inmediatamente en WordPress Admin > Apariencia > Temas
```

### Desarrollo de Plugins

```bash
# Crear nuevo plugin
mkdir wordpress/plugins/mi-plugin-custom
cd wordpress/plugins/mi-plugin-custom

# Crear archivo principal del plugin
cat > mi-plugin-custom.php << EOF
<?php
/*
Plugin Name: Mi Plugin Custom
Description: Plugin personalizado para funcionalidades específicas
Version: 1.0
Author: Tu Nombre
*/

// Prevenir acceso directo
if (!defined('ABSPATH')) {
    exit;
}

// Hook de activación
register_activation_hook(__FILE__, 'mi_plugin_activar');

function mi_plugin_activar() {
    // Código de activación
}

// Tu código del plugin aquí...
EOF

# El plugin aparecerá inmediatamente en WordPress Admin > Plugins
```

### Hot Reload para Desarrollo

Los cambios en archivos se reflejan **inmediatamente** gracias a los volúmenes bidireccionales:

- ✅ **Temas**: Cambios instantáneos
- ✅ **Plugins**: Cambios instantáneos
- ✅ **Uploads**: Archivos disponibles al momento
- ✅ **Configuración**: Reinicio rápido con `docker compose restart`

## 📊 Monitoreo y Performance

### Logs y Debugging

```bash
# Ver todos los logs
docker compose logs -f

# Logs específicos
docker compose logs -f nginx        # Logs de Nginx
docker compose logs -f wordpress    # Logs de WordPress/PHP
docker compose logs -f postgres     # Logs de PostgreSQL

# Logs de acceso de Nginx
tail -f logs/nginx/access.log

# Logs de error de Nginx
tail -f logs/nginx/error.log
```

### Monitoreo de Performance

```bash
# Estado de contenedores con uso de recursos
docker stats

# Información de PHP-FPM
curl http://localhost:8080/status

# Información de Redis
docker compose exec redis redis-cli info

# Información de PostgreSQL
docker compose exec postgres psql -U usuario -d database -c "SELECT version();"
```

### Optimización de Performance

El proyecto incluye optimizaciones automáticas:

- ✅ **PHP OPCache** habilitado
- ✅ **Redis Cache** para objetos WordPress
- ✅ **Nginx** con compresión Gzip
- ✅ **Buffers** optimizados para archivos grandes
- ✅ **Keep-alive** y conexiones persistentes
- ✅ **Cache** de archivos estáticos con headers correctos

## 🔧 Solución de Problemas Comunes

### Error de Permisos

```bash
# Reconfigurar permisos
sudo chown -R $USER:$USER wordpress/
find wordpress/ -type d -exec chmod 755 {} \;
find wordpress/ -type f -exec chmod 644 {} \;
chmod -R 777 wordpress/uploads
```

### Puerto en Uso

```bash
# Verificar qué usa el puerto
sudo netstat -tulnp | grep :8080
sudo ss -tulnp | grep :8080

# Cambiar puerto en .env
WORDPRESS_PORT=8081

# Reiniciar
docker compose down && docker compose up -d
```

### Problemas de Base de Datos

```bash
# Verificar conexión a PostgreSQL
docker compose exec postgres pg_isready -U usuario

# Reiniciar solo PostgreSQL
docker compose restart postgres

# Recrear base de datos
docker compose exec postgres dropdb -U usuario database_name
docker compose exec postgres createdb -U usuario database_name
```

### Problemas de Cache

```bash
# Limpiar cache de Redis
docker compose exec redis redis-cli FLUSHALL

# Limpiar cache de WordPress
docker compose exec wpcli wp cache flush

# Reiniciar servicios de cache
docker compose restart redis wordpress
```

### Problema de Memoria PHP

```bash
# Editar config/php/custom.ini
memory_limit = 1G

# Reiniciar WordPress
docker compose restart wordpress
```

## 🔄 Actualizaciones y Mantenimiento

### Actualizar WordPress

```bash
# Via WP-CLI (recomendado)
docker compose exec wpcli wp core update
docker compose exec wpcli wp core update-db

# Via Admin Panel
# WordPress Admin > Actualizaciones
```

### Actualizar Imágenes Docker

```bash
# Actualizar todas las imágenes
docker compose pull
docker compose up -d --build

# Actualizar imagen específica
docker compose pull wordpress
docker compose up -d wordpress
```

### Limpieza del Sistema

```bash
# Limpiar imágenes no utilizadas
docker system prune -f

# Limpiar volúmenes huérfanos
docker volume prune -f

# Ver espacio utilizado
docker system df
```

## 🚀 Migración a Producción

### Preparación para Producción

1. **Configuración de Seguridad**:

```bash
# En .env cambiar a producción
WP_DEBUG=false
PHP_DISPLAY_ERRORS=false

# Cambiar todas las contraseñas
# Generar claves WordPress: https://api.wordpress.org/secret-key/1.1/salt/
```

2. **Configuración de SSL**:

```bash
# Usar certificados reales de Let's Encrypt
# Ver sección SSL más arriba
```

3. **Optimización**:

```bash
# Habilitar OPCache en producción
# Configurar backup automático
# Configurar monitoreo
```

### Migrar desde Desarrollo

```bash
# 1. Crear backup en desarrollo
./backup.sh

# 2. Transferir backup al servidor de producción
scp backups/wordpress_backup_*.tar.gz usuario@servidor:/ruta/proyecto/

# 3. En producción, restaurar
./restore.sh wordpress_backup_*.tar.gz
```

## 🤝 Contribuir

Si encuentras mejoras o bugs:

1. Fork del repositorio
2. Crear rama para tu feature: `git checkout -b nueva-feature`
3. Commit de cambios: `git commit -am 'Agregar nueva feature'`
4. Push a la rama: `git push origin nueva-feature`
5. Crear Pull Request

## 📝 Changelog

### v2.0.0
- ✅ Actualizado a WordPress 6.4 + PHP 8.3
- ✅ PostgreSQL 16 Alpine
- ✅ Nginx 1.25 con optimizaciones avanzadas
- ✅ Script de instalación de un solo comando
- ✅ Backup/restore automático
- ✅ Configuración SSL integrada
- ✅ WP-CLI incluido
- ✅ Redis cache integrado

### v1.0.0
- ✅ Configuración inicial básica

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver archivo `LICENSE` para más detalles.

## 🆘 Soporte

Si necesitas ayuda:

1. **Revisa la sección** de solución de problemas
2. **Verifica los logs**: `docker compose logs -f`
3. **Crea un issue** en el repositorio con:
   - Versión de Docker
   - Sistema operativo
   - Logs relevantes
   - Pasos para reproducir el problema

## 🌟 Características Avanzadas

### Multi-Sitio WordPress

```bash
# Habilitar multisite
docker compose exec wpcli wp core multisite-convert

# Configurar subdominios o subdirectorios
# Ver documentación oficial de WordPress Multisite
```

### Desarrollo con HTTPS Local

```bash
# Generar certificados para múltiples dominios
./generate-ssl.sh

# Agregar dominios al /etc/hosts
echo "127.0.0.1 local.miproyecto.dev" | sudo tee -a /etc/hosts
```

### Integración con IDEs

El proyecto es compatible con:

- ✅ **VS Code** con extensiones de PHP/WordPress
- ✅ **PHPStorm** con configuración Docker
- ✅ **Vim/Neovim** con plugins de desarrollo web
- ✅ **Sublime Text** con packages WordPress

---

## 🎉 ¡Listo para Desarrollar!

Con esta configuración tienes un entorno de desarrollo WordPress profesional, escalable y listo para producción.

**¡Disfruta desarrollando! 🚀** servicios
docker compose restart

# Detener proyecto
docker compose down

# Actualizar imágenes
docker compose pull && docker compose up -d --build
```

### WP-CLI (WordPress por línea de comandos)

```bash
# Información de WordPress
docker compose exec wpcli wp --info

# Actualizar WordPress
docker compose exec wpcli wp core update

# Instalar plugin
docker compose exec wpcli wp plugin install contact-form-7 --activate

# Cambiar URL del sitio
docker compose exec wpcli wp option update home 'https://mi-dominio.com'
docker compose exec wpcli wp option update siteurl 'https://mi-dominio.com'

# Crear usuario administrador
docker compose exec wpcli wp user create nuevo_admin admin@email.com --role=administrator

# Limpiar cache
docker compose exec wpcli wp cache flush
```

### Gestión de Base de Datos

```bash
# Backup manual de base de datos
docker compose exec postgres pg_dump -U usuario -d database > backup.sql

# Restaurar base de datos
docker compose exec -T postgres psql -U usuario -d database < backup.sql

# Conectar a PostgreSQL
docker compose exec postgres psql -U usuario -d database
```

## 💾 Backup y Restauración

### Backup Automático

```bash
# Crear backup completo
./backup.sh

# Los backups se guardan en: backups/wordpress_backup_complete_FECHA.tar.gz
```

### Restauración

```bash
# Restaurar backup completo
./restore.sh backups/wordpress_backup_complete_20241209_143022.tar.gz

# Opciones avanzadas
./restore.sh backup.tar.gz --db-only        # Solo base de datos
./restore.sh backup.tar.gz --files-only     # Solo archivos
./restore.sh backup.tar.gz --force          # Sin confirmación
```

## 🔐 Configuración SSL/HTTPS

### Para Desarrollo Local

```bash
# Generar certificados autofirmados
./generate-ssl.sh

# Habilitar SSL en Nginx
# Editar config/nginx/ssl.conf y descomentar configuración

# Reiniciar# WordPress con Docker, Nginx y PostgreSQL

Esta configuración te proporciona un entorno completo de WordPress con:

- **WordPress** con PHP 8.2-FPM
- **Nginx** como servidor web y proxy reverso
- **PostgreSQL** como base de datos
- **phpMyAdmin** y **Adminer** para gestión de base de datos
- **Volúmenes bidireccionales** para desarrollo
- **Configuración personalizada** para subida de archivos grandes

## 🚀 Instalación Rápida

1. **Clona o descarga los archivos** en tu directorio de proyecto

2. **Ejecuta el script de instalación:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **¡Listo!** Accede a WordPress en `http://localhost:8080`

## 📁 Estructura del Proyecto

```
proyecto/
├── docker-compose.yml
├── .env
├── install.sh
├── wordpress/
│   ├── themes/          # Temas personalizados
│   ├── plugins/         # Plugins personalizados  
│   ├── uploads/         # Archivos subidos
│   └── content/         # Contenido adicional
├── config/
│   ├── nginx/
│   │   ├── nginx.conf
│   │   └── default.conf
│   └── php/
│       └── php.ini
└── logs/
```

## 🔧 Configuración

### Variables de entorno (.env)

Edita el archivo `.env` para personalizar:

- **Puertos de acceso**
- **Credenciales de base de datos**
- **Configuración de WordPress**

### Puertos por defecto

- **WordPress**: `http://localhost:8080`
- **phpMyAdmin**: `http://localhost:8081`
- **Adminer**: `http://localhost:8082`

## 🎨 Desarrollo de Temas y Plugins

### Temas
Coloca tus temas en `./wordpress/themes/` y aparecerán automáticamente en WordPress.

### Plugins
Coloca tus plugins en `./wordpress/plugins/` y podrás activarlos desde el panel de administración.

### Archivos subidos
Los archivos que subas desde WordPress se guardarán en `./wordpress/uploads/`

## 📤 Subida de Archivos Grandes

La configuración permite subir archivos de hasta **100MB**:

- PHP: `upload_max_filesize = 100M`
- Nginx: `client_max_body_size 100M`

## 🐳 Comandos Docker Útiles

```bash
# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f wordpress

# Reiniciar servicios
docker-compose restart

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Reconstruir contenedores
docker-compose up -d --build
```

## 🗄️ Gestión de Base de Datos

### Usando Adminer (Recomendado para PostgreSQL)
1. Accede a `http://localhost:8082`
2. Sistema: **PostgreSQL**
3. Servidor: **postgres**
4. Usuario: Según tu `.env`
5. Contraseña: Según tu `.env`
6. Base de datos: Según tu `.env`

### Backup de Base de Datos
```bash
# Crear backup
docker-compose exec postgres pg_dump -U wordpress_user wordpress_db > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U wordpress_user -d wordpress_db < backup.sql
```

## 🛠️ Solución de Problemas

### Permisos de archivos
```bash
sudo chown -R $USER:$USER wordpress/
chmod -R 755 wordpress/
chmod -R 777 wordpress/uploads
```

### Reinstalar WordPress
```bash
docker-compose down -v
docker-compose up -d
```

### Ver logs de errores
```bash
# Logs de Nginx
docker-compose exec nginx cat /var/log/nginx/error.log

# Logs de WordPress
docker-compose logs wordpress
```

## 🔒 Seguridad

Para **producción**, asegúrate de:

1. Cambiar todas las contraseñas por defecto
2. Usar HTTPS con certificados SSL
3. Configurar un firewall
4. Actualizar regularmente los contenedores
5. Hacer backups regulares

## 📝 Notas Importantes

- Los volúmenes son **bidireccionales**: los cambios se reflejan inmediatamente
- La configuración está optimizada para **desarrollo local**
- PostgreSQL se usa como base de datos (más robusta que MySQL)
- Nginx está configurado para **alto rendimiento**

## 🆘 Soporte

Si encuentras problemas:

1. Verifica que Docker y Docker Compose estén instalados
2. Asegúrate de que los puertos no estén en uso
3. Revisa los logs con `docker-compose logs`
4. Verifica los permisos de archivos

¡Disfruta desarrollando con WordPress! 🎉