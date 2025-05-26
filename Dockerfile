# Multi-stage build con npm install
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# Instalar dependencias del sistema para npm
RUN apk add --no-cache python3 make g++

# Copiar archivos de configuración de npm
COPY frontend/package*.json ./frontend/

# Usar npm install en lugar de npm ci para ser más permisivo
RUN cd frontend && \
    npm cache clean --force && \
    npm install

# Copiar código fuente del frontend
COPY frontend ./frontend

# Build del frontend
RUN cd frontend && npm run build

# Etapa de producción con Python
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONOPTIMIZE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar y instalar dependencias de Python
COPY backend/requirements.txt ./
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar código del backend
COPY backend/ ./

# Copiar frontend compilado desde la etapa anterior
COPY --from=frontend-builder /app/frontend/dist ./build

# Crear directorio de logs
RUN mkdir -p logs

# Crear usuario no-root para seguridad
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

EXPOSE 8080

CMD exec gunicorn \
    --bind 0.0.0.0:$PORT \
    --workers 2 \
    --worker-class sync \
    --worker-connections 1000 \
    --timeout 300 \
    --keepalive 5 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --preload \
    --access-logfile - \
    --error-logfile - \
    --log-level info \
    app:app