from django.urls import path

from . import views

urlpatterns = [
    path('health', views.health),
    path('pre-triaje', views.pre_triaje),
    path('diagnosticar', views.diagnosticar),
    path('diagnosticos', views.listar_diagnosticos),
    path('documentos', views.listar_documentos),                     # GET ?paciente_id=
    path('documentos/subir', views.subir_documento),                 # POST (multipart)
    path('documentos/<str:documento_id>/versiones', views.versiones_documento),
    path('documentos/<str:documento_id>/descargar', views.descargar_documento),
    path('auditoria', views.listar_auditoria),                       # GET ?documento_id=
]
