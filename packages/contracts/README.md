# packages/contracts

Esquemas compartidos entre servicios del monorepo.

## Contenido

- `schema.graphql` — SDL consolidado de ms-gestion, exportado para que:
  - El **API Gateway de Javier** lo consuma como subgrafo (Apollo Federation / GraphQL Mesh).
  - El **Angular de médicos de José** lo use con `graphql-codegen` para tipar sus queries.
  - El propio **Angular de Alimbert** lo use con codegen si se decide.

## Cómo se actualiza

Desde `services/ms-gestion/`:

```powershell
# Opción A — Spring corriendo, dump del schema introspectado:
curl http://localhost:8080/graphql -H "Content-Type: application/json" `
  -d '{"query":"{ __schema { types { name } } }"}' > _introspection.json

# Opción B — concatenar manualmente los .graphqls del classpath
Get-Content src\main\resources\graphql\*.graphqls | Out-File ..\..\packages\contracts\schema.graphql -Encoding UTF8
```

Se sugiere automatizar con un script `npm run export-schema` en `apps/web-angular/` que llame al endpoint introspectivo y lo serialice a SDL.

## Federación futura

Cuando Javier configure el gateway con Apollo Federation, descomentar las directivas `@key` en los tipos del SDL (anotadas con `# TODO @key(fields: "id")`).
