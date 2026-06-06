# GUIA-COMPANERO.md — Levantar el proyecto Clinica desde CERO (Windows)

> Formato: cada paso muestra **el comando** y **lo que debe salir**. Si tu salida no
> se parece, ve a la sección 13 (Problemas comunes) antes de seguir.
> Repo: https://github.com/mejia0023/cli

## 0. Requisitos (instalar una sola vez)

| Herramienta | Versión | Verificar con | Debe salir (similar) |
|---|---|---|---|
| Git | cualquiera reciente | `git --version` | `git version 2.4x` |
| Node.js | 20+ | `node -v` | `v20.x` o `v22.x` |
| Python | 3.12 | `py -3.12 --version` | `Python 3.12.x` |
| Java JDK | 17+ | `java -version` | `openjdk version "17..."` |
| PostgreSQL | 16 nativo en :5432 | `psql -U postgres -c "select 1;"` | ` 1` |
| (móvil, opcional) Android Studio + un Android físico | — | `adb --version` | `Android Debug Bridge ...` |

**Pide por privado al dueño del repo** (NO están en git): ① URL y anon key de Supabase, ② service_role key (solo si vas a correr el seed), ③ contraseñas de los usuarios demo.

## 1. Clonar (en ruta CORTA, fuera de Documents)

```powershell
mkdir C:\dev -Force; cd C:\dev
git clone https://github.com/mejia0023/cli clinica
cd clinica
```
**Debe salir:** `Cloning into 'clinica'... done.` — ⚠️ Usa `C:\dev` sí o sí: en rutas largas o sincronizadas (Documents/OneDrive/Drive) el build Android revienta (límite CMake 250 chars + "ninja still dirty").

Recomendado: Seguridad de Windows → Exclusiones de antivirus → agregar `C:\dev`.

## 2. Variables de entorno

```powershell
copy .env.example .env
copy services\ms-pacientes\.env.example services\ms-pacientes\.env
copy services\ms-gateway\.env.example services\ms-gateway\.env
copy services\ms-blockchain\.env.example services\ms-blockchain\.env
copy services\ms-diagnosticos\.env.example services\ms-diagnosticos\.env
```
Edita cada `.env`: `DB_USER=postgres`, `DB_PASS=<tu password de Postgres>`, y pega la URL/anon key de Supabase donde el template lo pida. En `ms-blockchain/.env` deja el perfil LOCAL (RPC `http://127.0.0.1:8545`, contrato `0x5FbDB2315678afecb367f032d93F642f64180aa3`).

## 3. Crear bases de datos

```powershell
psql -U postgres -c "CREATE DATABASE ms_pacientes;"
psql -U postgres -c "CREATE DATABASE ms_gestion;"
```
**Debe salir:** `CREATE DATABASE` (x2). Si dice "already exists", también está bien.

## 4. MS1 — ms-pacientes (Next.js + Prisma, :3000) — TERMINAL 1

```powershell
cd C:\dev\clinica\services\ms-pacientes
npm install
npx prisma migrate deploy
npx prisma generate
npm run dev
```
**Debe salir:**
- migrate: `X migrations found ... applied` (crea tablas usuario, paciente, cita...)
- dev: `▲ Next.js ... - Local: http://localhost:3000` y `✓ Ready in Xs`

(El seed `npx prisma db seed` SOLO funciona con la service_role key configurada, porque lee los UIDs reales de Supabase. Si no la tienes, sáltalo: los datos demo ya existen vía migraciones V4/V5 de MS3.)

**Verificar:**
```powershell
curl.exe -s -X POST http://localhost:3000/api/graphql -H "Content-Type: application/json" -d "{\"query\":\"{ __typename }\"}"
```
**Debe salir:** `{"data":{"__typename":"Query"}}`

## 5. Blockchain LOCAL (3 terminales, EN ESTE ORDEN)

