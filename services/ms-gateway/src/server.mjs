// =====================================================
//  ms-gateway — Gateway GraphQL por SCHEMA STITCHING
//  Une MS1 (ms-pacientes, :3000) y MS3 (ms-gestion, :8080) en un solo
//  endpoint :4000/graphql para el frontend. Reenvia el JWT a ambos subgrafos
//  (cada backend valida el token y aplica sus reglas por rol).
//
//  Ademas "cose" la frontera cruzada: agrega Receta.paciente y Factura.paciente
//  resolviendo el pacienteId (que vive en MS3 como UUID) contra el paciente
//  canonico de MS1. Asi el frontend puede pedir receta { paciente { nombre } }
//  aunque sean servicios distintos.
// =====================================================
import { createServer } from 'node:http';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, isAbsolute } from 'node:path';
import { buildSchema, OperationTypeNode } from 'graphql';
import { createYoga } from 'graphql-yoga';
import { stitchSchemas } from '@graphql-tools/stitch';
import { schemaFromExecutor } from '@graphql-tools/wrap';
import { buildHTTPExecutor } from '@graphql-tools/executor-http';
import { delegateToSchema } from '@graphql-tools/delegate';

const __dirname = dirname(fileURLToPath(import.meta.url));
const gatewayRoot = join(__dirname, '..');

try { process.loadEnvFile(join(gatewayRoot, '.env')); } catch { /* sin .env: defaults */ }

const MS1_URL = process.env.MS1_URL || 'http://localhost:3000/api/graphql';
const MS3_URL = process.env.MS3_URL || 'http://localhost:8080/graphql';
const PORT = Number(process.env.PORT || 4000);

const ms3SdlRel = process.env.MS3_SDL_DIR || '../ms-gestion/src/main/resources/graphql';
const MS3_SDL_DIR = isAbsolute(ms3SdlRel) ? ms3SdlRel : join(gatewayRoot, ms3SdlRel);

function makeExecutor(endpoint) {
  return buildHTTPExecutor({
    endpoint,
    headers: (executorRequest) => {
      const auth = executorRequest?.context?.authorization;
      return auth ? { authorization: auth } : {};
    },
  });
}

async function introspectWithRetry(executor, name, attempts = 15, delayMs = 2000) {
  let lastErr;
  for (let i = 1; i <= attempts; i++) {
    try {
      return await schemaFromExecutor(executor);
    } catch (e) {
      lastErr = e;
      console.warn(`[gateway] introspeccion de ${name} fallo (intento ${i}/${attempts}): ${e.message}`);
      if (i < attempts) await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw lastErr;
}

function loadMs3Sdl() {
  const files = readdirSync(MS3_SDL_DIR).filter((f) => f.endsWith('.graphqls'));
  if (files.length === 0) throw new Error(`No se encontraron .graphqls en ${MS3_SDL_DIR}`);
  return files.map((f) => readFileSync(join(MS3_SDL_DIR, f), 'utf8')).join('\n\n');
}

async function buildGateway() {
  const ms1Executor = makeExecutor(MS1_URL);
  const ms3Executor = makeExecutor(MS3_URL);

  console.log(`[gateway] introspeccionando MS1 en ${MS1_URL} ...`);
  const ms1Schema = await introspectWithRetry(ms1Executor, 'MS1');

  console.log(`[gateway] cargando SDL de MS3 desde ${MS3_SDL_DIR} ...`);
  const ms3Schema = buildSchema(loadMs3Sdl());

  const ms1Subschema = { schema: ms1Schema, executor: ms1Executor };
  const ms3Subschema = { schema: ms3Schema, executor: ms3Executor };

  // Resuelve el campo cross-service paciente: usa el pacienteId (MS3) para
  // consultar paciente(id) en MS1, reenviando el JWT (context) y la sub-seleccion (info).
  const resolvePacienteDesdeMs1 = (parent, _args, context, info) => {
    if (!parent || !parent.pacienteId) return null;
    return delegateToSchema({
      schema: ms1Subschema,
      operation: OperationTypeNode.QUERY,
      fieldName: 'paciente',
      args: { id: parent.pacienteId },
      context,
      info,
    });
  };

  return stitchSchemas({
    subschemas: [ms1Subschema, ms3Subschema],
    typeDefs: `
      extend type Receta { paciente: Paciente }
      extend type Factura { paciente: Paciente }
    `,
    resolvers: {
      Receta: { paciente: { selectionSet: '{ pacienteId }', resolve: resolvePacienteDesdeMs1 } },
      Factura: { paciente: { selectionSet: '{ pacienteId }', resolve: resolvePacienteDesdeMs1 } },
    },
  });
}

const schema = await buildGateway();

const yoga = createYoga({
  schema,
  graphqlEndpoint: '/graphql',
  fetchAPI: { Response },
  cors: { origin: '*', methods: ['GET', 'POST', 'OPTIONS'] },
  // No enmascarar errores: que el error real de cada subgrafo (MS1/MS3) y de
  // los resolvers cross-service se propague COMPLETO al cliente (mensaje +
  // originalError + stacktrace en extensions) en lugar de "Unexpected error.".
  maskedErrors: false,
  context: ({ request }) => ({ authorization: request.headers.get('authorization') || '' }),
});

createServer(yoga).listen(PORT, () => {
  console.log(`[gateway] GraphQL unificado en http://localhost:${PORT}/graphql`);
  console.log(`[gateway]   MS1 (pacientes/citas/historia) -> ${MS1_URL}`);
  console.log(`[gateway]   MS3 (farmacia/recetas/facturacion) -> ${MS3_URL}`);
});
