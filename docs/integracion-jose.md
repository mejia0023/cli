# Integración con la parte de José Eduardo

José es dueño de:
- Backend de diagnósticos (Python FastAPI / GCP).
- Modelos de IA para análisis de imágenes médicas (Vertex AI).
- Almacenamiento de historiales y PDFs (Amazon S3 + DynamoDB).
- Módulo web Angular para uso de médicos.

## Contrato esperado

### Lo que ms-gestion (Alimbert) expone para José

- Mutación GraphQL `emitirReceta(input: RecetaInput!): Receta!` — disponible para usuarios con rol MEDICO. El Angular de médicos de José la consume cuando un doctor emite receta tras un diagnóstico.
- Query `verificarReceta(id: UUID!): VerificacionReceta!` — para mostrar al médico el estado en blockchain.
- Query `medicamentos(...)` y `medicamento(id)` — para autocompletar al armar receta.

### Lo que José proveerá

| Recurso | Cómo lo consumirá Alimbert |
|---|---|
| Backend diagnósticos FastAPI | ms-gestion **no** consume diagnósticos directamente. Solo los médicos los ven en su Angular separado. Si en el futuro se necesita ligar `receta` a un `diagnostico_id`, agregar columna a `receta` (migración Vn). |
| Historia clínica en DynamoDB | Mismo principio: ms-gestion no lee. La app móvil de Javier accede vía gateway. |
| Vertex AI | Aislado en el dominio de José. |

## Identificador universal

`supabase_uid` también es la única identidad para José.
- `medico_uid` en `receta` es el `supabase_uid` del médico.
- Si José necesita asociar un diagnóstico a un paciente, usa `paciente.supabase_uid`.

## Reutilización del GraphQL de ms-gestion

El Angular de médicos de José es **otra app independiente** del de Alimbert. Ambos:
- Usan Supabase Auth con el mismo proyecto.
- Consumen el GraphQL de ms-gestion (directamente en MVP, o vía Gateway de Javier después).
- Comparten el SDL en `packages/contracts/schema.graphql` para tipar las queries con codegen.

## Eventos potenciales

Si José requiere reaccionar a recetas emitidas (para vincular a un diagnóstico):
- Webhook desde ms-gestion al endpoint que él indique cuando esté listo.
- Payload: `{ recetaId, pacienteId, medicoUid, blockchainTx, items }`.

## Lo que **no** debe hacer

- **No replicar** datos de medicamentos en su BD. Si los necesita, consulta `query medicamentos` de ms-gestion.
- **No** modificar tablas de ms-gestion. Si requiere un campo nuevo, abrir PR/issue para que Alimbert agregue la migración.
