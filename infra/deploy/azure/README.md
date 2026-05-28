# Despliegue Azure — ms-gestion + PostgreSQL + web-angular

## Recursos

- **Azure Database for PostgreSQL Flexible Server** (Burstable B1ms) — base de datos.
- **Azure App Service** (Linux, JAVA 17, plan B1) — host de ms-gestion.
- **Azure Static Web Apps** (Free) — host del Angular.

## Provisioning con Azure CLI

Requisitos: `az login`, suscripción activa, ~$30/mes de presupuesto (apagar fuera de demo).

```powershell
# Variables
$RG = "rg-clinica"
$LOC = "eastus"
$PG_SERVER = "clinica-pg-$((Get-Random -Maximum 9999))"
$PG_DB = "clinica_gestion"
$PG_USER = "clinica"
$PG_PASS = "<password fuerte 16+ chars>"
$APP_NAME = "ms-gestion-clinica-$((Get-Random -Maximum 9999))"

# 1. Resource group
az group create -n $RG -l $LOC

# 2. PostgreSQL Flexible Server
az postgres flexible-server create `
  -n $PG_SERVER -g $RG -l $LOC `
  --tier Burstable --sku-name Standard_B1ms `
  --admin-user $PG_USER --admin-password $PG_PASS `
  --version 16 --storage-size 32 `
  --public-access 0.0.0.0  # WARNING: abre a todas las IPs; restringir luego

az postgres flexible-server db create -s $PG_SERVER -d $PG_DB -g $RG

# 3. App Service plan + webapp
az appservice plan create -n plan-clinica -g $RG --sku B1 --is-linux
az webapp create -n $APP_NAME -g $RG -p plan-clinica --runtime "JAVA:17-java17"

# 4. Configurar variables de entorno
$DB_URL = "jdbc:postgresql://$PG_SERVER.postgres.database.azure.com:5432/$PG_DB`?sslmode=require"
az webapp config appsettings set -n $APP_NAME -g $RG --settings `
  DB_URL=$DB_URL `
  DB_USER=$PG_USER `
  DB_PASS=$PG_PASS `
  SPRING_PROFILES_ACTIVE=prod `
  SUPABASE_JWKS_URI="https://<tu-proyecto>.supabase.co/auth/v1/.well-known/jwks.json" `
  BLOCKCHAIN_URL="https://ms-blockchain-clinica.onrender.com" `
  CORS_ORIGINS="https://<tu-static-web>.azurestaticapps.net"

# 5. Build + deploy del JAR (despues de instalar Maven local o usar Dockerfile)
cd ..\..\..\services\ms-gestion
# .\mvnw clean package -DskipTests    # genera target/ms-gestion-*.jar
az webapp deploy -n $APP_NAME -g $RG `
  --src-path .\target\ms-gestion-0.0.1-SNAPSHOT.jar --type jar

# 6. Healthcheck
$URL = "https://$APP_NAME.azurewebsites.net"
Invoke-WebRequest "$URL/actuator/health"
```

## Despliegue del Angular a Static Web Apps

Opción más simple — desde GitHub con Action:

```powershell
# Crear Static Web App vinculada al repo (necesita el repo en GitHub primero)
az staticwebapp create -n swa-clinica -g $RG -l eastus2 `
  --source https://github.com/<usuario>/<repo> `
  --branch main `
  --app-location "apps/web-angular" `
  --output-location "dist/web-angular/browser" `
  --login-with-github
```

Si no hay repo en GitHub aún:

```powershell
# Build local
cd apps\web-angular
npm install
npm run build:prod

# Subir dist/ a Static Web App via SWA CLI
npm install -g @azure/static-web-apps-cli
swa deploy ./dist/web-angular/browser --deployment-token "<TOKEN_OBTENIDO_DEL_PORTAL>"
```

Configurar `apps/web-angular/staticwebapp.config.json` (ver archivo).

## Variables clave a configurar en producción

| Variable | Componente | Valor |
|---|---|---|
| `DB_URL` | ms-gestion | `jdbc:postgresql://<server>.postgres.database.azure.com:5432/clinica_gestion?sslmode=require` |
| `DB_USER` / `DB_PASS` | ms-gestion | de creación del Postgres |
| `SUPABASE_JWKS_URI` | ms-gestion + ms-blockchain | mismo en los dos |
| `BLOCKCHAIN_URL` | ms-gestion | URL pública de ms-blockchain en Render |
| `CORS_ORIGINS` | ms-gestion | URL de Static Web App + URL del Gateway de Javier cuando llegue |
| `SPRING_PROFILES_ACTIVE` | ms-gestion | `prod` |
| `environment.prod.ts` graphqlUrl | Angular | URL de App Service /graphql |

## Limpieza

```powershell
az group delete -n $RG --yes --no-wait
```
