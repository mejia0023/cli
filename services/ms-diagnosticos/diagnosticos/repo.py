"""Persistencia de metadatos (documento / diagnostico / auditoria).

USE_AWS=true  -> DynamoDB (boto3).
USE_AWS=false -> archivos JSON en data/<tabla>.json (emula un store NoSQL en dev).
"""
import json
import threading
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

from django.conf import settings


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def new_id() -> str:
    return uuid.uuid4().hex


def _to_dynamo(obj):
    """DynamoDB no acepta float: convierte floats a Decimal recursivamente."""
    if isinstance(obj, float):
        return Decimal(str(obj))
    if isinstance(obj, dict):
        return {k: _to_dynamo(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_to_dynamo(v) for v in obj]
    return obj


class LocalRepo:
    backend = 'local'

    def __init__(self):
        self.dir = Path(settings.LOCAL_DATA_DIR)
        self.dir.mkdir(parents=True, exist_ok=True)
        self.lock = threading.Lock()

    def _path(self, table):
        return self.dir / f'{table}.json'

    def _load(self, table):
        path = self._path(table)
        if not path.exists():
            return []
        return json.loads(path.read_text(encoding='utf-8'))

    def _save(self, table, rows):
        self._path(table).write_text(
            json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8'
        )

    def put(self, table, item):
        with self.lock:
            rows = self._load(table)
            rows.append(item)
            self._save(table, rows)
        return item

    def query(self, table, **filters):
        rows = self._load(table)
        return [r for r in rows if all(r.get(k) == v for k, v in filters.items())]

    def update(self, table, match, changes):
        with self.lock:
            rows = self._load(table)
            for r in rows:
                if all(r.get(k) == v for k, v in match.items()):
                    r.update(changes)
            self._save(table, rows)


class DynamoRepo:
    backend = 'dynamodb'

    def __init__(self):
        import boto3
        endpoint = getattr(settings, 'DDB_ENDPOINT_URL', '')
        if endpoint:
            # DynamoDB Local: no valida credenciales, pero boto3 exige alguna.
            self.ddb = boto3.resource(
                'dynamodb',
                region_name=settings.AWS_REGION,
                endpoint_url=endpoint,
                aws_access_key_id='local',
                aws_secret_access_key='local',
            )
        else:
            self.ddb = boto3.resource('dynamodb', region_name=settings.AWS_REGION)
        self.prefix = settings.DDB_PREFIX

    def _table(self, table):
        return self.ddb.Table(self.prefix + table)

    def put(self, table, item):
        self._table(table).put_item(Item=_to_dynamo(item))
        return item

    def query(self, table, **filters):
        from boto3.dynamodb.conditions import Attr
        fe = None
        for k, v in filters.items():
            cond = Attr(k).eq(v)
            fe = cond if fe is None else fe & cond
        kwargs = {'FilterExpression': fe} if fe is not None else {}
        return self._table(table).scan(**kwargs).get('Items', [])

    def update(self, table, match, changes):
        # Demo: re-escribe los items que matchean (put_item sobrescribe por PK).
        for item in self.query(table, **match):
            item.update(changes)
            self._table(table).put_item(Item=_to_dynamo(item))


_repo = None


def get_repo():
    global _repo
    if _repo is None:
        # DynamoDB si: AWS real (USE_AWS=true) o DynamoDB Local (DDB_ENDPOINT_URL).
        use_dynamo = settings.USE_AWS or bool(getattr(settings, 'DDB_ENDPOINT_URL', ''))
        _repo = DynamoRepo() if use_dynamo else LocalRepo()
    return _repo
