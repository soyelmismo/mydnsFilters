FROM alpine:latest

WORKDIR /

RUN apk update && \
    apk add --no-cache python3 git bash

# Copiamos los archivos necesarios
COPY . /app/

RUN chmod +x /app/*.sh
