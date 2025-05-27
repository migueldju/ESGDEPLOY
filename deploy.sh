#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
echo "🚀 Desplegando ESGenerator en proyecto: $PROJECT_ID"

# Verificar que estamos en el directorio correcto
if [ ! -f "Dockerfile" ] || [ ! -d "frontend" ] || [ ! -d "backend" ]; then
    echo "❌ Error: Ejecutar desde el directorio raíz del proyecto"
    exit 1
fi

# Construir frontend
echo "🔨 Construyendo frontend..."
cd frontend
npm ci
npm run build
cd ..

# Copiar frontend al backend
echo "📁 Copiando frontend construido..."
rm -rf backend/build
cp -r frontend/dist backend/build

# Verificar archivos necesarios
echo "✅ Verificando archivos..."
if [ ! -f "backend/app.yaml" ]; then
    echo "❌ Error: backend/app.yaml no encontrado"
    exit 1
fi

# Inicializar base de datos (solo si es necesario)
echo "🗄️ Inicializando base de datos..."
cd backend
python init_db.py

# Desplegar
echo "🚀 Desplegando a App Engine..."
gcloud app deploy app.yaml --quiet

echo "✅ ¡Despliegue completado!"
echo "🌐 URL: https://$PROJECT_ID.appspot.com"

# Abrir en navegador
gcloud app browse