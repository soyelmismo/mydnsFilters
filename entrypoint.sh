#!/bin/bash

# Función para manejar errores
handle_error() {
  local lineno=$1
  local msg=$2
  echo "Error occurred at line $lineno: $msg"
  # Puedes agregar aquí más lógica de manejo de errores si es necesario
}

# Configurar trap para manejar errores
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

chmod +x /app/*.sh
# Configuración del cron según las variables de entorno
CRON_MINUTES=${CRON_MINUTES:-0}
CRON_HOURS=${CRON_HOURS:-*/12}
CRON_DOM=${CRON_DOM:-*}
CRON_MONTH=${CRON_MONTH:-*}
CRON_DOW=${CRON_DOW:-*}

# Validar valores de CRON
if ! [[ $CRON_MINUTES =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_HOURS =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_DOM =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_MONTH =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_DOW =~ ^[0-9*,]+$ ]]; then
    echo "Error en los valores de CRON" >&2
    exit 1
fi
# Establecer tarea de cron
crontab -r

cron_job="$CRON_MINUTES $CRON_HOURS $CRON_DOM $CRON_MONTH $CRON_DOW /app/update_filter_lists.sh"
echo "$cron_job" | crontab -

# Iniciar el demonio de cron
crond -f &

# Ejecutar al iniciar contenedor
/app/update_filter_lists.sh

# Mantener el contenedor corriendo
tail -f /dev/null
