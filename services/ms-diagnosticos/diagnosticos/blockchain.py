"""Cliente al ms-blockchain (Node/Polygon) para anclar el hash de un documento.

Reutiliza el contrato RegistroRecetas (POST /recetas con el hash canonico).
Resiliente: si esta deshabilitado o falla, devuelve None (no rompe la subida).
"""
import logging

import requests
from django.conf import settings

log = logging.getLogger(__name__)


def canonical_doc(item: dict) -> str:
    """Texto canonico determinista de una version de documento (para hashear/anclar)."""
    return (
        '{doc:%s,version:%s,paciente:%s,s3:%s,hash:%s}'
        % (
            item.get('documento_id'),
            item.get('version'),
            item.get('paciente_id'),
            item.get('s3_version_id'),
            item.get('hash_documento'),
        )
    )


def anchor(documento_texto: str, paciente_id: str, medico_uid: str, token: str | None = None):
    if not settings.BLOCKCHAIN_ENABLED:
        log.info('Blockchain deshabilitado por config — skip anchor')
        return None
    try:
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = f'Bearer {token}'
        resp = requests.post(
            f'{settings.BLOCKCHAIN_URL}/recetas',
            json={
                'documentoTexto': documento_texto,
                'pacienteId': str(paciente_id),
                'medicoUid': str(medico_uid),
            },
            headers=headers,
            timeout=45,
        )
        if resp.ok:
            data = resp.json()
            return {
                'txHash': data.get('txHash'),
                'id': data.get('id'),
                'hash': data.get('hash'),
            }
        log.warning('ms-blockchain respondio %s: %s', resp.status_code, resp.text[:200])
    except Exception as exc:  # noqa: BLE001
        log.warning('anchor a blockchain fallo: %s', exc)
    return None
