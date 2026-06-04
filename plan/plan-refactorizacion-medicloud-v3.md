# Plan de refactorización — MediCloud (v3 definitivo)

Documento maestro del proyecto `mejia0023/cli`, con las decisiones **ya confirmadas y bloqueadas**:
**Next.js + Django REST Framework + Spring Boot + Angular**, ejecución **local-first**, documentos en **AWS S3 nativo**, IA con modelo **supervisado y no supervisado**, autenticación **Supabase** y 4 roles. Reemplaza a la v2.

> **Cambios clave vs v2:** MS2 ahora va por **REST (DRF)**, no GraphQL → no se federa, Angular lo llama directo. Despliegue **local** (puertos), no cloud. Se añade el **modelo no supervisado** que faltaba.

---

## 0. Stack definitivo (bloqueado)

| Pieza | Tecnología | Estado | Puerto local |
|---|---|---|---|
| Frontend web | **Angular** + Apollo Client | ya existe | `localhost:4200` |
| MS1 — Pacientes, Citas, Historia | **Next.js** + Prisma + PostgreSQL | crear | `localhost:3000/api/graphql` |
| MS2 — Diagnóstico IA + Documental | **Django REST Framework** + S3 + DynamoDB | crear | `localhost:8000` (REST) |
| MS3 — Farmacia, Facturación, BI | **Spring Boot** + PostgreSQL + web3j | ya funciona | `localhost:8080/graphql` |
| ms-blockchain | Node/Express + Solidity (Polygon Amoy) | ya funciona | `localhost:3001` |
| Gateway GraphQL | Apollo Federation (federa MS1 + MS3) | crear | `localhost:4000` |
| Identidad / 4 roles | Supabase Auth (JWT) | ya integrado | externo (cloud) |
| Automatización | n8n | externo | externo |

**Bases de datos:** PostgreSQL nativo en `localhost:5432` (sin docker), con dos bases: `ms_pacientes` (MS1) y `ms_gestion` (MS3). NoSQL: **AWS DynamoDB** (MS2). Archivos: **AWS S3** nativo con versionado (MS2).

---

## 1. Análisis del repo actual

```
cli/
├── apps/
│   ├── web-angular/   Angular: sidebar dinámico, guards por rol, Supabase, features ya hechas
│   └── mobile-rn/     React Native (pacientes)
├── services/
│   ├── ms-gestion/    Spring Boot, PostgreSQL, GraphQL → MS3 (ya funciona, hace de monolito)
│   ├── ms-blockchain/ Node/Express + Solidity (Polygon Amoy) — REST
│   └── _futuros/      Placeholders: ms-pacientes, ms-gateway, ms-diagnosticos
├── infra/db/migrations/  V1..V5
├── packages/contracts/   schema.graphql
└── docs/
```

**Ya funciona y se conserva:**
- `ms-gestion` (MS3): auth Supabase (`SupabaseJwtConverter` lee `app_metadata.role`), 4 roles en `RolEnum`, GraphQL (Spring for GraphQL).
- `web-angular`: sidebar `menu-items.ts`, guards `auth.guard.ts`/`role.guard.ts`, `supabase.service.ts`, `core/graphql/queries.ts`. Features: caja, recepción, dashboard-bi, administración, inventario, mis-recetas, mis-facturas, forbidden. Ya apunta a `localhost:8080` y `localhost:3001`.
- `ms-blockchain`: `POST /recetas`, `GET /recetas/verificar` sobre Polygon Amoy. **No tocar.**

**Falta:** historia clínica, citas, diagnóstico/IA, gestión documental, versionado, y los servicios MS1 y MS2.

---

## 2. Qué se reúsa, qué se crea, qué se ajusta

| | Detalle |
|---|---|
| **Se conserva** | MS3 (`ms-gestion`, Java), `ms-blockchain` (Node), todo el Angular. No se reescribe Java. |
| **Se crea** | MS1 (Next.js), MS2 (Django/DRF), Gateway, y 5 componentes Angular. |
| **Se ajusta en MS3** | Cortar FKs cruzadas: `paciente_id` y `usuario_id` → UUID de referencia sin `REFERENCES`. El paciente pasa a MS1. |

**Llave universal entre servicios:** `supabase_uid`. Ningún servicio comparte tablas.

---

## 3. Comunicación entre piezas (importante)

