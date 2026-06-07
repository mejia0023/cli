# GUIA-CHAT-IA-MOVIL.md — Asistente IA (pre-triaje conversacional) en la app móvil

> Funcionalidad: el paciente chatea sus síntomas en la app → **Gemini** (vía MS2)
> responde, sugiere especialidad + urgencia → un botón **agenda la cita** en MS1
> (lo que dispara el push de confirmación y el email automáticamente).
>
> **Seguridad de la API key**: la key vive SOLO en el backend. El móvil nunca la ve.
>
> ```
> App móvil ──(JWT del paciente)──► MS2 Django ──(GEMINI_API_KEY del .env)──► Gemini
>                                      │ si el LLM falla o no hay key
>                                      └──► clasificador por reglas (ml/triage.py)
> ```
>
> Híbrido para el requisito 9: ML supervisado/no supervisado (RandomForest +
> IsolationForest) y NLP por reglas siguen vivos; el LLM es la capa
> conversacional encima (a Gemini se le pasa la "pista" del clasificador).

## Paso 1 — Obtener la API key de Gemini (2 min, gratis)

1. Entra a **https://aistudio.google.com** con tu cuenta Google.
2. Botón **"Get API key"** → **"Create API key"** → copia la key (`AIza...`).

## Paso 2 — Configurarla en MS2

Edita `services/ms-diagnosticos/.env` (créalo desde `.env.example` si no existe) y agrega:

```env
GEMINI_API_KEY=AIza...tu_key...
GEMINI_MODEL=gemini-2.0-flash
```

Reinicia MS2:
```powershell
cd services\ms-diagnosticos
.\.venv\Scripts\Activate.ps1
python manage.py runserver
```
**Debe salir:** `Starting development server at http://127.0.0.1:8000/` (sin errores).

> Sin key, TODO funciona igual pero con el clasificador por reglas
> (`"metodo": "reglas-nlp (fallback sin LLM)"`). Útil si se acaba la cuota en plena demo.

## Paso 3 — Probar el endpoint SIN el móvil (recomendado)

```powershell
# 3.1 token de un usuario (Carlos):
$body = '{"email":"carlos.rodriguez@example.com","password":"LA_CLAVE"}'
$r = Invoke-RestMethod -Method Post -Uri "https://yiyfwfvxdseamnelgetf.supabase.co/auth/v1/token?grant_type=password" -Headers @{apikey="LA_ANON_KEY"} -ContentType "application/json" -Body $body
# 3.2 chat:
Invoke-RestMethod -Method Post -Uri "http://localhost:8000/api/chat-triaje" -Headers @{Authorization="Bearer $($r.access_token)"} -ContentType "application/json" -Body '{"mensaje":"tengo dolor de pecho y me falta el aire","historial":[]}'
```
**Debe salir** (similar):
```json
{ "respuesta": "Lamento que te sientas así... ¿el dolor apareció de golpe?",
  "especialidad": "Cardiologia", "urgencia": "ALTA",
  "agendar": true, "metodo": "gemini (gemini-2.0-flash)" }
```

## Paso 4 — Levantar lo que el móvil necesita

| Servicio | Puerto | Para qué |
|---|---|---|
| MS1 ms-pacientes | 3000 | crearCita + push |
| **Gateway (REINICIADO)** | 4000 | GraphQL de la app (`miPaciente`, `crearCita`) |
| MS2 ms-diagnosticos | 8000 | el chat IA |

## Paso 5 — Conectar el teléfono (Android por USB)

```powershell
adb devices                      # tu equipo como "device"
adb reverse tcp:8081 tcp:8081    # Metro
adb reverse tcp:4000 tcp:4000    # GraphQL
adb reverse tcp:3001 tcp:3001    # blockchain
adb reverse tcp:8000 tcp:8000    # ← NUEVO: el chat IA (MS2)
```
**Debe salir:** nada (silencio = éxito). `adb reverse --list` muestra los 4.

Lanza la app:
```powershell
cd apps\mobile-rn
npx expo start --localhost       # presiona "a"  (o npx expo run:android si usas dev build)
```

## Paso 6 — Usarlo en el móvil (la demo)

1. **Login** como paciente (Carlos).
2. Menú lateral ☰ → **"Asistente IA"**. **Debe salir:** burbuja de bienvenida del bot.
3. Escribe: `tengo dolor de pecho y me falta el aire desde anoche` → Enviar.
4. **Debe salir:** "El asistente está escribiendo..." → respuesta empática del bot →
   tarjeta verde **"Sugerencia: Cardiologia · urgencia ALTA"** con el botón
   **"Agendar cita de Cardiologia"**.
5. Toca el botón. **Debe salir:** burbuja "✅ Tu cita de Cardiologia quedó agendada
   para mañana..." **+ vibra el push de confirmación + llega el email** (cadena
   completa: IA → cita → notificaciones, sin tocar nada más).
6. Verifica la cita en Angular (lista de citas) o en la BD si quieres el cierre.

## Problemas comunes

| Síntoma | Causa → solución |
|---|---|
| Bot: "No pude procesar tu mensaje (Network request failed)" | Falta `adb reverse tcp:8000` o MS2 apagado |
| Bot responde pero `metodo` = fallback | Key vacía/mal pegada en `.env` de MS2 (reinicia MS2 tras editarla) |
| HTTP 401 en el chat | Sesión expirada → cerrar sesión y volver a entrar |
| HTTP 429 / error de cuota | Capa gratuita de Gemini agotada → espera unos minutos o cambia `GEMINI_MODEL` (p. ej. `gemini-2.0-flash-lite`); la demo sigue viva por el fallback |
| Botón Agendar falla: "Cannot query field" | Gateway viejo → **reinícialo** (introspecciona solo al arrancar) |
| Bot: "No encontré tu registro de paciente" | La cuenta logueada no tiene fila `paciente` vinculada (usa Carlos/Paco) |
| "La fecha de la cita debe ser futura" | No debería: la pantalla agenda para mañana; revisa la hora del sistema |

## Para la defensa (2 frases)

"La IA generativa corre detrás de nuestro microservicio de IA: el móvil manda el
JWT del paciente a MS2 y es MS2 quien usa la API key (nunca expuesta en el APK).
El LLM complementa —no reemplaza— nuestros modelos supervisado y no supervisado:
recibe la pista del clasificador por reglas y, si falla, el sistema degrada a él."
