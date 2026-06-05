"""Endpoints REST de MS2 (ms-diagnosticos).

Gestion documental versionada (S3/DynamoDB o fallback local), diagnostico IA
(supervisado/no supervisado) y pre-triaje NLP. Cada accion documental registra
auditoria; cada subida ancla el hash en blockchain (si esta disponible).
"""
from django.conf import settings
from django.http import HttpResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from . import blockchain
from . import repo as repo_mod
from . import storage as storage_mod
from .ml import models as ml_models
from .ml import triage as ml_triage
from .notify import notificar_resultado
from .permissions import role_required

repo = repo_mod.get_repo()
storage = storage_mod.get_storage()


def _audit(documento_id, accion, actor):
    repo.put('auditoria', {
        'audit_id': repo_mod.new_id(),
        'documento_id': documento_id,
        'accion': accion,
        'usuario_uid': getattr(actor, 'uid', None),
        'rol': getattr(actor, 'rol', None),
        'timestamp': repo_mod.now_iso(),
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def health(request):
    return Response({
        'status': 'ok',
        'service': 'ms-diagnosticos',
        'storage': storage.backend,
        'repo': repo.backend,
        'aws': settings.USE_AWS,
    })


@api_view(['POST'])
@permission_classes([role_required('PACIENTE', 'ADMINISTRADOR', 'MEDICO')])
def pre_triaje(request):
    sintomas = (request.data.get('sintomas') or '').strip()
    if not sintomas:
        return Response({'error': 'sintomas requerido'}, status=400)
    return Response(ml_triage.pre_triaje(sintomas))


@api_view(['POST'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO')])
def diagnosticar(request):
    actor = request.user
    paciente_id = request.data.get('paciente_id')
    tipo_estudio = request.data.get('tipo_estudio', 'radiografia')
    modo = (request.data.get('modo') or 'SUPERVISADO').upper()
    documento_id = request.data.get('documento_id')

    image_bytes = None
    if 'imagen' in request.FILES:
        image_bytes = request.FILES['imagen'].read()
    elif documento_id:
        docs = repo.query('documento', documento_id=documento_id, vigente=True)
        if not docs:
            return Response({'error': 'documento no encontrado'}, status=404)
        d = docs[0]
        image_bytes = storage.get(d['s3_key'], d['s3_version_id'])
        paciente_id = paciente_id or d['paciente_id']

    if image_bytes is None:
        return Response({'error': 'falta imagen (campo "imagen") o documento_id'}, status=400)
    if not paciente_id:
        return Response({'error': 'paciente_id requerido'}, status=400)

    try:
        resultado = ml_models.predict(image_bytes, modo)
    except Exception as exc:  # noqa: BLE001
        import traceback as _tb
        return Response(
            {
                'error': f'imagen invalida: {exc}',
                'exception': exc.__class__.__name__,
                'traceback': _tb.format_exc(),
            },
            status=400,
        )

    item = {
        'diagnostico_id': repo_mod.new_id(),
        'paciente_id': paciente_id,
        'documento_id': documento_id,
        'tipo_estudio': tipo_estudio,
        'hallazgo': resultado['hallazgo'],
        'confianza': resultado['confianza'],
        'modelo_version': resultado['modelo_version'],
        'modo': resultado['modo'],
        'medico_uid': actor.uid,
        'created_at': repo_mod.now_iso(),
    }
    repo.put('diagnostico', item)
    # Push #3 (resultado listo): le pedimos a MS1 que avise al paciente,
    # reenviando el JWT del médico. Resiliente: si MS1 está caído, el
    # diagnóstico ya quedó guardado y solo se loggea un warning.
    notificar_resultado(
        request.headers.get('Authorization'),
        paciente_id,
        tipo_estudio,
    )
    return Response(item, status=201)


@api_view(['POST'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO', 'PACIENTE')])
def subir_documento(request):
    actor = request.user
    archivo = request.FILES.get('archivo')
    if not archivo:
        return Response({'error': 'archivo requerido (multipart, campo "archivo")'}, status=400)
    paciente_id = request.data.get('paciente_id')
    if not paciente_id:
        return Response({'error': 'paciente_id requerido'}, status=400)

    episodio_id = request.data.get('episodio_id')
    tipo = request.data.get('tipo', 'estudio')
    motivo = request.data.get('motivo_cambio')
    documento_id = request.data.get('documento_id')  # si viene -> nueva version

    data = archivo.read()
    hash_doc = storage_mod.sha256_hex(data)

    if documento_id:
        existing = repo.query('documento', documento_id=documento_id)
        version = (max(r['version'] for r in existing) + 1) if existing else 1
        repo.update('documento', {'documento_id': documento_id}, {'vigente': False})
        accion = 'EDITAR'
    else:
        documento_id = repo_mod.new_id()
        version = 1
        accion = 'CREAR'

    key = f'{paciente_id}/{documento_id}'
    s3_version_id = storage.put(key, data, content_type=archivo.content_type)

    item = {
        'documento_id': documento_id,
        'version': version,
        'paciente_id': paciente_id,
        'episodio_id': episodio_id,
        's3_key': key,
        's3_version_id': s3_version_id,
        'tipo': tipo,
        'nombre_original': archivo.name,
        'tamano': len(data),
        'content_type': archivo.content_type,
        'hash_documento': hash_doc,
        'editado_por': actor.uid,
        'motivo_cambio': motivo,
        'vigente': True,
        'created_at': repo_mod.now_iso(),
    }
    repo.put('documento', item)
    _audit(documento_id, accion, actor)

    reg = blockchain.anchor(
        blockchain.canonical_doc(item), paciente_id, actor.uid,
        token=getattr(request, 'auth', None),
    )
    if reg:
        cambios = {'blockchain_tx': reg.get('txHash'), 'blockchain_id': reg.get('id')}
        repo.update('documento', {'documento_id': documento_id, 'version': version}, cambios)
        item.update(cambios)

    return Response(item, status=201)


@api_view(['GET'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO', 'PACIENTE')])
def listar_documentos(request):
    paciente_id = request.query_params.get('paciente_id')
    if not paciente_id:
        return Response({'error': 'paciente_id requerido'}, status=400)
    docs = repo.query('documento', paciente_id=paciente_id, vigente=True)
    return Response(sorted(docs, key=lambda d: d.get('created_at', ''), reverse=True))


@api_view(['GET'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO', 'PACIENTE')])
def versiones_documento(request, documento_id):
    docs = repo.query('documento', documento_id=documento_id)
    if not docs:
        return Response({'error': 'documento no encontrado'}, status=404)
    _audit(documento_id, 'CONSULTAR', request.user)
    return Response(sorted(docs, key=lambda d: d['version']))


@api_view(['GET'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO', 'PACIENTE')])
def descargar_documento(request, documento_id):
    version = request.query_params.get('version')
    docs = repo.query('documento', documento_id=documento_id)
    if not docs:
        return Response({'error': 'documento no encontrado'}, status=404)
    if version:
        sel = next((d for d in docs if str(d['version']) == str(version)), None)
    else:
        sel = next((d for d in docs if d.get('vigente')), docs[-1])
    if not sel:
        return Response({'error': 'version no encontrada'}, status=404)

    _audit(documento_id, 'CONSULTAR', request.user)

    if storage.backend == 's3':
        return Response({'url': storage.url(sel['s3_key'], sel['s3_version_id'])})

    data = storage.get(sel['s3_key'], sel['s3_version_id'])
    if data is None:
        return Response({'error': 'archivo no encontrado'}, status=404)
    resp = HttpResponse(data, content_type=sel.get('content_type') or 'application/octet-stream')
    resp['Content-Disposition'] = f'attachment; filename="{sel.get("nombre_original", "documento")}"'
    return resp


@api_view(['GET'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO', 'PACIENTE')])
def listar_diagnosticos(request):
    paciente_id = request.query_params.get('paciente_id')
    if not paciente_id:
        return Response({'error': 'paciente_id requerido'}, status=400)
    items = repo.query('diagnostico', paciente_id=paciente_id)
    return Response(sorted(items, key=lambda d: d.get('created_at', ''), reverse=True))


@api_view(['GET'])
@permission_classes([role_required('ADMINISTRADOR', 'MEDICO')])
def listar_auditoria(request):
    documento_id = request.query_params.get('documento_id')
    if not documento_id:
        return Response({'error': 'documento_id requerido'}, status=400)
    items = repo.query('auditoria', documento_id=documento_id)
    return Response(sorted(items, key=lambda d: d.get('timestamp', ''), reverse=True))
