"""Permisos por rol para DRF. El rol viene del JWT (ver auth.Actor)."""
from rest_framework.permissions import BasePermission


def role_required(*roles):
    """Devuelve una clase de permiso que exige uno de los roles dados."""
    class _RolePermission(BasePermission):
        message = 'No autorizado para este recurso (rol insuficiente).'

        def has_permission(self, request, view):
            user = getattr(request, 'user', None)
            return bool(
                user is not None
                and getattr(user, 'is_authenticated', False)
                and getattr(user, 'rol', None) in roles
            )

    return _RolePermission
