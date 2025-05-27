# Dockerfile simplificado - todo en una imagen
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONOPTIMIZE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Instalar Node.js y dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libpq-dev \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verificar instalaciones
RUN node --version && npm --version && python --version

# Copiar y build frontend
COPY frontend/ ./frontend/
RUN cd frontend && \
    npm install && \
    npm run build && \
    echo "Build completed, checking output:" && \
    ls -la && \
    (ls -la dist/ || ls -la build/ || echo "No build directory found")

# Instalar dependencias de Python
COPY backend/requirements.txt ./
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar backend
COPY backend/ ./

# Mover frontend build al lugar correcto
RUN mkdir -p build && \
    (cp -r frontend/dist/* build/ 2>/dev/null || \
     cp -r frontend/build/* build/ 2>/dev/null || \
     echo "No frontend build to copy") && \
    echo "Final build check:" && \
    ls -la build/

# Limpiar frontend source y node_modules para reducir tamaño
RUN rm -rf frontend/

# Crear logs directory
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