| Frontera | Protocolo | Nota |
|---|---|---|
| Angular ↔ Gateway | **GraphQL** | Cumple el requisito GraphQL frontend↔backend |
| Gateway ↔ MS1 / MS3 | GraphQL (federación) | Solo MS1 y MS3 exponen subgrafo |
| **Angular ↔ MS2** | **REST (DRF)** | MS2 NO se federa: subir imagen, ver diagnóstico, documentos por REST directo |
| MS3 ↔ ms-blockchain | REST (web3j → Polygon) | Anclar/verificar hash |
| MS2 ↔ ms-blockchain | REST | Anclar hash de documento/versión |
| n8n ↔ MS1 | GraphQL/HTTP | n8n llama `crearCita` |

> Que MS2 sea REST es válido: GraphQL solo es obligatorio entre el frontend y el backend de gestión (MS1+MS3). La comunicación con un servicio de IA por REST es la práctica estándar.

---

## 4. Bases de datos y esquemas finales

### MS1 — `ms-pacientes` (PostgreSQL local) · `prisma/schema.prisma`

FKs internas SÍ existen (mismo servicio).

```prisma
generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql"; url = env("DATABASE_URL") } // postgresql://...@localhost:5432/ms_pacientes

enum RolNombre      { ADMINISTRADOR MEDICO FARMACEUTICO PACIENTE }
enum EstadoCita     { AGENDADA ATENDIDA CANCELADA }
enum EstadoHistoria { ABIERTA CERRADA }

model Rol {
  id Int @id @default(autoincrement())
  nombre RolNombre @unique
  descripcion String?
  usuarios Usuario[]
  @@map("rol")
}
model Usuario {
  id String @id @default(uuid()) @db.Uuid
  supabaseUid String @unique @map("supabase_uid")
  nombre String
  email String @unique
  rolId Int @map("rol_id")
  rol Rol @relation(fields: [rolId], references: [id])
  activo Boolean @default(true)
  @@map("usuario")
}
model Paciente {
  id String @id @default(uuid()) @db.Uuid
  supabaseUid String? @unique @map("supabase_uid")
  ci String @unique
  nombre String
  apellido String
  telefono String?
  email String?
  fechaNacimiento DateTime? @map("fecha_nacimiento") @db.Date
  citas Cita[]
  historia HistoriaClinica?
  @@map("paciente")
}
model Cita {
  id String @id @default(uuid()) @db.Uuid
  pacienteId String @map("paciente_id") @db.Uuid
  paciente Paciente @relation(fields: [pacienteId], references: [id])
  medicoUid String @map("medico_uid")
  especialidad String?
  fechaHora DateTime @map("fecha_hora")
  urgencia String?            // nivel de pre-triaje (IA de MS2)
  estado EstadoCita @default(AGENDADA)
  motivo String?
  episodios Episodio[]
  @@index([pacienteId])
  @@map("cita")
}
model HistoriaClinica {
  id String @id @default(uuid()) @db.Uuid
  pacienteId String @unique @map("paciente_id") @db.Uuid
  paciente Paciente @relation(fields: [pacienteId], references: [id])
  fechaApertura DateTime @default(now()) @map("fecha_apertura")
  estado EstadoHistoria @default(ABIERTA)
  episodios Episodio[]
  @@map("historia_clinica")
}
model Episodio {               // inmutable: no se edita ni borra (regla de app)
  id String @id @default(uuid()) @db.Uuid
  historiaId String @map("historia_id") @db.Uuid
  historia HistoriaClinica @relation(fields: [historiaId], references: [id])
  citaId String? @map("cita_id") @db.Uuid
  cita Cita? @relation(fields: [citaId], references: [id])
  medicoUid String @map("medico_uid")
  fecha DateTime @default(now())
  motivoConsulta String? @map("motivo_consulta")
  evolucion String?
  diagnosticoTexto String? @map("diagnostico_texto")
  @@index([historiaId])
  @@map("episodio")
}
```

### MS2 — `ms-diagnosticos` (AWS DynamoDB + S3) · vía DRF

Archivos reales en **S3 nativo con Versioning**. Metadatos pequeños en DynamoDB.

