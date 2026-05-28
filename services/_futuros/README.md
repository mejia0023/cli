# Microservicios futuros (placeholders)

Esta carpeta **NO contiene código**. Solo documenta los servicios que serán implementados por los otros estudiantes del equipo.

## ms-pacientes (Javier — NestJS / AWS)

**Responsable:** Javier
**Stack:** Node.js + NestJS + (PostgreSQL o MongoDB) + AWS (EC2 / Elastic Beanstalk / Lambda)
**Función:** dueño canónico del agregado paciente y de las citas médicas.

**Contrato con ms-gestion:**
- Cuando Javier publique la primera versión, ms-gestion dejará de escribir en la tabla `paciente` local (que actualmente actúa como referencia mínima).
- Identificador universal: `supabase_uid`.
- Coordinación detallada en [`../../docs/integracion-javier.md`](../../docs/integracion-javier.md).

## ms-gateway (Javier — Apollo Federation o GraphQL Mesh)

**Responsable:** Javier
**Stack:** NestJS + Apollo Federation / GraphQL Mesh
**Función:** federar los subgrafos de ms-gestion, ms-pacientes y ms-diagnosticos en un único endpoint GraphQL.

**Cuando esté listo:**
- Angular y la app móvil apuntarán al gateway, no a ms-gestion directamente.
- ms-gestion sigue exponiendo su `/graphql` (es el subgrafo); el gateway lo introspecta.

## ms-diagnosticos (José — FastAPI / GCP)

**Responsable:** José Eduardo
**Stack:** Python + FastAPI + Vertex AI + S3 + DynamoDB
**Función:** análisis de imágenes médicas con IA, almacenamiento de historiales y PDFs.

**Contrato con ms-gestion:**
- No comparte tablas. Si necesita ligar un diagnóstico a una receta, abrir migración Vn en `infra/db/migrations/` para agregar `diagnostico_id` a `receta`.
- Identificador universal: `supabase_uid`.
- Coordinación detallada en [`../../docs/integracion-jose.md`](../../docs/integracion-jose.md).

## Reglas

- **Nadie crea código stub aquí.** Esta carpeta solo tiene READMEs y eventualmente un `openapi.yaml` / `schema.graphql` cuando los compañeros lo publiquen.
- **Identidad única vía Supabase Auth.** Los 3 servicios validan el mismo JWT con la misma URL JWKS.
- **CORS** del ms-gestion se ajusta vía env var cuando aparezcan nuevos dominios.
