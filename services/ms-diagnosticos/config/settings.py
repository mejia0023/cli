"""Configuracion Django de MS2 (ms-diagnosticos).

Servicio backend REST (DRF). NO usa modelos Django: la persistencia va a
DynamoDB + S3 (o fallback local filesystem/JSON). Auth via JWT de Supabase.
"""
import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')


def _bool(name, default='false'):
    return os.environ.get(name, default).strip().lower() in ('1', 'true', 'yes', 'on')


SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'dev-insecure-key')
DEBUG = _bool('DJANGO_DEBUG', 'true')
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'corsheaders',
    'rest_framework',
    'diagnosticos',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
]

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'
TEMPLATES = []

# Django exige DATABASES aunque no usemos el ORM (datos van a DynamoDB/S3 o local).
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'data' / 'django.sqlite3',
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ['diagnosticos.auth.SupabaseJWTAuthentication'],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'UNAUTHENTICATED_USER': None,
    # Manejador que expone el error COMPLETO (clase, mensaje y traceback) en vez
    # del 500 generico de Django/DRF.
    'EXCEPTION_HANDLER': 'diagnosticos.exception_handler.full_exception_handler',
}

# CORS: el frontend Angular llama a MS2 directo por REST (diagnostico/documentos/pre-triaje).
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_HEADERS = ['authorization', 'content-type', 'accept']

# ---- Config de negocio (env) ----
SUPABASE_JWKS_URI = os.environ.get('SUPABASE_JWKS_URI', '')
SUPABASE_ISSUER = os.environ.get('SUPABASE_ISSUER', '')

USE_AWS = _bool('USE_AWS', 'false')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
S3_BUCKET = os.environ.get('S3_BUCKET', 'medicloud-documentos')
DDB_PREFIX = os.environ.get('DDB_PREFIX', '')
# DynamoDB Local (emulador oficial de AWS): si se define, los metadatos van a
# DynamoDB en ese endpoint (ej. http://localhost:8001) SIN necesitar cuenta AWS.
# Los archivos siguen en disco local salvo que USE_AWS=true (S3 real).
DDB_ENDPOINT_URL = os.environ.get('DDB_ENDPOINT_URL', '')
LOCAL_DATA_DIR = BASE_DIR / 'data'

BLOCKCHAIN_URL = os.environ.get('BLOCKCHAIN_URL', 'http://localhost:3001')
BLOCKCHAIN_ENABLED = _bool('BLOCKCHAIN_ENABLED', 'true')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
USE_TZ = True
TIME_ZONE = 'UTC'

# runserver sin staticfiles app
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {'console': {'class': 'logging.StreamHandler'}},
    'root': {'handlers': ['console'], 'level': 'INFO'},
}