| Tabla DynamoDB | PK / SK | Atributos | Notas |
|---|---|---|---|
| `documento` | PK `documento_id`, SK `version` | `paciente_id`, `episodio_id`, `s3_key`, `s3_version_id`, tipo, nombre_original, tamano, content_type, `hash_documento`, `editado_por`, `motivo_cambio`, `vigente`, created_at | Versionado: una fila por versión; `vigente=true` solo en la última. GSI `paciente_id-index`. |
| `diagnostico` | PK `diagnostico_id` | `paciente_id`, `documento_id`, tipo_estudio, hallazgo, confianza, `modelo_version`, **modo** (SUPERVISADO/NO_SUPERVISADO), created_at | Resultado del ML. GSI `paciente_id-index`. |
| `auditoria` | PK `audit_id` | `documento_id`, accion, `usuario_uid`, rol, timestamp | Bitácora. GSI `documento_id-index`. |

Tablas y bucket se crean con el script `ms2-diagnosticos-tables.py` (boto3).

### MS3 — `ms-gestion` (PostgreSQL local + Polygon) · cambios del refactor

Conserva el esquema actual. **Cambios:** se quitan `rol`, `usuario`, `paciente` (van a MS1); `paciente_id`/`usuario_id` → `UUID` sin `REFERENCES`; el rol se lee del JWT. Tablas que quedan: `categoria`, `proveedor`, `medicamento`, `lote`, `movimiento_inventario`, `receta` (con `hash_documento`, `blockchain_tx`, `blockchain_id`), `detalle_receta`, `factura`, `detalle_factura`. (Detalle en `ms3-gestion-schema.sql`.)

---

## 5. IA / Machine Learning en MS2 (supervisado + NO supervisado)

El examen exige **los dos**. MS2 implementa:

| Modelo | Tipo | Qué hace | Cómo |
|---|---|---|---|
| **Clasificación de imágenes** | **Supervisado** | Etiqueta una radiografía/estudio (ej. normal / anómalo / categoría) y da una confianza | CNN con PyTorch o TensorFlow (o Vertex AI) |
| **Detección de anomalías / agrupamiento** | **No supervisado** | Marca imágenes "raras" (autoencoder) o agrupa estudios similares (K-means sobre embeddings) | Autoencoder o K-means; sin etiquetas |

Cada predicción se guarda en la tabla `diagnostico` con su campo `modo` (`SUPERVISADO` o `NO_SUPERVISADO`). El **pre-triaje** (NLP que sugiere especialidad y urgencia desde los síntomas) también vive en MS2 y escribe `urgencia` en la `cita` de MS1.

---

## 6. Autenticación Supabase y los 4 roles

- Un solo proyecto Supabase; el rol va en `app_metadata.role`. Misma JWKS (`SUPABASE_JWKS_URI`) en los 3 servicios.
- MS3 (Spring) ya lo tiene; MS1 (Next.js) usa `jose`+`jwks-rsa`; MS2 (Django/DRF) usa `PyJWT`+JWKS.
- El frontend oculta por rol (UX); cada backend bloquea de verdad. Paciente: filtrar por `supabase_uid`.

| Operación | ADMIN | MEDICO | FARMA | PACIENTE |
|---|:-:|:-:|:-:|:-:|
| Usuarios/roles, BI | ✓ | | | |
| Citas | ✓ | ✓ | | ✓ (propias) |
| Historia clínica | ✓ | ✓ | | ✓ (propia) |
| Emitir receta (→ blockchain) | | ✓ | | |
| Subir imagen / ver diagnóstico IA | ✓ | ✓ | | ✓ (subir/ver propio) |
| Inventario / dispensar / verificar receta | ✓ | | ✓ | |
| Facturar | ✓ | | ✓ | |

---

## 7. Frontend Angular por rol

### 7.1 Sidebar extendido — `menu-items.ts`

