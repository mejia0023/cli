# Integración con la parte de Javier

Javier es dueño de:
- Backend pacientes y citas (NestJS / AWS).
- App móvil React Native (cámara, GPS, biometría, micrófono).
- Automatización WhatsApp con N8N.
- **API Gateway GraphQL** central (federará los subgrafos).

## Contrato esperado

### Lo que ms-gestion (Alimbert) expone para Javier

- **GraphQL subgrafo** en `https://ms-gestion-clinica.azurewebsites.net/graphql`.
- SDL exportable en `packages/contracts/schema.graphql` para que el Gateway lo consuma.
- Tipos con candidatos a `@key` para federación futura: `Paciente`, `Receta`, `Factura`. Comentados en el SDL con `# TODO @key(fields: "id")`.

### Lo que Javier proveerá

| Recurso | Cómo lo consumirá Alimbert |
|---|---|
| Backend pacientes canónicos (NestJS) | Cuando esté listo, ms-gestion dejará de escribir tabla `paciente` y solo guardará `paciente_id` como FK lógica. Mientras tanto, `paciente` se mantiene como referencia mínima local. |
| API Gateway GraphQL | El Angular eventualmente apuntará al gateway en vez de a ms-gestion directo. CORS de ms-gestion debe permitir el dominio del gateway (via `CORS_ORIGINS` env var). |
| App móvil RN | Consume el GraphQL del gateway (que federa ms-gestion). El paciente usa la app para consultar `misFacturas` y `misRecetas` — ambas operaciones ya están en ms-gestion. |
| N8N WhatsApp | Cuando se crea una factura o se emite una receta, Javier suscribirá un webhook. Ver "Eventos" abajo. |

## Eventos que ms-gestion publicará (futuro)

Si Javier requiere reactividad, ms-gestion expondrá un endpoint webhook configurable por env:

| Evento | Trigger | Payload sugerido |
|---|---|---|
| `factura.creada` | tras commit de `crearFactura` | `{ facturaId, pacienteId, total, fecha }` |
| `factura.anulada` | tras `anularFactura` | `{ facturaId, motivo, fecha }` |
| `receta.emitida` | tras commit de `emitirReceta` | `{ recetaId, pacienteId, medicoUid, controlado, blockchainTx }` |
| `inventario.critico` | job @Scheduled diario | `[{ medicamentoId, nombre, stockActual, stockMinimo }]` |

Implementación pendiente — abrir cuando Javier confirme su endpoint N8N.

## Identificador universal

`supabase_uid` (UUID) es la única identidad que cruza los 3 servicios.

- En ms-gestion: `usuario.supabase_uid` y `receta.medico_uid`.
- En el servicio de Javier: cada paciente tendrá su `supabase_uid`.
- Cuando se cruzan datos, se hace por UID, NO por id local de tabla.

## Federación GraphQL — pasos cuando Javier esté listo

1. Javier instala Apollo Federation (`@apollo/gateway`) en su NestJS.
2. Configura ms-gestion como subgrafo: `{ name: 'gestion', url: 'https://ms-gestion-clinica.azurewebsites.net/graphql' }`.
3. Alimbert agrega dependencia `graphql-java-federation` en Spring y descomenta las directivas `@key` en el SDL.
4. Angular cambia `environment.graphqlUrl` al endpoint del gateway.
5. CORS de ms-gestion se restringe al dominio del gateway (env `CORS_ORIGINS`).
