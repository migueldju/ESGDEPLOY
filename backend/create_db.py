import pymysql
import os


try:
    print("🔌 Conectando a Cloud SQL...")
    
    # Conectar sin especificar base de datos
    connection = pymysql.connect(
        host='127.0.0.1',
        port=3306,
        user='root',
        password='lopoleto',
        charset='utf8mb4'
    )
    
    print("✅ Conexión establecida")
    
    with connection.cursor() as cursor:
        print("📋 Verificando bases de datos existentes...")
        cursor.execute("SHOW DATABASES;")
        databases = cursor.fetchall()
        
        db_names = [db[0] for db in databases]
        print(f"Bases de datos encontradas: {db_names}")
        
        if 'esgenerator' not in db_names:
            print("🔨 Creando base de datos 'esgenerator'...")
            cursor.execute("CREATE DATABASE esgenerator CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
            print("✅ Base de datos 'esgenerator' creada exitosamente")
        else:
            print("✅ Base de datos 'esgenerator' ya existe")
        
        # Verificar nuevamente
        cursor.execute("SHOW DATABASES;")
        databases = cursor.fetchall()
        db_names = [db[0] for db in databases]
        print(f"Bases de datos actuales: {db_names}")
        
    connection.close()
    print("🚀 ¡Listo! Ahora puedes ejecutar init_db.py")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("Asegúrate de que Cloud SQL Proxy esté ejecutándose:")
    print("cloud_sql_proxy.exe -instances=esgenerator:europe-southwest1:esgenerator-db=tcp:3306")