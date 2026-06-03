# 1. Ir a la carpeta del repo (ajusta la ruta a donde lo tengas clonado)
cd C:\ruta\a\tu\cli

# 2. Levantar DynamoDB Local (Docker Desktop debe estar abierto)
docker compose up -d dynamodb-local
docker compose ps    # debe aparecer clinica_dynamodb en puerto 8001

# 3. Crear las 3 tablas con sus índices
pip install boto3
$env:DDB_ENDPOINT_URL = "http://localhost:8001"
python plan\ms2-diagnosticos-tables.py


PS C:\Users\Usuario\AppData\Local\Microsoft\WindowsApps> curl http://localhost:8000/api/health
{"status":"ok","service":"ms-diagnosticos","storage":"local","repo":"local","aws":false}
PS C:\Users\Usuario\AppData\Local\Microsoft\WindowsApps> aws dynamodb list-tables --endpoint-url http://localhost:8001
{
    "TableNames": []
}

PS C:\Users\Usuario\AppData\Local\Microsoft\WindowsApps>


(.venv) PS C:\Users\Usuario\Documents\sw2_projects\SW2_PARCIAL_DOS\clinica\services\ms-diagnosticos> python C:\Users\Usuario\Documents\sw2_projects\SW2_PARCIAL_DOS\clinica\plan\ms2-diagnosticos-tables.py
[INFO] Usando DynamoDB Local en http://localhost:8001 (se omite S3)
[OK] Tabla creada: documento
[OK] Tabla creada: diagnostico
[OK] Tabla creada: auditoria

Listo. Tablas creadas en DynamoDB Local (S3 omitido: los archivos quedan en disco local).
(.venv) PS C:\Users\Usuario\Documents\sw2_projects\SW2_PARCIAL_DOS\clinica\services\ms-diagnosticos> aws dynamodb list-tables --endpoint-url http://localhost:8001

{                                                                                                                                                                
    "TableNames": [
        "auditoria",
        "diagnostico",
        "documento"
    ]
}

(.venv) PS C:\Users\Usuario\Documents\sw2_projects\SW2_PARCIAL_DOS\clinica\services\ms-diagnosticos> 

##passo fial 
PS C:\Users\Usuario> curl http://localhost:8000/api/health
>>
{"status":"ok","service":"ms-diagnosticos","storage":"local","repo":"dynamodb","aws":false}
PS C:\Users\Usuario> aws dynamodb scan --table-name documento --endpoint-url http://localhost:8001
{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}

PS C:\Users\Usuario> aws dynamodb scan --table-name auditoria --endpoint-url http://localhost:8001
{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}

PS C:\Users\Usuario>