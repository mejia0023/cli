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

## Cómo levantar el entorno local

Requisitos: Docker Desktop, JDK 17, Maven, Node 20+, Angular CLI 17.

```powershell
# 1. PostgreSQL
docker compose up -d postgres

# 2. Blockchain local (nodo Hardhat + ms-blockchain)
cd services\ms-blockchain
npm install
npx hardhat node                                # terminal aparte
npx hardhat run scripts/deploy.js --network localhost
node src/server.js                              # API en 3001

# 3. ms-gestion (Spring Boot)
cd services\ms-gestion
.\mvnw spring-boot:run                          # GraphQL en 8080, GraphiQL en /graphiql

# 4. Angular
cd apps\web-angular
npm install
ng serve                                        # http://localhost:4200
```

## Plan de implementación

Documento completo en `C:\Users\Usuario\.claude\plans\javier-app-m-vil-react-snoopy-shannon.md`.
