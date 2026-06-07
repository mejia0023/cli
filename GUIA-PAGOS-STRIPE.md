# GUIA-PAGOS-STRIPE.md — Pagar medicamentos en línea (Stripe Checkout, modo test)

> Flujo: caja emite la factura **PENDIENTE** → el paciente toca **"Pagar en línea"**
> (app móvil o web) → página de pago alojada por Stripe → el **webhook** confirma y
> la factura pasa a **PAGADA** (idempotente). La caja presencial sigue igual que siempre.
>
> Seguridad: la `sk_test_...` vive SOLO en el `.env` de MS3; los montos salen SIEMPRE
> de la BD; un PACIENTE solo puede pagar SUS facturas (uid del JWT → MS1).
> Bolivia: Stripe no opera live aquí ni soporta BOB → **modo test + usd** (decisión
> documentada; en producción se cambiaría por un adquirente local tras la misma interfaz).

## Paso 0 — Claves de Stripe (3 min, gratis)
1. Crea cuenta en **https://dashboard.stripe.com** (queda en **modo Test**, dinero ficticio).
2. **Developers → API keys** → copia la **Secret key** `sk_test_...`.

## Paso 1 — Configurar MS3
Agrega a `services/ms-gestion/.env` (spring-dotenv lo lee al arrancar):
```env
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxx
# STRIPE_WEBHOOK_SECRET se llena en el Paso 3
```

## Paso 2 — Arrancar MS3 y el gateway
```powershell
cd services\ms-gestion
.\mvnw.cmd spring-boot:run
```
**Debe salir:** `Migrating schema "public" to version "6 - pagos online"` (Flyway crea
las columnas) y `Tomcat started on port 8080`.
> Si Maven se quejara bajando `stripe-java`, sube la versión en `pom.xml` a la última.

⚠️ **Reinicia el GATEWAY** (:4000): la mutation `crearCheckoutFactura` es nueva en el
subgrafo y el gateway solo introspecciona al arrancar.

## Paso 3 — Webhook en localhost (Stripe CLI)
```powershell
# instalar una vez: https://stripe.com/docs/stripe-cli  (o: scoop install stripe)
stripe login
stripe listen --forward-to localhost:8080/api/pagos/webhook
```
**Debe salir:** `Ready! Your webhook signing secret is whsec_xxxxx`.
Pega ese valor en el `.env` de MS3 como `STRIPE_WEBHOOK_SECRET=whsec_xxxxx`,
**reinicia MS3** y deja esta terminal ABIERTA (es el cartero de Stripe→tu PC).
> Sin CLI también funciona: con el secret vacío MS3 acepta el webhook con un WARN
> "SIN verificar (solo desarrollo)" — útil de emergencia, no para presumir.

## Paso 4 — Emitir una factura PENDIENTE (Angular, rol caja/farmacéutico)
`http://localhost:4200` → **Caja** → paciente *Carlos Rodriguez* → agrega un
medicamento → marca el checkbox **"Dejar PENDIENTE — el paciente la paga en línea"**
→ Facturar.
**Debe salir:** factura creada; en **Mis facturas** (como Carlos) aparece con badge
**gris PENDIENTE** y el botón de pago.

## Paso 5 — Pagar desde el MÓVIL (la demo estrella)
```powershell
adb reverse tcp:8081 tcp:8081
adb reverse tcp:4000 tcp:4000
adb reverse tcp:4200 tcp:4200   # opcional: para que la página de "pago exitoso" cargue bonita en el teléfono
```
1. App → login Carlos → **Mis facturas** → botón verde **"Pagar en línea con tarjeta"**.
2. Se abre el navegador con la página de Stripe. Tarjeta de prueba:
   **4242 4242 4242 4242**, fecha futura cualquiera, CVC 123, email cualquiera → Pay.
3. **Debe salir, en cascada:** en la terminal de `stripe listen`:
   `checkout.session.completed ... [200]`; en los logs de MS3:
   `[pagos] factura F-2026-0000xx marcada PAGADA via Stripe`;
   y en la app, **desliza hacia abajo** → badge **verde PAGADA**, método **TARJETA**.

(Rechazo para la demo: tarjeta `4000 0000 0000 9995` → Stripe muestra "fondos insuficientes" y la factura sigue PENDIENTE.)

## Paso 6 — Verificación en BD (opcional, cierre con broche)
```powershell
psql -U postgres -d ms_gestion -c "select numero, estado, metodo_pago, stripe_session_id, pagada_en from factura order by created_at desc limit 3;"
```
**Debe salir:** la factura con `PAGADA | TARJETA | cs_test_... | <timestamp>`.

## Problemas comunes
| Síntoma | Causa → solución |
|---|---|
| "Pagos online no configurados (falta STRIPE_SECRET_KEY)" | `.env` de MS3 sin la key, o MS3 sin reiniciar tras editarla |
| Botón Pagar: "Cannot query field crearCheckoutFactura" | Gateway viejo → reinícialo |
| "Solo se pueden pagar facturas PENDIENTE" | La factura nació PAGADA: faltó el checkbox en caja |
| `stripe listen` muestra `[400] firma invalida` | `STRIPE_WEBHOOK_SECRET` no coincide (cada `stripe listen` genera uno nuevo) → actualiza el `.env` y reinicia MS3 |
| Pago hecho pero la factura sigue PENDIENTE | La terminal de `stripe listen` estaba cerrada → ábrela y en el dashboard de Stripe reenvía el evento (Developers → Events → Resend) |
| "No se pudo verificar tu registro de paciente (MS1)" | MS1 apagado: el chequeo de propiedad consulta a MS1 → levántalo |
| El teléfono muestra error tras pagar | Falta `adb reverse tcp:4200` (solo estético: el pago YA se procesó por webhook) |
| `mvnw` no descarga stripe-java | Pin de versión: cambia `<version>` en `pom.xml` por la última de Maven Central |

## Para la defensa (resumen de seguridad)
- Secret key y webhook secret **solo en backend**; el cliente recibe únicamente una URL.
- Monto y concepto se arman **desde la BD** de MS3 (el cliente no puede manipular precios).
- Webhook autenticado por **firma** y `marcarPagada` **idempotente** (replays no duplican).
- Propiedad verificada: PACIENTE paga solo lo suyo (JWT → MS1 → pacienteId).