```typescript
export const MENU: MenuItem[] = [
  { label: 'Recepción',       icon: 'pi-users',        route: '/recepcion',     roles: ['ADMINISTRADOR','FARMACEUTICO'] },
  { label: 'Caja',            icon: 'pi-shopping-cart',route: '/caja',          roles: ['ADMINISTRADOR','FARMACEUTICO'] },
  { label: 'Inventario',      icon: 'pi-box',          route: '/inventario',    roles: ['ADMINISTRADOR','FARMACEUTICO'] },
  { label: 'Administración',  icon: 'pi-cog',          route: '/administracion',roles: ['ADMINISTRADOR'] },
  { label: 'Dashboard BI',    icon: 'pi-chart-bar',    route: '/dashboard',     roles: ['ADMINISTRADOR'] },
  { label: 'Mis recetas',     icon: 'pi-file-edit',    route: '/mis-recetas',   roles: ['MEDICO','PACIENTE'] },
  { label: 'Mis facturas',    icon: 'pi-receipt',      route: '/mis-facturas',  roles: ['PACIENTE'] },
  { label: 'Citas',           icon: 'pi-calendar',     route: '/citas',         roles: ['ADMINISTRADOR','MEDICO','PACIENTE'] },     // MS1
  { label: 'Historia clínica',icon: 'pi-clipboard',    route: '/historia',      roles: ['ADMINISTRADOR','MEDICO'] },                // MS1
  { label: 'Diagnóstico IA',  icon: 'pi-bolt',         route: '/diagnostico',   roles: ['ADMINISTRADOR','MEDICO'] },                // MS2 (REST)
  { label: 'Documentos',      icon: 'pi-folder',       route: '/documentos',    roles: ['ADMINISTRADOR','MEDICO','PACIENTE'] },     // MS2 (REST)
  { label: 'Pre-triaje',      icon: 'pi-upload',       route: '/pre-triaje',    roles: ['PACIENTE'] },                              // MS2 → MS1
];
```

### 7.2 Componentes nuevos

| Componente | Ruta | Roles | Pega a | Protocolo |
|---|---|---|---|---|
| `citas/` | `/citas` | admin, médico, paciente | MS1 | GraphQL |
| `historia/` | `/historia` | admin, médico | MS1 | GraphQL |
| `diagnostico/` | `/diagnostico` | admin, médico | MS2 | **REST** |
| `documentos/` | `/documentos` | admin, médico, paciente | MS2 | **REST** |
| `pre-triaje/` | `/pre-triaje` | paciente | MS2 → MS1 | REST + GraphQL |

`environment.ts` añade `ms2Url: 'http://localhost:8000'` para las llamadas REST a MS2 (las de MS1/MS3 van a `graphqlUrl` del Gateway).

---

## 8. Ejecución local (solo local)

```
PostgreSQL   localhost:5432   (nativo, bases: ms_pacientes, ms_gestion)
MS3 gestión  localhost:8080   ./mvnw spring-boot:run
blockchain   localhost:3001   npm start
MS1 next     localhost:3000   npm run dev   (DATABASE_URL → ms_pacientes)
MS2 django   localhost:8000   python manage.py runserver
Gateway      localhost:4000   npm start     (federa 3000 + 8080)
Angular      localhost:4200   ng serve      (graphqlUrl → 4000, ms2Url → 8000)
```

> **AVISO (requisito del examen):** "solo local" sirve para desarrollar y demostrar en tu máquina, pero el examen pide los 3 microservicios en **3 nubes distintas** (AWS/GCP/Azure). Plan recomendado: desarrolla local y **despliega al final** a la nube. S3, DynamoDB y Supabase ya son cloud; faltaría subir MS1/MS2/MS3.

---

## 9. Plan por fases

0. **Preparación:** crear bases `ms_pacientes` y `ms_gestion` en Postgres local; bucket S3 con Versioning; respaldar datos de `ms-gestion`.
1. **Cortar FKs en MS3** (migración: `paciente_id`/`usuario_id` → UUID sin `REFERENCES`).
2. **Crear MS1 (Next.js)** con Prisma, GraphQL, auth Supabase; migrar `paciente`.
3. **Crear MS2 (Django/DRF)** con DynamoDB + S3 versionado, endpoints REST, modelo supervisado + no supervisado, auth Supabase.
4. **Gateway** federa MS1 + MS3; Angular → Gateway.
5. **Frontend:** 5 componentes + sidebar extendido (citas/historia por GraphQL; diagnóstico/documentos/pre-triaje por REST a MS2).
6. **n8n:** flujo WhatsApp → `crearCita` en MS1 → email/push (documentar).

---

## 10. PROMPT A — Claude Code (backend, local-first)

