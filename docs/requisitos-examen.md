# Mapeo requisito del parcial ↔ implementación

Esta tabla rastrea cada requisito del parcial 2 al artefacto concreto del repo donde se cumple.

| # | Requisito del parcial | Cumplido por | Ubicación |
|---|---|---|---|
| 1 | **3+ microservicios en 3 proveedores cloud distintos** | ms-gestion (Azure), ms-blockchain (Render + Polygon Amoy), futuros: ms-pacientes (AWS, Javier) y ms-diagnosticos (GCP, José) | `services/` |
| 2 | **3 lenguajes distintos** | Java (ms-gestion), JavaScript/Solidity (ms-blockchain). Tercero: TypeScript en NestJS (Javier) + Python en FastAPI (José) | `services/ms-gestion`, `services/ms-blockchain` |
| 3 | **Servicios en instancias separadas** | Azure App Service plan B1, Render web service, Hardhat node local, Polygon Amoy | `infra/deploy/` |
| 4 | **Database per service** | PostgreSQL exclusivo de ms-gestion; ms-blockchain usa la propia blockchain como BD; futuros usarán DynamoDB (José) y otra BD (Javier) | `infra/db/migrations/` |
| 5 | **Mínimo 2 tipos de BD (SQL + NoSQL)** | PostgreSQL (SQL) en ms-gestion. NoSQL DynamoDB lo aporta José en sus historiales clínicos | Coordinación con José |
| 6 | **Gestión empresarial pequeño con GraphQL (NO REST) frontend↔backend** | Spring for GraphQL en ms-gestion; Apollo Client en Angular | `services/ms-gestion/src/main/resources/graphql/`, `apps/web-angular/src/app/core/graphql/` |
| 7 | **Gestión documental (Word/Excel/imágenes) en S3 o similar** | Responsabilidad de José (S3 + DynamoDB para historiales y PDFs) | Pendiente integración José |
| 8 | **App móvil con 3 recursos nativos (cámara, GPS, push)** | Responsabilidad de Javier (React Native) | Pendiente integración Javier |
| 9 | **IA/ML imágenes/video supervisado y no supervisado** | Responsabilidad de José (Vertex AI) | Pendiente integración José |
| 10 | **Blockchain registrando algo (factura/documento)** | ms-blockchain registra hash de recetas controladas en Polygon Amoy. Contrato `RegistroRecetas.sol` | `services/ms-blockchain/contracts/` |
| 11 | **Automatización 3+ pasos (WhatsApp → sistema → email)** | Responsabilidad de Javier (N8N + WhatsApp). ms-gestion publicará webhooks para alimentar el flujo | Pendiente integración Javier |
| 12 | **Inteligencia de negocios (gráficos/dashboards)** | Dashboard BI en Angular con 4 paneles Chart.js sobre vistas SQL. Resolvers `bi*` en ms-gestion. Solo ADMINISTRADOR. | `services/ms-gestion/.../bi/`, `apps/web-angular/.../dashboard-bi/` |
| 13 | **Metodología Unified Process** | Documentado en `docs/arquitectura/` con C4 + UML | `docs/arquitectura/`, `docs/modelo/` |
| 14 | **C4 para arquitectura, UML para resto** | C4 context + containers en PlantUML; UML clases, secuencia, despliegue | `docs/arquitectura/c4-*.puml`, `docs/modelo/*.puml` |

## Lo que sí debe defender Alimbert solo en su entrega

- ms-gestion en Azure funcionando con GraphQL.
- ms-blockchain en Render funcionando con Polygon Amoy + contrato verificable en explorer.
- Angular en Static Web Apps con login y sidebar dinámico por rol.
- Dashboard BI mostrando datos reales tras seed.
- Diagramas C4 y UML.
- Matriz de roles aplicada (frontend filtra + backend bloquea con `@PreAuthorize`).

## Lo que se aclarará en la defensa como "responsabilidad del compañero"

- Tipos de BD distintos (José aporta DynamoDB).
- App móvil RN (Javier).
- N8N WhatsApp (Javier).
- IA Vertex (José).
- Gestión documental S3 (José).
