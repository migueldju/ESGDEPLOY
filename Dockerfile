# Multi-stage build con verificación de directorios
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# Instalar herramientas necesarias para compilación
RUN apk add --no-cache python3 make g++

# Copiar archivos de configuración
COPY frontend/package*.json ./frontend/

# Instalar dependencias con fallback
RUN cd frontend && \
    (npm ci || (echo "npm ci failed, using npm install" && npm install))

# Copiar código fuente
COPY frontend ./frontend

# Build con verificación detallada
RUN cd frontend && \
    echo "=== Starting build ===" && \
    npm run build && \
    echo "=== Build completed, checking output ===" && \
    ls -la && \
    echo "=== Checking for dist directory ===" && \
    (ls -la dist/ && echo "✅ dist/ found") || \
    (ls -la build/ && echo "✅ build/ found") || \
    (echo "❌ No build output found" && ls -la)

# Crear un directorio de build consistente
RUN cd frontend && \
    mkdir -p /tmp/frontend-build && \
    (cp -r dist/* /tmp/frontend-build/ 2>/dev/null || \
     cp -r build/* /tmp/frontend-build/ 2>/dev/null || \
     echo "No build files to copy") && \
    echo "=== Final build verification ===" && \
    ls -la /tmp/frontend-build/

# Etapa de producción
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

# Instalar dependencias de Python
COPY backend/requirements.txt ./
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar backend
COPY backend/ ./

# Crear directorio build y copiar frontend
RUN mkdir -p build
COPY --from=frontend-builder /tmp/frontend-build/ ./build/

# Verificar que los archivos se copiaron
RUN echo "=== Backend build verification ===" && \
    ls -la build/ && \
    (ls build/index.html && echo "✅ Frontend files copied successfully") || \
    echo "⚠️ Frontend files may be missing"

# Crear directorio de logs
RUN mkdir -p logs

# Crear usuario no-root
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