#!/bin/bash
# build-for-cloud.sh - Build script para deployment en Google Cloud

echo "🚀 Preparing for Google Cloud deployment..."

# Crear directorio de build si no existe
mkdir -p backend/build

# Build del frontend
# --------------------------
# Etapa 1: Build de frontend
# --------------------------
FROM node:18 AS frontend-builder
WORKDIR /app

# Copiamos solo los archivos necesarios para instalar dependencias y build
COPY frontend/package*.json ./frontend/
RUN cd frontend && npm install

COPY frontend ./frontend
RUN cd frontend && npm run build

# --------------------------
# Etapa 2: Backend con Flask
# --------------------------
FROM python:3.11-slim

# Crear directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema (por ejemplo para psycopg2 o faiss)
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar requerimientos e instalar
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el backend completo
COPY backend/ .

# Copiar los archivos build del frontend (desde la primera etapa)
COPY --from=frontend-builder /app/frontend/dist ./build

# Exponer puerto (Flask suele correr en el 8080 en Cloud Run)
EXPOSE 8080

# Comando para arrancar Flask con gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
