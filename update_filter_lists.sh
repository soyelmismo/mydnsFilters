#!/bin/bash

# Archivo con URLs de blocklists
URL_FILE="/app/blocklists.txt"

# Verificar si el archivo existe
if [[ ! -f "$URL_FILE" ]]; then
  echo "El archivo con las URLs no existe."
  exit 1
fi

# Leer las URLs del archivo y asignarlas al array
readarray -t BLOCKLIST_URLS < "$URL_FILE"


# Directorios y archivos
DOWNLOAD_DIR="/app/blocklists"
OUTPUT_FILE="/app/unified.txt"

# Crear el directorio de descarga si no existe
mkdir -p "$DOWNLOAD_DIR"

echo "Inicio del procesamiento: $(date)"

# Descargar las blocklists
echo "Descargando blocklists..."
for url in "${BLOCKLIST_URLS[@]}"; do
  echo "Descargando $url"
  wget -q -O "$DOWNLOAD_DIR/$(echo "$url" | tr -cd '[:alnum:]_' | tr '/' '_' | tr '[:upper:]' '[:lower:]').txt" "$url"
done
echo "Descarga completada."

# Convertir todas las entradas al formato AdBlock
echo "Convirtiendo listas híbridas al formato AdBlock..."

awk '
# Ignorar comentarios, líneas vacías y entradas mal formateadas
/^(#|!|$)/ { next }
/^[[:space:]]*$/ { next }

# Convertir formato hosts (0.0.0.0 o 127.0.0.1 seguido de un dominio)
/^(0\.0\.0\.0|127\.0\.0\.1)[[:space:]]+([a-zA-Z0-9.-]+)([[:space:]]+.*)?$/ {
  print "||" $2 "^"
  next
}

# Detectar y descartar líneas inválidas (IP solas o caracteres extraños)
$0 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ { next }

# Convertir dominios simples al formato AdBlock
/^[a-zA-Z0-9.-]+$/ {
  print "||" $1 "^"
  next
}

# Mantener líneas válidas de AdBlock tal cual
/^(\|\|[a-zA-Z0-9.-]+\^.*)$/ { print; next }

/^(\|\|[a-zA-Z0-9.-]+)/ &&! /\$$/ {
  print $0 "^"
  next
}

# Todo lo demás es inválido y se ignora
{ next }
' "$DOWNLOAD_DIR"/*.txt | sort -u > "$DOWNLOAD_DIR/all_entries_adblock.txt"


# Conversión completada
echo "Conversión completada."
# Número de hilos a usar
THREADS=$(nproc)

# Dividir el archivo en fragmentos
echo "Dividiendo el archivo en fragmentos para procesamiento paralelo..."
split -l $(echo "scale=0; $(wc -l < "$DOWNLOAD_DIR/all_entries_adblock.txt") / $THREADS" | bc) "$DOWNLOAD_DIR/all_entries_adblock.txt" "$DOWNLOAD_DIR/fragment_"

# Ejecutar el script Python para procesar los fragmentos y deduplicar
echo "Procesando fragmentos en paralelo con $THREADS hilos..."
python3 /app/deduplicate.py "$DOWNLOAD_DIR/fragment_"* "$OUTPUT_FILE"

# Comprobación de resultados
grep -Eo '\|\|[a-z0-9.-]+\^' "$OUTPUT_FILE" | sort | uniq -d

# Eliminar directorio de descargas temporal
rm -rf "$DOWNLOAD_DIR"

# Finalizar
echo "Deduplicación avanzada completada. Archivo optimizado disponible en $OUTPUT_FILE"
