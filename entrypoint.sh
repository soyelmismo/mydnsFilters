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
CRON_MINUTES=${CRON_MINUTES:-*/2}
CRON_HOURS=${CRON_HOURS:-*}
CRON_DOM=${CRON_DOM:-*}
CRON_MONTH=${CRON_MONTH:-*}
CRON_DOW=${CRON_DOW:-0-6}

# Validar valores de CRON
if ! [[ $CRON_MINUTES =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_HOURS =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_DOM =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_MONTH =~ ^[0-9*/]+$ ]] ||
   ! [[ $CRON_DOW =~ ^[0-9,-]+$ ]]; then
  echo "Error en los valores de CRON" >&2
  exit 1
fi
# Establecer tarea de cron
cron_job="$CRON_MINUTES $CRON_HOURS $CRON_DOM $CRON_MONTH $CRON_DOW /app/entrypoint.sh"
echo "$cron_job" | crontab -

# Verificar si la tarea de cron se instaló correctamente
if [ $? -eq 0 ]; then
  echo "Cron job installed successfully:"
  crontab -l
else
  echo "Failed to install cron job." >&2
  exit 1
fi

# Actualiza las listas de filtrado
echo "Actualizando listas de filtrado..."
/app/update_filter_lists.sh


if [ -f /app/unified.txt ]; then
  # Clonar el repositorio si no existe
  rm -rf /app/repo
  git clone https://github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git /app/repo

  # Cambiar a la ubicación del repositorio
  cd /app/repo

  # Configurar el usuario y correo electrónico
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global credential.helper 'store --file ~/.git-credentials'
  echo "https://${GIT_USER_NAME}:${GIT_TOKEN}@github.com" >> ~/.git-credentials

  # Copiar el archivo /app/unified.txt al directorio del repositorio
  cp /app/unified.txt /app/repo/unified.txt.new

  # Comparar los dos archivos
  if [ -f /app/repo/unified.txt ] && cmp /app/repo/unified.txt /app/repo/unified.txt.new; then
    echo "No hay cambios en unified.txt, no se sube"
  else
    echo "Subiendo cambios al repositorio Git..."
    # Renombrar el archivo antiguo y copiar el nuevo
    mv /app/repo/unified.txt.new /app/repo/unified.txt
    # Agregar el archivo y subir cambios
    git add /app/repo/unified.txt
    git commit -m "Actualización de listas de filtrado"
    git push origin main
  fi
fi

# Mantener el contenedor corriendo
tail -f /dev/null
