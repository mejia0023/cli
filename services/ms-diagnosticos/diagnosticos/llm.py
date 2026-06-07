"""Capa LLM (Google Gemini) para el chat de pre-triaje conversacional.

Seguridad: la API key vive SOLO en el backend (variable GEMINI_API_KEY del
.env de MS2). El movil nunca la ve ni la transporta:

    app movil --(JWT del paciente)--> MS2 --(GEMINI_API_KEY)--> Gemini

Si no hay key configurada o Gemini falla/agota cuota, la vista cae al
clasificador por reglas (ml/triage.py), de modo que el endpoint SIEMPRE
responde algo util (la demo nunca muere).

Hibrido supervisado/no supervisado + generativo: a Gemini se le pasa como
"pista" el resultado del clasificador NLP por reglas; el LLM aporta la capa
conversacional y puede corregir la pista si la conversacion lo amerita.
"""
import json
import os

import requests

# Especialidades validas de la clinica (las mismas de ml/triage.py).
ESPECIALIDADES = (
    'Cardiologia',
    'Neumologia',
    'Emergencias',
    'Traumatologia',
    'Dermatologia',
    'Neurologia',
    'Gastroenterologia',
    'Medicina General',
)

_URGENCIAS = ('ALTA', 'MEDIA', 'BAJA')

SYSTEM_PROMPT = (
    "Eres el asistente virtual de pre-triaje de una clinica en Bolivia. "
    "Hablas en espanol, con calidez y frases cortas.\n"
    "Tu UNICO objetivo es orientar al paciente hacia la especialidad adecuada "
    "y el nivel de urgencia. Haz como maximo 1 o 2 preguntas aclaratorias si "
    "falta informacion; cuando ya tengas una idea clara, recomienda.\n"
    "REGLAS ESTRICTAS:\n"
    "- NUNCA das diagnosticos, nombres de enfermedades como conclusion, "
    "medicamentos ni dosis.\n"
    "- Ante senales de alarma (dolor de pecho intenso, dificultad severa para "
    "respirar, sangrado abundante, perdida de conciencia, convulsiones, ideas "
    "de hacerse dano), tu respuesta indica acudir a emergencias de inmediato, "
    "urgencia ALTA y agendar=false.\n"
    f"- 'especialidad' debe ser EXACTAMENTE una de: {', '.join(ESPECIALIDADES)} "
    "o null si aun no la sabes.\n"
    "- 'urgencia' es ALTA, MEDIA, BAJA o null.\n"
    "- 'agendar' es true SOLO cuando ya recomendaste una especialidad concreta "
    "y corresponde ofrecer cita (no en emergencias).\n"
    "- Recibiras una PISTA de un clasificador por reglas de la clinica; usala "
    "como orientacion, puedes corregirla si la conversacion da mas contexto.\n"
    "RESPONDE SIEMPRE Y UNICAMENTE con un JSON valido, sin texto adicional, "
    "con esta forma exacta:\n"
    '{"respuesta": "texto para el paciente (max 80 palabras)", '
    '"especialidad": "..." | null, "urgencia": "ALTA"|"MEDIA"|"BAJA"|null, '
    '"agendar": true|false}'
)


class LlmError(Exception):
    """Fallo al consultar o interpretar al LLM (la vista hace fallback)."""


def _config():
    key = (os.environ.get('GEMINI_API_KEY') or '').strip()
    model = (os.environ.get('GEMINI_MODEL') or '').strip() or 'gemini-2.0-flash'
    return key, model


def hay_llm() -> bool:
    """True si hay GEMINI_API_KEY configurada en el entorno."""
    key, _ = _config()
    return bool(key)


def _extraer_json(texto):
    """Saca el primer objeto JSON de un texto (tolera ```json ... ``` y ruido)."""
    if not texto:
        return None
    t = texto.strip()
    if t.startswith('```'):
        t = t.strip('`')
        if t.lower().startswith('json'):
            t = t[4:]
        t = t.strip()
    ini = t.find('{')
    fin = t.rfind('}')
    if ini == -1 or fin == -1 or fin <= ini:
        return None
    try:
        data = json.loads(t[ini:fin + 1])
    except (ValueError, TypeError):
        return None
    return data if isinstance(data, dict) else None


def _normalizar(data: dict) -> dict:
    """Garantiza tipos/valores validos venga lo que venga del modelo."""
    respuesta = str(data.get('respuesta') or '').strip()
    if not respuesta:
        raise LlmError('el modelo no devolvio "respuesta"')

    especialidad = data.get('especialidad')
    if isinstance(especialidad, str):
        esp = especialidad.strip()
        match = next((e for e in ESPECIALIDADES if e.lower() == esp.lower()), None)
        especialidad = match
    else:
        especialidad = None

    urgencia = data.get('urgencia')
    if isinstance(urgencia, str) and urgencia.strip().upper() in _URGENCIAS:
        urgencia = urgencia.strip().upper()
    else:
        urgencia = None

    agendar = bool(data.get('agendar')) and especialidad is not None

    return {
        'respuesta': respuesta,
        'especialidad': especialidad,
        'urgencia': urgencia,
        'agendar': agendar,
    }


def chat_triaje(mensaje: str, historial: list, pista: dict) -> dict:
    """Llama a Gemini con el historial y la pista del clasificador por reglas.

    historial: lista de {'rol': 'user'|'bot', 'texto': str} (la vista ya la sanea).
    pista: salida de ml/triage.pre_triaje() para el texto acumulado del paciente.
    Devuelve {'respuesta', 'especialidad', 'urgencia', 'agendar', 'metodo'}.
    Lanza LlmError si no hay key, la red falla o la salida es ininterpretable.
    """
    key, model = _config()
    if not key:
        raise LlmError('GEMINI_API_KEY no configurada')

    contents = []
    for item in historial:
        rol = 'model' if item.get('rol') == 'bot' else 'user'
        texto = str(item.get('texto') or '').strip()
        if texto:
            contents.append({'role': rol, 'parts': [{'text': texto[:1000]}]})

    pista_txt = (
        f"[PISTA del clasificador por reglas de la clinica: especialidad="
        f"{pista.get('especialidad')}, urgencia={pista.get('urgencia')}]"
    )
    contents.append({'role': 'user', 'parts': [{'text': f'{pista_txt}\n{mensaje[:1000]}'}]})

    body = {
        'system_instruction': {'parts': [{'text': SYSTEM_PROMPT}]},
        'contents': contents,
        'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 400,
            'responseMimeType': 'application/json',
        },
    }
    url = f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent'

    try:
        resp = requests.post(
            url,
            json=body,
            headers={'x-goog-api-key': key, 'Content-Type': 'application/json'},
            timeout=20,
        )
    except requests.RequestException as exc:
        raise LlmError(f'no se pudo contactar a Gemini: {exc}') from exc

    if resp.status_code != 200:
        detalle = resp.text[:200].replace('\n', ' ')
        raise LlmError(f'Gemini HTTP {resp.status_code}: {detalle}')

    try:
        texto = resp.json()['candidates'][0]['content']['parts'][0]['text']
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        raise LlmError('respuesta de Gemini con forma inesperada') from exc

    data = _extraer_json(texto)
    if data is None:
        raise LlmError('Gemini no devolvio JSON interpretable')

    out = _normalizar(data)
    out['metodo'] = f'gemini ({model})'
    return out
