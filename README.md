# Clínica — Sistema integral (Parcial 2 SW2)

Monorepo del sistema integral de gestión clínica. Arquitectura de microservicios con 3 proveedores cloud y 3 lenguajes distintos.

## Equipo y responsabilidades

| Estudiante | Responsabilidades |
|---|---|
| **Alimbert** (este repo) | Backend facturación + inventario farmacia (Spring Boot 3 / Azure) · Blockchain Polygon (Node + Solidity) · Web Angular (recepción, caja, administración) · Dashboard BI |
| Javier (integración futura) | App móvil React Native · Backend pacientes/citas (NestJS / AWS) · Automatización WhatsApp (N8N) · API Gateway GraphQL federado |
| José Eduardo (integración futura) | Backend diagnósticos (FastAPI / GCP) · IA Vertex AI · S3 + DynamoDB · Módulo web Angular para médicos |

## Roles del sistema

Administrador · Médico · Farmacéutico · Paciente. Ver [docs/matriz-roles.md](docs/matriz-roles.md).

## Estructura del monorepo

```
clinica/
├── apps/web-angular/         Angular 17 standalone (recepción, caja, inventario, administración, BI)
├── services/
│   ├── ms-gestion/           Spring Boot 3 + GraphQL + PostgreSQL → Azure
│   ├── ms-blockchain/        Node + Solidity + ethers.js → Polygon Amoy (Render)
│   └── _futuros/             Contratos esperados de Javier y José (READMEs, sin código stub)
├── packages/contracts/       SDL GraphQL exportado para federación futura
├── infra/db/                 Migraciones Flyway versionadas
└── docs/                     C4, UML, matriz roles, requisitos parcial
```


## ⚠️ Configuración antes de correr (CREDENCIALES)

Este repo es **público / listo para nube** — todos los secretos están **fuera de versión**. Antes de correr necesitas configurar tres lugares:

### 1. `.env` en la raíz (lo lee docker-compose y se pasa a los servicios)

```powershell
cp .env.example .env
# Editar .env con tus valores reales
```

### 2. `apps/web-angular/src/environments/environment.ts`

Reemplaza los placeholders `<YOUR_SUPABASE_URL>` y `<YOUR_SUPABASE_PUBLISHABLE_KEY>` con los valores de tu proyecto Supabase (Project Settings → API Keys → Publishable).

### 3. `services/ms-blockchain/.env`

```powershell
cp services/ms-blockchain/.env.example services/ms-blockchain/.env
# Editar con tu private key (Hardhat local o wallet con MATIC de Amoy)
```

### Setup Supabase (necesario para auth)

1. Crear proyecto en https://supabase.com.
2. Auth → Users → crear 4 usuarios test: `admin@clinica.com`, `medico@clinica.com`, `farma@clinica.com`, `paciente@clinica.com` con el password de tu elección.
3. SQL Editor → para cada uno asignar rol:
   ```sql
   UPDATE auth.users
   SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"role":"ADMINISTRADOR"}'::jsonb
   WHERE email = 'admin@clinica.com';
   -- Repetir cambiando rol/email para MEDICO, FARMACEUTICO, PACIENTE.
   ```
4. Copia tu **Project URL** y **Publishable key** a `apps/web-angular/src/environments/environment.ts`.
5. Copia tu **JWKS URI** (`https://<proyecto>.supabase.co/auth/v1/.well-known/jwks.json`) a `SUPABASE_JWKS_URI` en `.env`.


## Cómo levantar el entorno local

Requisitos: Docker Desktop, JDK 17, Maven 3.9+, Node 20+, Angular CLI 17.

```powershell
# 1. PostgreSQL (vía Docker; alternativa: Postgres nativo en 5432)
docker compose up -d postgres

# 2. Blockchain local (nodo Hardhat + ms-blockchain)
cd services\ms-blockchain
npm install
npx hardhat node                                # terminal aparte
npx hardhat run scripts/deploy.js --network localhost
# copiar la address devuelta a services/ms-blockchain/.env (CONTRACT_ADDRESS)
node src/server.js                              # API en :3001

# 3. ms-gestion (Spring Boot) — lee variables del .env raíz
cd services\ms-gestion
.\mvnw spring-boot:run                          # GraphQL en :8080, GraphiQL en /graphiql

# 4. Angular
cd apps\web-angular
npm install --legacy-peer-deps
ng serve                                        # http://localhost:4200
```


## Seed de datos

Las migraciones Flyway (V1-V5 en `infra/db/migrations/`) se aplican automáticamente al arrancar ms-gestion:

- **V1-V3**: schema, vistas BI, roles base.
- **V4**: usuarios + 3 pacientes + 8 medicamentos + lotes iniciales.
- **V5**: 30 facturas + 12 recetas + ~60 movimientos distribuidos en los últimos 30 días (para que el Dashboard BI se vea poblado al primer login).

Las recetas del seed usan `medico_uid = 'seed-medico-uid'` como placeholder. Para que el médico real las vea como "Mis recetas", sincroniza tras su primer login:

```sql
UPDATE receta SET medico_uid = '<UID Supabase del medico real>'
WHERE medico_uid = 'seed-medico-uid';
```


## Despliegue a la nube

- **ms-gestion** → Azure App Service + Azure Database for PostgreSQL. Ver [infra/deploy/azure/](infra/deploy/azure/README.md).
- **ms-blockchain** → Render web service + contrato deployed a Polygon Amoy testnet. Ver [infra/deploy/render/](infra/deploy/render/README.md).
- **web-angular** → Azure Static Web Apps. Reemplaza los placeholders de `environment.prod.ts` antes del build.


## ⚠️ Si vas a publicar este repo en GitHub/GitLab

El **historial de git de este repo contuvo credenciales reales** en commits anteriores (publishable key Supabase, UIDs de usuarios, password de demo). Aunque el HEAD actual está limpio, **los commits viejos siguen visibles en `git log`**.

Para limpiar el historial antes de hacer push público:

```powershell
# Opcion A — Repo nuevo (mas simple, recomendado)
# 1. Borrar la carpeta .git existente
Remove-Item -Recurse -Force .git
# 2. Inicializar de cero
git init
git add .
git commit -m "Initial commit: clinica monorepo sanitized"
# 3. Crear repo en GitHub y hacer primer push
git remote add origin https://github.com/<usuario>/<repo>.git
git push -u origin main

# Opcion B — Purgar history con git-filter-repo (preserva commits limpios)
pip install git-filter-repo
git filter-repo --replace-text replacements.txt
# Ver docs: https://github.com/newren/git-filter-repo
```

Después de publicar:
- Regenera tus claves Supabase (Project Settings → API → "Generate new secret") por si quedaron en el historial cacheado de algún tercero.
- Confirma que `.gitignore` cubre todo lo sensible — revisa con `git status` que no aparezcan `.env`, `c.c`, `node_modules/`, `target/`, etc.


## Comandos clave

```powershell
# Verificar migraciones aplicadas
docker exec -it clinica_postgres psql -U clinica -d clinica_gestion -c "SELECT version, description FROM flyway_schema_history ORDER BY installed_rank;"

# Empaquetar ms-gestion para deploy
cd services\ms-gestion ; .\mvnw clean package -DskipTests

# Build Angular para prod (reemplaza environment.prod.ts antes)
cd apps\web-angular ; ng build --configuration production
```
