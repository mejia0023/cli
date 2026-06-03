import { createYoga } from 'graphql-yoga';
import { schema } from '@/graphql/schema';
import { actorFromRequest } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export const dynamic = 'force-dynamic';

const { handleRequest } = createYoga({
  schema,
  graphqlEndpoint: '/api/graphql',
  // Next.js usa la Fetch API estandar; le pasamos su Response.
  fetchAPI: { Response },
  cors: { origin: '*', methods: ['GET', 'POST', 'OPTIONS'] },
  context: async ({ request }) => ({
    actor: await actorFromRequest(request),
    prisma,
  }),
});

// Envolvemos en handlers de 1 argumento: el 2do arg de yoga (server context) no
// coincide con el RouteContext que Next.js 15 valida por tipos. La firma (request)
// satisface el type-check de rutas; el contexto GraphQL se arma en `context` arriba.
export async function GET(request: Request) {
  return handleRequest(request, {});
}
export async function POST(request: Request) {
  return handleRequest(request, {});
}
export async function OPTIONS(request: Request) {
  return handleRequest(request, {});
}
