#!/bin/bash
# build-for-cloud.sh - Build script para deployment en Google Cloud

echo "🚀 Preparing for Google Cloud deployment..."

# Crear directorio de build si no existe
mkdir -p backend/build

# Build del frontend
echo "📦 Building frontend..."
cd frontend

# Instalar dependencias
echo "  Installing dependencies..."
npm ci

# Build del frontend
echo "  Building React app..."
npm run build

# Verificar que el build se creó
if [ ! -d "dist" ] && [ ! -d "build" ]; then
    echo "❌ Frontend build failed - no dist or build directory found"
    exit 1
fi

# Copiar archivos built al backend
echo "  Copying built files..."
if [ -d "dist" ]; then
    cp -r dist/* ../backend/build/
    echo "  ✅ Copied from dist/"
elif [ -d "build" ]; then
    cp -r build/* ../backend/build/
    echo "  ✅ Copied from build/"
fi

cd ..

# Verificar que los archivos se copiaron
if [ ! -f "backend/build/index.html" ]; then
    echo "❌ Frontend files not copied correctly"
    exit 1
fi

echo "✅ Frontend build completed and copied to backend/build/"

# Limpiar node_modules del frontend para reducir tamaño
echo "🧹 Cleaning up frontend node_modules..."
rm -rf frontend/node_modules

echo "🎉 Build preparation completed successfully!"
echo "📋 Ready for deployment:"
echo "  - Frontend built and copied to backend/build/"
echo "  - Frontend node_modules removed"
echo "  - Ready for Docker build"