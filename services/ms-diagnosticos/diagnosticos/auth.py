"""Autenticacion DRF contra el JWT de Supabase (PyJWT + JWKS).

El rol viaja en el claim app_metadata.role. El frontend oculta por rol (UX);
aqui cada endpoint bloquea de verdad via permisos. supabase_uid (claim sub) es
la llave universal entre microservicios.
"""
import jwt
from jwt import PyJWKClient
from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

ROLES = {'ADMINISTRADOR', 'MEDICO', 'FARMACEUTICO', 'PACIENTE'}


class Actor:
    """Usuario autenticado minimal derivado del JWT (no es un modelo Django)."""
    is_authenticated = True

    def __init__(self, uid, email, nombre, rol):
        self.uid = uid
        self.email = email
        self.nombre = nombre
        self.rol = rol

    def __str__(self):
        return f'{self.nombre or self.email or self.uid} ({self.rol})'


def _norm_rol(value):
    s = str(value or '').upper()
    return s if s in ROLES else 'PACIENTE'


_jwk_client = None


def _client():
    global _jwk_client
    if _jwk_client is None and settings.SUPABASE_JWKS_URI:
        _jwk_client = PyJWKClient(settings.SUPABASE_JWKS_URI)
    return _jwk_client


class SupabaseJWTAuthentication(BaseAuthentication):
    def authenticate(self, request):
        authz = request.headers.get('Authorization', '')
        if not authz.lower().startswith('bearer '):
            return None  # sin credenciales -> request.user = None
        token = authz[7:].strip()

        client = _client()
        if client is None:
            return None  # JWKS no configurado (modo dev sin auth)

        try:
            signing_key = client.get_signing_key_from_jwt(token)
            kwargs = {}
            if settings.SUPABASE_ISSUER:
                kwargs['issuer'] = settings.SUPABASE_ISSUER
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=['ES256', 'RS256'],
                options={'verify_aud': False},
                **kwargs,
            )
        except Exception as exc:  # noqa: BLE001
            raise AuthenticationFailed(f'Token invalido: {exc}')

        app_meta = payload.get('app_metadata') or {}
        user_meta = payload.get('user_metadata') or {}
        actor = Actor(
            uid=payload.get('sub'),
            email=payload.get('email'),
            nombre=user_meta.get('name'),
            rol=_norm_rol(app_meta.get('role') or user_meta.get('role')),
        )
        return (actor, token)
