# Dockerfile temporal - Solo backend con frontend estático mínimo
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

# Crear frontend mínimo funcional
RUN mkdir -p build && \
    cat > build/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESGenerator</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f7fa; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2a66b3; text-align: center; }
        .message { background: #e7f3ff; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .api-link { background: #2a66b3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
        .status { color: green; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>ESGenerator Backend</h1>
        <div class="message">
            <p><strong class="status">✅ Backend is running successfully!</strong></p>
            <p>The backend API is available and ready to serve requests.</p>
            <p>Frontend build is temporarily disabled to resolve deployment issues.</p>
        </div>
        
        <h3>Available API Endpoints:</h3>
        <ul>
            <li><a href="/api/check-auth" class="api-link">Check Authentication</a></li>
            <li><a href="/api/health" class="api-link">Health Check</a></li>
        </ul>
        
        <div class="message">
            <p><strong>Note:</strong> This is a temporary page. The full React frontend will be restored once build issues are resolved.</p>
        </div>
    </div>

    <script>
        // Simple JS to test API connectivity
        fetch('/api/check-auth')
            .then(response => response.json())
            .then(data => console.log('API Response:', data))
            .catch(error => console.error('API Error:', error));
    </script>
</body>
</html>
EOF

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