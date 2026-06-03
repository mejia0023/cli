"""Pre-triaje NLP por reglas: texto de sintomas -> especialidad sugerida + urgencia.

Es un clasificador por palabras clave (NLP basico, determinista). La salida (urgencia)
se escribe en la cita de MS1. Pensado para cambiarse luego por un modelo de texto
entrenado (TF-IDF + clasificador, o un LLM) sin tocar la vista.
"""
import unicodedata

# (palabras_clave, especialidad, urgencia)
_REGLAS = [
    (('dolor de pecho', 'dolor pecho', 'opresion en el pecho', 'palpitacion', 'taquicardia'),
     'Cardiologia', 'ALTA'),
    (('dificultad para respirar', 'falta de aire', 'ahogo', 'disnea', 'no puedo respirar'),
     'Neumologia', 'ALTA'),
    (('sangrado', 'hemorragia', 'desmayo', 'inconsciente', 'convulsion', 'perdida de conocimiento'),
     'Emergencias', 'ALTA'),
    (('fractura', 'me cai', 'caida', 'esguince', 'torcedura', 'dolor de hueso', 'golpe fuerte'),
     'Traumatologia', 'MEDIA'),
    (('erupcion', 'sarpullido', 'picazon', 'mancha en la piel', 'roncha'),
     'Dermatologia', 'BAJA'),
    (('dolor de cabeza', 'migrana', 'mareo', 'vision borrosa', 'hormigueo'),
     'Neurologia', 'MEDIA'),
    (('dolor abdominal', 'dolor de estomago', 'nausea', 'vomito', 'diarrea'),
     'Gastroenterologia', 'MEDIA'),
    (('fiebre', 'tos', 'gripe', 'resfriado', 'dolor de garganta', 'malestar general', 'congestion'),
     'Medicina General', 'MEDIA'),
]


def _normaliza(texto: str) -> str:
    t = (texto or '').lower()
    t = unicodedata.normalize('NFKD', t).encode('ascii', 'ignore').decode('ascii')
    return t


def pre_triaje(sintomas: str) -> dict:
    texto = _normaliza(sintomas)
    for claves, especialidad, urgencia in _REGLAS:
        for clave in claves:
            if _normaliza(clave) in texto:
                return {
                    'especialidad': especialidad,
                    'urgencia': urgencia,
                    'coincidencia': clave,
                    'metodo': 'reglas-nlp',
                }
    return {
        'especialidad': 'Medicina General',
        'urgencia': 'BAJA',
        'coincidencia': None,
        'metodo': 'reglas-nlp',
    }
