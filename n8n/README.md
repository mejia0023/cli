# n8n — Recordatorios de citas (push 24h)

Workflow importable: [`recordatorios-citas.json`](./recordatorios-citas.json).

Cada día a las **08:00 (America/La_Paz)** hace login como administrador en Supabase,
obtiene un `access_token` y llama la mutation `enviarRecordatorios` de **MS1
(ms-pacientes)**, que envía un push a cada paciente con una cita **AGENDADA mañana**.

```
Schedule 08:00 La Paz  ──▶  Login Supabase  ──▶  Enviar recordatorios
 (cron 0 8 * * *)            (POST /token)        (POST /api/graphql -> MS1)
```

## Cómo importar

1. En n8n: **Workflows → Import from File** y elige `recordatorios-citas.json`.
   (También sirve copiar el JSON y pegarlo con **Import from URL/Clipboard**.)
2. La zona horaria del cron ya viene fijada en el workflow (`Settings → Timezone =
   America/La_Paz`). Verifícala tras importar.
3. Reemplaza los **3 placeholders** (abajo) y guarda.
4. **Execute Workflow** para probar a mano; activa el toggle cuando funcione.

## Los 3 placeholders a reemplazar

| Placeholder | Dónde | Qué poner |
|---|---|---|
| `REEMPLAZAR_ANON_KEY` | nodo **Login Supabase** → header `apikey` | La **anon/publishable key** del proyecto Supabase (`yiyfwfvxdseamnelgetf`). |
| `REEMPLAZAR_PASSWORD` | nodo **Login Supabase** → body JSON, campo `password` | La contraseña real de `admin@clinica.com`. |
| `REEMPLAZAR_NGROK` | nodo **Enviar recordatorios** → URL | El host público (ngrok u otro) que tunelea **MS1 en :3000**, p.ej. `abc123.ngrok-free.app`. La URL final queda `https://<host>/api/graphql`. |

> ⚠️ El endpoint es **MS1 directamente** (`/api/graphql`), no el gateway: la mutation
> `enviarRecordatorios` vive en MS1 y solo la puede ejecutar un **ADMINISTRADOR**.
> No comitees las keys/passwords reales: rellénalas dentro de n8n tras importar.

## Resultado esperado

El nodo **Enviar recordatorios** devuelve:

```json
{ "data": { "enviarRecordatorios": 1 } }
```

donde el número es cuántos push se enviaron (pacientes con cita AGENDADA mañana
que tienen un ExpoPushToken registrado).
