"""Aviso a MS1 (ms-pacientes) de que el resultado de un estudio ya está listo.

MS1 es quien tiene el ExpoPushToken del paciente, así que MS2 solo le pide que
dispare el push #3 (mutation notificarResultado), reenviando el JWT del médico.

REGLA DURA: esto NUNCA rompe el guardado del diagnóstico. Si MS1 está caído,
tarda o responde error, solo se loggea con un warning (igual que blockchain.py).
"""
import logging
import os

import requests

log = logging.getLogger(__name__)

_MUTATION = (
    'mutation($pacienteId: ID!, $tipoEstudio: String) {'
    ' notificarResultado(pacienteId: $pacienteId, tipoEstudio: $tipoEstudio) }'
)


def notificar_resultado(authorization, paciente_id, tipo_estudio=None):
    """POST GraphQL a MS1 reenviando el header Authorization del médico.

    :param authorization: header Authorization entrante (``Bearer <jwt>``) o None.
    :param paciente_id: id del paciente dueño del estudio.
    :param tipo_estudio: tipo de estudio (radiografia, etc.); opcional.
    """
    if not paciente_id:
        return
    # Se lee aquí (no a nivel de módulo) para tomar siempre el valor actual del .env.
    url = os.environ.get('MS1_GRAPHQL_URL', 'http://localhost:3000/api/graphql')
    try:
        headers = {'Content-Type': 'application/json'}
        if authorization:
            headers['Authorization'] = authorization
        resp = requests.post(
            url,
            json={
                'query': _MUTATION,
                'variables': {'pacienteId': str(paciente_id), 'tipoEstudio': tipo_estudio},
            },
            headers=headers,
            timeout=4,
        )
        if not resp.ok:
            log.warning('MS1 notificarResultado respondió %s: %s', resp.status_code, resp.text[:300])
    except Exception as exc:  # noqa: BLE001
        # Incluye timeouts y fallos de conexión (MS1 caído): nunca propagamos.
        log.warning('notificar_resultado a MS1 falló: %s', exc)
