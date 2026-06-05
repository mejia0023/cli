# ms-gateway — Gateway GraphQL (schema stitching)

Une **MS1** (`ms-pacientes`, `:3000/api/graphql`) y **MS3** (`ms-gestion`, `:8080/graphql`) en un
**único endpoint** `http://localhost:4000/graphql` para que el frontend (Angular) consulte un solo sitio.

## Por qué stitching (y no Apollo Federation)
Tras el refactor a microservicios, MS3 ya **no comparte tipos** con MS1 (usa `pacienteId`/`usuarioId`
como `UUID`, no objetos `Paciente`/`Usuario`). Los subgrafos son **disjuntos**, así que no hay entidades
que unir con `@key` (que es para lo que sirve Federation). **Stitching** los compone tal como están,
**sin tocar MS1 ni MS3**.

## ⚠️ Tras cambiar el SCHEMA de MS1: reiniciar el gateway
El gateway introspecciona MS1 **una sola vez al arrancar** (no hay re-introspección periódica).
Si agregas/cambias campos o mutations en MS1 (typeDefs/resolvers) — p.ej. `registrarPushToken`,
`enviarRecordatorios`, `notificarResultado` — debes **(1) levantar/redeployar MS1 primero y
(2) reiniciar el gateway** para que los exponga en `:4000`. Si no, las llamadas fallarán con
`Cannot query field ...` aunque MS1 ya tenga el campo. (Las queries de MS3 no se ven afectadas:
su SDL se lee de archivo, no por introspección.)

## Cómo funciona
- **MS1**: se introspecciona en vivo (graphql-yoga permite introspección sin token).
- **MS3**: su `/graphql` está protegido (no se puede introspeccionar sin token), así que el gateway
  **lee su SDL** de los `.graphqls` del repo (`../ms-gestion/src/main/resources/graphql`).
- En cada query, el gateway **reenvía el header `Authorization`** a ambos subgrafos; cada backend valida
  el JWT y aplica sus reglas por rol (`@PreAuthorize` en MS3, guards por resolver en MS1).

## Correr en local
```bash
cd services/ms-gateway
npm install
# Requiere MS1 levantado (:3000) para introspeccionar al arrancar.
# Para queries de gestión, además MS3 (:8080) debe estar corriendo.
npm run start            # http://localhost:4000/graphql
```

## Variables (.env, opcional)
- `MS1_URL` (def. `http://localhost:3000/api/graphql`)
- `MS3_URL` (def. `http://localhost:8080/graphql`)
- `MS3_SDL_DIR` (def. `../ms-gestion/src/main/resources/graphql`)
- `PORT` (def. `4000`)

## El frontend
Angular debe apuntar su `graphqlUrl` a `http://localhost:4000/graphql`. Las consultas de
pacientes/citas/historia se resuelven en MS1 y las de farmacia/recetas/facturación en MS3,
de forma transparente.
