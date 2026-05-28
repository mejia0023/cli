# Migraciones de base de datos (Flyway)

Migraciones SQL versionadas para la BD de ms-gestion (PostgreSQL 16).

## Estructura

- `migrations/V1__schema.sql` — DDL completo: extensiones, tipos ENUM, tablas, índices, triggers.
- `migrations/V2__views_bi.sql` — vistas SQL para el dashboard BI.
- `migrations/V3__seed_roles.sql` — semilla de los 4 roles del sistema + categorías base.
- `migrations/V4__seed_demo.sql` — datos demo (medicamentos, lotes, proveedores) para que el frontend tenga contenido al primer arranque.

## Convenciones

- Nombres: `V<n>__<descripcion_snake_case>.sql`.
- **NUNCA** modificar una migración ya aplicada; agregar una nueva (`V<n+1>`).
- Usar `IF NOT EXISTS` y `CREATE OR REPLACE` cuando aplique para idempotencia en dev.

## Ejecución automática (recomendado)

ms-gestion ejecuta Flyway al arranque (dependencia `flyway-core`). Lee las migraciones desde el classpath, configurado en `application.yml` con:

```yaml
spring.flyway.locations: filesystem:../../infra/db/migrations
```

en perfil `dev`, o `classpath:db/migration` en perfil `prod` (las migraciones se copian al jar con `maven-resources-plugin`).

## Ejecución manual (alternativa, sin Spring)

```powershell
docker run --rm `
  -v ${PWD}\infra\db\migrations:/flyway/sql `
  --network host `
  flyway/flyway:10 `
  -url=jdbc:postgresql://localhost:5432/clinica_gestion `
  -user=clinica -password=clinica migrate
```

## Reset en desarrollo

```powershell
docker compose down -v
docker compose up -d postgres
# Spring volverá a aplicar V1-V4 al arrancar
```

⚠️ `flyway clean` está DESHABILITADO en perfil prod por seguridad.