```
Trabaja sobre este monorepo (raíz `cli`). Sistema de clínica. Ejecución LOCAL (sin docker):
PostgreSQL nativo en localhost:5432 con dos bases (ms_pacientes, ms_gestion).
Objetivo: pasar de monolito (ms-gestion) a 3 microservicios con bases separadas, auth Supabase y 4 roles.
NO tocar ms-blockchain (Node/Express + Polygon Amoy, REST, queda igual en localhost:3001).

STACK FIJO: MS1 Next.js (GraphQL, localhost:3000), MS2 Django REST Framework (REST, localhost:8000),
MS3 ms-gestion Spring Boot (GraphQL, localhost:8080, YA FUNCIONA). Gateway Apollo Federation (localhost:4000)
federa SOLO MS1 + MS3. MS2 NO se federa (es REST puro).

REGLAS:
- Llave universal entre servicios: supabase_uid. NADA de FKs entre bases de servicios distintos.
- Los 3 servicios validan el MISMO JWT de Supabase con la MISMA JWKS (env SUPABASE_JWKS_URI), rol en app_metadata.role.
- ms-gestion ya tiene auth Supabase (SupabaseJwtConverter; RolEnum ADMINISTRADOR/MEDICO/FARMACEUTICO/PACIENTE).

FASE 1 — Adelgazar ms-gestion (MS3):
- Migración que convierta receta.paciente_id, factura.paciente_id, factura.usuario_id y
  movimiento_inventario.usuario_id en UUID SIN `REFERENCES`. Quitar la responsabilidad de la tabla paciente.
- Si el código Java hacía JOIN a paciente, usar paciente_id como referencia; si necesita datos del paciente,
  pedirlos por HTTP a MS1 (PacienteClient WebClient análogo a BlockchainClient).

FASE 2 — Crear MS1 = services/ms-pacientes (Next.js, solo backend, sin UI):
- Next.js App Router SOLO como API: GraphQL en app/api/graphql/route.ts (Apollo Server o graphql-yoga). Sin páginas.
- Prisma + PostgreSQL (DATABASE_URL → localhost:5432/ms_pacientes). Modelos: rol, usuario, paciente, cita,
  historia_clinica, episodio (episodio inmutable; cita con urgencia y estado AGENDADA|ATENDIDA|CANCELADA).
- Auth Supabase (jose + jwks-rsa); guard por resolver; paciente solo sus datos (filtro por supabase_uid).
- Mutations: crearCita, crearEpisodio. Queries: misCitas, citas, historiaPorPaciente.
- Migrar filas de paciente desde ms_gestion a ms_pacientes. README con cómo correr en local (npm run dev).

FASE 3 — Crear MS2 = services/ms-diagnosticos (Django REST Framework, REST):
- Django + DRF + boto3. AWS S3 nativo con Versioning para archivos; DynamoDB para metadatos.
- Tablas DynamoDB: documento (PK documento_id, SK version; vigente=true en la última), diagnostico
  (modo SUPERVISADO|NO_SUPERVISADO), auditoria. GSIs por paciente_id y documento_id.
- Endpoints REST: POST subir documento (genera versión nueva vía S3 presigned, NO sobrescribe),
  GET versiones de un documento, GET descargar (presigned), POST diagnosticar (corre el modelo), GET diagnósticos.
  Cada acción escribe en auditoria.
- IA: modelo SUPERVISADO (clasificación de imágenes con PyTorch/TensorFlow) y modelo NO SUPERVISADO
  (autoencoder de anomalías o K-means de agrupamiento). Dejar predict_supervisado() y predict_no_supervisado().
- Pre-triaje: endpoint que recibe síntomas (texto) y devuelve especialidad + urgencia.
- Al anclar un documento, llamar POST /recetas de ms-blockchain con el hash.
- Auth Supabase (PyJWT + JWKS). README con cómo correr en local (runserver) y variables AWS.

FASE 4 — Gateway = services/ms-gateway (Apollo Federation):
- Federa subgrafos de ms-pacientes (3000) y ms-gestion (8080) en localhost:4000. Activa @key en Paciente y Usuario.

ENTREGABLES POR FASE: código + migraciones + README local (sin docker); no borrar datos sin migración de copia;
dejar el repo corriendo en local. Empieza por la FASE 1 y muéstrame el plan de archivos antes de escribir código.
```

---

## 11. PROMPT B — Claude Code (frontend Angular)

