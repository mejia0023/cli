# MS2 — ms-diagnosticos (Django/DRF · IA + gestión documental)

Microservicio **REST** dueño de **diagnóstico por IA**, **gestión documental versionada** y **pre-triaje**.
Parte del refactor MediCloud (v3). Identidad compartida vía **Supabase** (`supabase_uid`).

## Stack
- **Django + Django REST Framework** (REST, no GraphQL — el frontend lo llama directo)
- **scikit-learn** — IA: modelo **supervisado** (RandomForest) + **no supervisado** (IsolationForest)
- **Pre-triaje NLP** por reglas (síntomas → especialidad + urgencia)
- **Almacenamiento**: **AWS S3** (versioning) + **DynamoDB** vía boto3 — con **fallback local**
  (filesystem + JSON) para correr sin AWS (`USE_AWS=false`)
- **Auth**: JWT de Supabase con **PyJWT + JWKS** (ES256/RS256); bloqueo por rol en cada endpoint
- **Blockchain**: ancla el hash de cada versión de documento en `ms-blockchain` (Polygon)

## Correr en local (sin AWS)
```bash
cd services/ms-diagnosticos
py -3.12 -m venv .venv
.venv\Scripts\pip install -r requirements.txt
.venv\Scripts\python manage.py runserver 8000   # http://localhost:8000/api/health
```
Con `USE_AWS=false` (default) los archivos van a `data/files/` y los metadatos a `data/*.json`
(emulando S3 + DynamoDB). Para producción: `USE_AWS=true` + credenciales AWS + bucket con Versioning.

## Endpoints (`/api`)
| Método | Ruta | Rol | Qué hace |
|---|---|---|---|
| GET  | `/api/health` | — | Estado del servicio |
| POST | `/api/pre-triaje` | PACIENTE/MEDICO/ADMIN | `{sintomas}` → `{especialidad, urgencia}` (NLP) |
| POST | `/api/diagnosticar` | MEDICO/ADMIN | imagen (`imagen`) o `documento_id` + `modo` → corre ML → guarda diagnóstico |
| GET  | `/api/diagnosticos?paciente_id=` | MEDICO/ADMIN/PACIENTE | lista diagnósticos |
| POST | `/api/documentos/subir` | MEDICO/ADMIN/PACIENTE | multipart `archivo`+`paciente_id` → nueva versión (no sobrescribe) + hash en blockchain |
| GET  | `/api/documentos?paciente_id=` | MEDICO/ADMIN/PACIENTE | documentos vigentes del paciente |
| GET  | `/api/documentos/{id}/versiones` | MEDICO/ADMIN/PACIENTE | todas las versiones |
| GET  | `/api/documentos/{id}/descargar?version=` | MEDICO/ADMIN/PACIENTE | descarga (local) o presigned URL (S3) |
| GET  | `/api/auditoria?documento_id=` | MEDICO/ADMIN | bitácora (CREAR/EDITAR/CONSULTAR) |

## IA/ML (supervisado + no supervisado)
- `diagnosticos/ml/models.py`: `predict_supervisado` (clasificación normal/anómalo + confianza) y
  `predict_no_supervisado` (detección de anomalías + confianza). Entrenados con datos sintéticos (demo);
  la API está lista para reemplazarlos por modelos reales o un CNN (PyTorch/TensorFlow) sin tocar las vistas.
- `diagnosticos/ml/triage.py`: pre-triaje por reglas, ampliable a un clasificador de texto entrenado.

## Versionado documental
Un documento es **inmutable**: una corrección sube una **versión nueva** (nueva fila + nuevo `s3_version_id`
+ nuevo hash anclado), la anterior no se borra (solo `vigente=false`). Cada acción queda en `auditoria`.
