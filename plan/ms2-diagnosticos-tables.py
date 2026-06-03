#!/usr/bin/env python3
# =====================================================
#  MS2 — ms-diagnosticos  (Django + boto3 · DynamoDB + S3 en GCP)
#  Dueño de: análisis de imágenes con IA/ML y gestión documental versionada.
#
#  DynamoDB no usa SQL: las "tablas" se crean por API/SDK. Este script crea
#  las 3 tablas + el bucket S3 con versionado activado.
#
#  Uso:
#    pip install boto3
#    export AWS_REGION=us-east-1
#    export S3_BUCKET=medicloud-documentos
#    python ms2-diagnosticos-tables.py
#
#  Estructura de cada "tabla" (NoSQL: clave de partición PK, de orden SK):
#    documento    PK documento_id (S), SK version (N)   + GSI por paciente_id
#    diagnostico  PK diagnostico_id (S)                 + GSI por paciente_id
#    auditoria    PK audit_id (S)                       + GSI por documento_id
# =====================================================

import os
import boto3
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION", "us-east-1")
BUCKET = os.environ.get("S3_BUCKET", "medicloud-documentos")

dynamodb = boto3.client("dynamodb", region_name=REGION)
s3 = boto3.client("s3", region_name=REGION)


def crear_tabla(definicion):
    nombre = definicion["TableName"]
    try:
        dynamodb.create_table(**definicion)
        print(f"[OK] Tabla creada: {nombre}")
        dynamodb.get_waiter("table_exists").wait(TableName=nombre)
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            print(f"[SKIP] La tabla ya existe: {nombre}")
        else:
            raise


# ---------- 1) documento (VERSIONADO: PK documento_id + SK version) ----------
documento = {
    "TableName": "documento",
    "KeySchema": [
        {"AttributeName": "documento_id", "KeyType": "HASH"},   # PK lógica del documento
        {"AttributeName": "version",      "KeyType": "RANGE"},  # SK: 1, 2, 3...
    ],
    "AttributeDefinitions": [
        {"AttributeName": "documento_id", "AttributeType": "S"},
        {"AttributeName": "version",      "AttributeType": "N"},
        {"AttributeName": "paciente_id",  "AttributeType": "S"},
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "paciente_id-index",  # listar documentos de un paciente
            "KeySchema": [
                {"AttributeName": "paciente_id", "KeyType": "HASH"},
                {"AttributeName": "version",     "KeyType": "RANGE"},
            ],
            "Projection": {"ProjectionType": "ALL"},
        }
    ],
    "BillingMode": "PAY_PER_REQUEST",
}
# Atributos NO-clave que guarda cada item (no se declaran en DynamoDB, van en el put):
#   episodio_id, s3_key, s3_version_id, tipo, nombre_original, tamano,
#   content_type, hash_documento, editado_por, motivo_cambio, vigente (bool), created_at
# Regla de versionado: al subir una versión nueva, escribir version = max+1
# y poner vigente=true solo en esa; marcar la anterior vigente=false.

# ---------- 2) diagnostico (resultado del ML) ----------
diagnostico = {
    "TableName": "diagnostico",
    "KeySchema": [
        {"AttributeName": "diagnostico_id", "KeyType": "HASH"},
    ],
    "AttributeDefinitions": [
        {"AttributeName": "diagnostico_id", "AttributeType": "S"},
        {"AttributeName": "paciente_id",    "AttributeType": "S"},
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "paciente_id-index",  # diagnósticos de un paciente
            "KeySchema": [
                {"AttributeName": "paciente_id", "KeyType": "HASH"},
            ],
            "Projection": {"ProjectionType": "ALL"},
        }
    ],
    "BillingMode": "PAY_PER_REQUEST",
}
# Atributos no-clave: documento_id, tipo_estudio, hallazgo, confianza (N),
#   modelo_version, modo (SUPERVISADO|NO_SUPERVISADO), created_at

# ---------- 3) auditoria (bitácora documental) ----------
auditoria = {
    "TableName": "auditoria",
    "KeySchema": [
        {"AttributeName": "audit_id", "KeyType": "HASH"},
    ],
    "AttributeDefinitions": [
        {"AttributeName": "audit_id",     "AttributeType": "S"},
        {"AttributeName": "documento_id", "AttributeType": "S"},
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "documento_id-index",  # historial de acciones de un documento
            "KeySchema": [
                {"AttributeName": "documento_id", "KeyType": "HASH"},
            ],
            "Projection": {"ProjectionType": "ALL"},
        }
    ],
    "BillingMode": "PAY_PER_REQUEST",
}
# Atributos no-clave: accion (CREAR|EDITAR|CONSULTAR), usuario_uid, rol, timestamp


def crear_bucket_versionado():
    try:
        if REGION == "us-east-1":
            s3.create_bucket(Bucket=BUCKET)
        else:
            s3.create_bucket(
                Bucket=BUCKET,
                CreateBucketConfiguration={"LocationConstraint": REGION},
            )
        print(f"[OK] Bucket creado: {BUCKET}")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("BucketAlreadyOwnedByYou", "BucketAlreadyExists"):
            print(f"[SKIP] El bucket ya existe: {BUCKET}")
        else:
            raise
    # Activar versionado nativo: cada subida conserva la versión anterior.
    s3.put_bucket_versioning(
        Bucket=BUCKET,
        VersioningConfiguration={"Status": "Enabled"},
    )
    print(f"[OK] Versionado S3 activado en: {BUCKET}")


if __name__ == "__main__":
    crear_tabla(documento)
    crear_tabla(diagnostico)
    crear_tabla(auditoria)
    crear_bucket_versionado()
    print("\nListo. MS2 tiene sus 3 tablas DynamoDB y el bucket S3 versionado.")
