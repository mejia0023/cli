"""Almacenamiento de archivos: S3 nativo (con versioning) o fallback local.

USE_AWS=true  -> S3 (boto3); cada put crea una version (S3 Versioning).
USE_AWS=false -> filesystem local en data/files/<key>/<version_id> (dev sin AWS).
"""
import hashlib
import uuid
from pathlib import Path

from django.conf import settings


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class LocalStorage:
    backend = 'local'

    def __init__(self):
        self.root = Path(settings.LOCAL_DATA_DIR) / 'files'
        self.root.mkdir(parents=True, exist_ok=True)

    def put(self, key, data, content_type=None):
        version_id = uuid.uuid4().hex
        folder = self.root / key
        folder.mkdir(parents=True, exist_ok=True)
        (folder / version_id).write_bytes(data)
        return version_id

    def get(self, key, version_id):
        path = self.root / key / version_id
        return path.read_bytes() if path.exists() else None

    def url(self, key, version_id):
        # Servido por la vista de descarga (stream local).
        return f'/api/documentos/archivo?key={key}&version={version_id}'


class S3Storage:
    backend = 's3'

    def __init__(self):
        import boto3
        self.s3 = boto3.client('s3', region_name=settings.AWS_REGION)
        self.bucket = settings.S3_BUCKET

    def put(self, key, data, content_type=None):
        extra = {'ContentType': content_type} if content_type else {}
        resp = self.s3.put_object(Bucket=self.bucket, Key=key, Body=data, **extra)
        return resp.get('VersionId')

    def get(self, key, version_id):
        params = {'Bucket': self.bucket, 'Key': key}
        if version_id:
            params['VersionId'] = version_id
        return self.s3.get_object(**params)['Body'].read()

    def url(self, key, version_id):
        params = {'Bucket': self.bucket, 'Key': key}
        if version_id:
            params['VersionId'] = version_id
        return self.s3.generate_presigned_url('get_object', Params=params, ExpiresIn=3600)


_storage = None


def get_storage():
    global _storage
    if _storage is None:
        _storage = S3Storage() if settings.USE_AWS else LocalStorage()
    return _storage