**TERMINAL 2 — nodo Hardhat (dejar abierta):**
```powershell
cd C:\dev\clinica\services\ms-blockchain
npm install
npm run node
```
**Debe salir:** `Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/` + lista de `Account #0: 0xf39F... (10000 ETH)`.

**TERMINAL 3 — deploy del contrato (se ejecuta y termina):**
```powershell
cd C:\dev\clinica\services\ms-blockchain
npm run deploy:local
```
**Debe salir:** `RecetaRegistry deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3` (dirección SIEMPRE igual en local; si difiere, actualiza CONTRACT_ADDRESS del .env).

**TERMINAL 4 — el microservicio (:3001):**
```powershell
npm run dev
```
**Debe salir:** `ms-blockchain escuchando en http://localhost:3001` (o similar `listening on 3001`).

⚠️ El nodo Hardhat es EFÍMERO: si lo cierras, las recetas registradas quedan huérfanas (ver Problemas #4).

## 6. MS3 — ms-gestion (Spring Boot + Flyway, :8080) — TERMINAL 5

```powershell
cd C:\dev\clinica\services\ms-gestion
.\mvnw.cmd spring-boot:run
```
**Debe salir** (primera vez tarda, descarga dependencias):
- `Flyway ... Successfully applied X migrations` (V3/V4/V5 cargan datos demo: Carlos CI 1234567, Paco CI 7777777, medicamentos, etc.)
- `Tomcat started on port 8080` + `Started MsGestionApplication`

## 7. Gateway federado (:4000) — TERMINAL 6

```powershell
cd C:\dev\clinica\services\ms-gateway
npm install
npm run dev
```
**Debe salir:** mensajes de introspección de subgrafos (MS1 y MS3) y `Gateway listo en http://localhost:4000/graphql`.

⚠️ REGLA DE ORO: el gateway lee los esquemas SOLO al arrancar. Si MS1 o MS3 cambian su GraphQL, **reinicia el gateway** o las mutations nuevas "no existirán".

## 8. MS2 — ms-diagnosticos (Django + IA, :8000) — TERMINAL 7

```powershell
cd C:\dev\clinica\services\ms-diagnosticos
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py runserver
```
**Debe salir:** `[ml] entrenando modelos demo... listo (RandomForest + IsolationForest)` (tarda unos segundos la primera vez) y luego `Starting development server at http://127.0.0.1:8000/`.

## 9. Frontend Angular (:4200) — TERMINAL 8

```powershell
cd C:\dev\clinica\apps\web-angular
npm install
```
Crea/edita `src/environments/environment.local.ts` con la URL y anon key de Supabase (mismo formato que `environment.ts`). Luego:
```powershell
npm start
```
**Debe salir:** `Application bundle generation complete` + `Local: http://localhost:4200/`.

## 10. Prueba end-to-end (la que confirma que TODO quedó bien)

1. Navegador → `http://localhost:4200` → login `admin@clinica.com` (contraseña: pedirla).
2. Pacientes → buscar `1234567` → **debe aparecer Carlos Rodriguez**.
3. Crear una cita para Carlos con fecha de MAÑANA → **"Cita creada"** y se asigna médico solo.
4. Como `medico@clinica.com`: Diagnóstico IA → subir cualquier imagen → **devuelve clase + % y un anomaly score** (con imágenes reales casi siempre "anómalo": el modelo demo entrena con datos sintéticos, es esperado).
5. Recetas: emitir una → en la terminal del Hardhat node **deben aparecer transacciones** (eth_sendRawTransaction); verificar receta → "Íntegra ✓".

Usuarios demo: admin@clinica.com (ADMINISTRADOR), medico@clinica.com (MEDICO), farma@clinica.com (FARMACEUTICO), jamessuperman74@gmail.com (PACIENTE Carlos), fracasosamesite@gmail.com (PACIENTE Paco).

## 11. App móvil (OPCIONAL — requiere Android físico)

Ruta rápida (Expo Go, sin push remoto): instala "Expo Go" del Play Store, conecta el cel por USB con Depuración USB activa, y:
```powershell
cd C:\dev\clinica\apps\mobile-rn
npm install
adb reverse tcp:8081 tcp:8081
adb reverse tcp:4000 tcp:4000
adb reverse tcp:3001 tcp:3001
npx expo start --localhost     # presiona "a" cuando cargue
```
**Debe salir:** QR + `Metro waiting on...`; al presionar `a`, la app abre en el teléfono. Login con Carlos/Paco. Los `adb reverse` hacen que "localhost" del teléfono = tu PC (se repiten si reconectas el cable). Para push remoto/build nativo, ver `HowRunReactMobile.md` (Ruta B: EAS + Firebase).

## 12. n8n (bots Telegram/WhatsApp) — nota

Los workflows viven en la cuenta n8n Cloud del dueño y apuntan a SU túnel ngrok; no necesitas correrlos para usar el sistema. Si quieres replicarlos: `n8n/recordatorios-citas.json` se importa en n8n (Workflows → Import from File) y `n8n/README.md` documenta los 3 placeholders (anon key, password admin, URL ngrok → `https://TU_NGROK/api/graphql` con header `ngrok-skip-browser-warning: true`).

## 13. Problemas comunes

| # | Síntoma | Causa → Solución |
|---|---|---|
| 1 | `EADDRINUSE :3000/:4000/:8080` | Puerto ocupado → `netstat -ano \| findstr :3000` y `taskkill /PID xxxx /F` |
| 2 | Prisma `Can't reach database server` | Postgres apagado o DB_PASS mal en `.env` de ms-pacientes |
| 3 | MS3: `FlywayException: checksum mismatch V4` | Alguien editó una migración aplicada → `psql -U postgres -d ms_gestion -c "DELETE FROM flyway_schema_history WHERE version='4';"` y reiniciar MS3 |
| 4 | "Receta no encontrada en blockchain" tras reiniciar Hardhat | Recetas huérfanas (nodo efímero) → `psql -U postgres -d ms_gestion -c "TRUNCATE detalle_receta, receta CASCADE;"` |
| 5 | Angular crea cita pero falla "fecha futura" | Estás mandando fecha pasada; usa mañana |
| 6 | Mutation nueva "no existe" en :4000 | Gateway viejo → reiniciar gateway (regla de oro §7) |
| 7 | Login falla en Angular/app | environment.local.ts / app.json sin las claves Supabase reales |
| 8 | Build Android: `CMAKE_OBJECT_PATH_MAX` o `ninja still dirty` | Proyecto en ruta larga/sincronizada → clonar en `C:\dev` + exclusión antivirus + borrar carpetas `.cxx` |
| 9 | `expo run:android`: "projectDirectory ... does not exist" tras mover el repo | Cachés con ruta vieja → borrar `android\.gradle`, `android\build`, `node_modules\.cache` y recompilar |
| 10 | Móvil: "Network request failed" al loguear | El teléfono no tiene internet propio (Supabase es cloud) o faltan `adb reverse` para :4000 |
| 11 | Seed de MS1 falla | Requiere SUPABASE_SERVICE_ROLE; si no la tienes, omite el seed (los demo ya vienen por Flyway) |
| 12 | Venv de Python roto tras mover carpeta | Rutas absolutas internas → borrar `.venv` y recrear (§8) |

## 14. Cheat-sheet diario (todo ya instalado)

Orden: Postgres (servicio) → T2 `npm run node` → T3 `deploy:local` → T4 `npm run dev` (blockchain) → T1 MS1 `npm run dev` → T5 MS3 `mvnw spring-boot:run` → T7 MS2 `runserver` → T6 gateway `npm run dev` → T8 Angular `npm start`. 

Atajo: abrir la carpeta en VS Code dispara `.vscode/tasks.json`, que levanta las terminales en el orden correcto automáticamente.
