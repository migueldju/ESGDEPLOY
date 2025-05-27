#!/bin/bash
set -e

echo "🔨 Construyendo frontend..."
cd frontend
npm ci
npm run build

echo "📁 Copiando archivos de frontend..."
cd ..
rm -rf backend/build
cp -r frontend/dist backend/build

echo "📦 Preparando backend..."
cd backend

echo "✅ ¡Construcción completada!"