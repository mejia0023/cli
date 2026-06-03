import { prisma } from '@/lib/prisma';

export const dynamic = 'force-dynamic';

/**
 * Endpoint interno consumido por el PacienteClient de MS3 (ms-gestion):
 * resuelve supabase_uid -> pacienteId para "mis recetas" / "mis facturas".
 *   GET /api/internal/pacientes/by-uid/{supabaseUid}  ->  { "id": "<uuid>" } | 404
 */
export async function GET(_req: Request, { params }: { params: Promise<{ uid: string }> }) {
  const { uid } = await params;
  const paciente = await prisma.paciente.findUnique({
    where: { supabaseUid: uid },
    select: { id: true },
  });
  if (!paciente) {
    return Response.json({ error: 'paciente no encontrado' }, { status: 404 });
  }
  return Response.json({ id: paciente.id });
}
