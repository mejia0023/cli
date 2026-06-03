"""Manejador de excepciones de DRF que expone el error COMPLETO.

Por defecto DRF (y Django) devuelven un 500 generico ("A server error occurred.")
para cualquier excepcion no controlada, ocultando la causa real. Aqui hacemos lo
contrario: SIEMPRE respondemos JSON con el error explicito (clase, mensaje y el
traceback completo), tanto para excepciones conocidas por DRF como para las
inesperadas. Pensado para depuracion del backend.
"""
import traceback

from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_default_handler


def full_exception_handler(exc, context):
    tb = traceback.format_exc()
    response = drf_default_handler(exc, context)

    if response is not None:
        # Excepcion que DRF ya entiende (validacion, auth, permisos, 404...):
        # conservamos status/forma y le agregamos el detalle completo.
        data = response.data
        if isinstance(data, dict):
            data.setdefault('exception', exc.__class__.__name__)
            data.setdefault('detail_completo', str(exc))
            data['traceback'] = tb
        else:
            response.data = {
                'detail': data,
                'exception': exc.__class__.__name__,
                'detail_completo': str(exc),
                'traceback': tb,
            }
        return response

    # Excepcion NO controlada (lo que normalmente seria un 500 opaco): la
    # devolvemos completa en JSON en vez de ocultarla.
    return Response(
        {
            'error': str(exc) or exc.__class__.__name__,
            'exception': exc.__class__.__name__,
            'traceback': tb,
        },
        status=500,
    )