```
Trabaja sobre apps/web-angular. Angular standalone con Apollo Client, Supabase auth y sidebar dinámico por rol.
NO rehagas lo existente; CONSTRUYE sobre el patrón actual (menu-items.ts MENU, authGuard+roleGuard con data.roles,
core/graphql/queries.ts, features standalone en src/app/features/).

IMPORTANTE: citas e historia hablan con MS1 por GraphQL (Gateway en environment.graphqlUrl).
diagnóstico, documentos y pre-triaje hablan con MS2 por REST (añade environment.ms2Url = 'http://localhost:8000';
usa HttpClient/fetch, NO Apollo, para esos tres).

CREA 5 COMPONENTES STANDALONE, registrados en app.routes.ts con [authGuard, roleGuard] y data.roles:

1) citas/ → /citas → ['ADMINISTRADOR','MEDICO','PACIENTE'] → MS1 GraphQL
   Lista de citas (PACIENTE solo misCitas). Mutation crearCita(pacienteId, medicoUid, especialidad, fechaHora, motivo).
2) historia/ → /historia → ['ADMINISTRADOR','MEDICO'] → MS1 GraphQL
   Selector de paciente → historia + episodios (solo lectura). Query historiaPorPaciente(pacienteId).
3) diagnostico/ → /diagnostico → ['ADMINISTRADOR','MEDICO'] → MS2 REST
   POST imagen a {ms2Url}/documentos (presigned) y POST {ms2Url}/diagnosticar; muestra hallazgo, confianza, modo.
4) documentos/ → /documentos → ['ADMINISTRADOR','MEDICO','PACIENTE'] → MS2 REST
   GET {ms2Url}/documentos del paciente con sus VERSIONES (vigente en la última); descargar por presigned.
   PACIENTE solo los suyos. Mostrar quién subió cada versión (auditoría).
5) pre-triaje/ → /pre-triaje → ['PACIENTE'] → MS2 REST + MS1 GraphQL
   Formulario de síntomas → POST {ms2Url}/pre-triaje (devuelve especialidad+urgencia) → precarga crearCita en /citas.

DESPUÉS: añade al MENU de menu-items.ts: Citas, Historia clínica, Diagnóstico IA, Documentos, Pre-triaje.
Añade ms2Url a environment.ts y environment.prod.ts.

SEGURIDAD: roleGuard solo oculta en UI; MS1/MS3 bloquean de verdad por el rol del JWT. No pongas autorización solo en el front.
ENTREGABLE: Angular compilando (ng build). Empieza por el componente de Citas y muéstrame su código antes de seguir.
```

---

## 12. Checklist del examen

| Requisito | Cumple con | Estado |
|---|---|---|
| 3+ microservicios | MS1, MS2, MS3 (+ ms-blockchain) | ✓ |
| 3 lenguajes | TypeScript, Python, Java | ✓ |
| GraphQL frontend↔backend | Angular ↔ Gateway (MS1+MS3) | ✓ |
| 2 tipos de BD | PostgreSQL (SQL) + DynamoDB (NoSQL) | ✓ |
| Gestión documental | S3 nativo + versionado + auditoría (MS2) | ✓ |
| Blockchain | Hash de recetas en Polygon (MS3) | ✓ |
| IA/ML supervisado **y no supervisado** | MS2: clasificación + anomalías/clustering | ⚠ añadir el no supervisado |
| App móvil 3 recursos nativos | RN: cámara, GPS, push | ✓ |
| Automatización 3+ pasos | n8n WhatsApp → MS1 → email/push | ✓ |
| Inteligencia de negocios | Dashboard BI en Angular | ✓ |
| 4 roles aplicados | Supabase + sidebar + guards + bloqueo backend | ✓ |
| **3 proveedores cloud distintos** | — | ⚠ requiere desplegar (hoy es local) |

---

## 13. Pendientes a resolver

1. **Modelo NO supervisado en MS2** — solo marcaste supervisado; el examen pide ambos. Es el hueco más urgente.
2. **Despliegue cloud** — "solo local" no cumple el requisito de 3 nubes. Desarrolla local y despliega al final, o confírmalo con el profesor.
3. **Next.js vs NestJS** — confirma que el profesor acepta Next.js usado como backend puro.
4. Respaldar la BD de `ms-gestion` antes de la Fase 1.

### Archivos complementarios (generados aparte)
- `ms1-pacientes-schema.prisma`, `ms3-gestion-schema.sql`, `ms2-diagnosticos-tables.py`.
