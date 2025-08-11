@echo off
REM Crear carpeta raíz
set ROOT=wordpress-docker-compose-pro-lab
mkdir %ROOT%

REM Crear archivos en la raíz
type nul > %ROOT%\docker-compose.yml
type nul > %ROOT%\.env
type nul > %ROOT%\install.sh
type nul > %ROOT%\backup.sh
type nul > %ROOT%\restore.sh
type nul > %ROOT%\generate-ssl.sh

REM Crear subdirectorios de WordPress
mkdir %ROOT%\wordpress
mkdir %ROOT%\wordpress\themes
mkdir %ROOT%\wordpress\plugins
mkdir %ROOT%\wordpress\uploads
mkdir %ROOT%\wordpress\mu-plugins

REM Crear subdirectorios de configuración
mkdir %ROOT%\config
mkdir %ROOT%\config\nginx
mkdir %ROOT%\config\php

REM Crear carpetas adicionales
mkdir %ROOT%\backups
mkdir %ROOT%\logs
mkdir %ROOT%\ssl

echo Estructura creada correctamente en %ROOT%
pause
