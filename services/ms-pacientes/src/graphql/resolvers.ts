import { GraphQLScalarType, Kind, GraphQLError } from 'graphql';
import type { PrismaClient } from '@prisma/client';
import type { Actor, Rol } from '@/lib/auth';

type Ctx = { actor: Actor | null; prisma: PrismaClient };

function requireAuth(ctx: Ctx): Actor {
  if (!ctx.actor) throw new GraphQLError('No autenticado', { extensions: { code: 'UNAUTHENTICATED' } });
  return ctx.actor;
}

function requireRole(ctx: Ctx, ...roles: Rol[]): Actor {
  const a = requireAuth(ctx);
  if (!roles.includes(a.rol)) throw new GraphQLError('No autorizado', { extensions: { code: 'FORBIDDEN' } });
  return a;
}

/**
 * Ficha de paciente del actor autenticado. Si aun no esta vinculada por
 * supabaseUid, intenta AUTO-VINCULAR por email: busca una ficha creada en
 * recepcion con el mismo correo y sin uid, y le escribe el uid del JWT.
 * Asi el paciente queda habilitado para auto-agendarse sin tocar la BD.
 */
async function pacienteDelActor(ctx: Ctx, a: Actor) {
  const porUid = await ctx.prisma.paciente.findUnique({ where: { supabaseUid: a.uid } });
  if (porUid) return porUid;
  if (!a.email) return null;
  const porEmail = await ctx.prisma.paciente.findFirst({
    where: { supabaseUid: null, email: { equals: a.email, mode: 'insensitive' } },
  });
  if (!porEmail) return null;
  return ctx.prisma.paciente.update({
    where: { id: porEmail.id },
    data: { supabaseUid: a.uid },
  });
}

const DateTime = new GraphQLScalarType({
  name: 'DateTime',
  description: 'Fecha-hora ISO-8601',
  serialize(v) { return v instanceof Date ? v.toISOString() : v; },
  parseValue(v) { return new Date(v as string); },
  parseLiteral(ast) { return ast.kind === Kind.STRING ? new Date(ast.value) : null; },
});

export const resolvers = {
  DateTime,

  Query: {
    async me(_p: unknown, _a: unknown, ctx: Ctx) {
      const a = requireAuth(ctx);
      // Lazy-provision del directorio local de personal a partir del JWT.
      const rol = await ctx.prisma.rol.findUnique({ where: { nombre: a.rol } });
      return ctx.prisma.usuario.upsert({
        where: { supabaseUid: a.uid },
        update: {},
        create: {
          supabaseUid: a.uid,
          nombre: a.nombre ?? a.email ?? a.uid,
          email: a.email ?? `${a.uid}@sin-email.local`,
          rolId: rol?.id ?? 4,
        },
      });
    },

    miPaciente(_p: unknown, _a: unknown, ctx: Ctx) {
      const a = requireAuth(ctx);
      return pacienteDelActor(ctx, a);
    },

    usuarios(_p: unknown, _a: unknown, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR');
      return ctx.prisma.usuario.findMany({ orderBy: { nombre: 'asc' } });
    },

    pacientes(_p: unknown, args: { q?: string }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO', 'FARMACEUTICO');
      const q = args.q?.trim();
      return ctx.prisma.paciente.findMany({
        where: q
          ? {
              OR: [
                { ci: { contains: q, mode: 'insensitive' } },
                { nombre: { contains: q, mode: 'insensitive' } },
                { apellido: { contains: q, mode: 'insensitive' } },
              ],
            }
          : undefined,
        orderBy: { apellido: 'asc' },
      });
    },

    paciente(_p: unknown, args: { id: string }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO', 'FARMACEUTICO');
      return ctx.prisma.paciente.findUnique({ where: { id: args.id } });
    },

    citas(_p: unknown, _a: unknown, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO');
      return ctx.prisma.cita.findMany({ orderBy: { fechaHora: 'desc' } });
    },

    async misCitas(_p: unknown, _a: unknown, ctx: Ctx) {
      const a = requireRole(ctx, 'PACIENTE', 'ADMINISTRADOR', 'MEDICO');
      const pac = await pacienteDelActor(ctx, a);
      if (!pac) return [];
      return ctx.prisma.cita.findMany({ where: { pacienteId: pac.id }, orderBy: { fechaHora: 'desc' } });
    },

    historiaPorPaciente(_p: unknown, args: { pacienteId: string }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO');
      return ctx.prisma.historiaClinica.findUnique({ where: { pacienteId: args.pacienteId } });
    },
  },

  Mutation: {
    crearPaciente(_p: unknown, args: { input: PacienteData }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO', 'FARMACEUTICO');
      return ctx.prisma.paciente.create({ data: toPacienteData(args.input) });
    },

    actualizarPaciente(_p: unknown, args: { id: string; input: PacienteData }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR', 'MEDICO', 'FARMACEUTICO');
      return ctx.prisma.paciente.update({ where: { id: args.id }, data: toPacienteData(args.input) });
    },

    async crearCita(_p: unknown, args: { input: CitaData }, ctx: Ctx) {
      const a = requireRole(ctx, 'ADMINISTRADOR', 'MEDICO', 'PACIENTE');
      const i = args.input;
      if (a.rol === 'PACIENTE') {
        const pac = await pacienteDelActor(ctx, a);
        if (!pac || pac.id !== i.pacienteId) {
          throw new GraphQLError('Solo puedes agendar tus propias citas', { extensions: { code: 'FORBIDDEN' } });
        }
      }
      return ctx.prisma.cita.create({
        data: {
          pacienteId: i.pacienteId,
          medicoUid: i.medicoUid ?? '',
          especialidad: i.especialidad ?? null,
          fechaHora: i.fechaHora,
          urgencia: i.urgencia ?? null,
          motivo: i.motivo ?? null,
        },
      });
    },

    crearEpisodio(_p: unknown, args: { input: EpisodioData }, ctx: Ctx) {
      const a = requireRole(ctx, 'ADMINISTRADOR', 'MEDICO');
      const i = args.input;
      // Episodio inmutable: solo se crea, nunca se edita ni borra.
      return ctx.prisma.episodio.create({
        data: {
          historiaId: i.historiaId,
          citaId: i.citaId ?? null,
          medicoUid: a.uid,
          motivoConsulta: i.motivoConsulta ?? null,
          evolucion: i.evolucion ?? null,
          diagnosticoTexto: i.diagnosticoTexto ?? null,
        },
      });
    },

    async cambiarRolUsuario(_p: unknown, args: { id: string; rol: Rol }, ctx: Ctx) {
      requireRole(ctx, 'ADMINISTRADOR');
      const rol = await ctx.prisma.rol.findUnique({ where: { nombre: args.rol } });
      if (!rol) throw new GraphQLError('Rol invalido', { extensions: { code: 'BAD_USER_INPUT' } });
      return ctx.prisma.usuario.update({ where: { id: args.id }, data: { rolId: rol.id } });
    },
  },

  Usuario: {
    rol(parent: { rolId: number; rol?: unknown }, _a: unknown, ctx: Ctx) {
      return parent.rol ?? ctx.prisma.rol.findUnique({ where: { id: parent.rolId } });
    },
  },

  Paciente: {
    citas(parent: { id: string }, _a: unknown, ctx: Ctx) {
      return ctx.prisma.cita.findMany({ where: { pacienteId: parent.id }, orderBy: { fechaHora: 'desc' } });
    },
    historia(parent: { id: string }, _a: unknown, ctx: Ctx) {
      return ctx.prisma.historiaClinica.findUnique({ where: { pacienteId: parent.id } });
    },
  },

  Cita: {
    paciente(parent: { pacienteId: string }, _a: unknown, ctx: Ctx) {
      return ctx.prisma.paciente.findUnique({ where: { id: parent.pacienteId } });
    },
  },

  HistoriaClinica: {
    episodios(parent: { id: string }, _a: unknown, ctx: Ctx) {
      return ctx.prisma.episodio.findMany({ where: { historiaId: parent.id }, orderBy: { fecha: 'asc' } });
    },
  },
};

// ---------- helpers de tipado de inputs ----------
interface PacienteData {
  ci: string; nombre: string; apellido: string;
  telefono?: string | null; email?: string | null;
  fechaNacimiento?: Date | null; supabaseUid?: string | null;
}
interface CitaData {
  pacienteId: string; medicoUid?: string | null; especialidad?: string | null;
  fechaHora: Date; urgencia?: string | null; motivo?: string | null;
}
interface EpisodioData {
  historiaId: string; citaId?: string | null;
  motivoConsulta?: string | null; evolucion?: string | null; diagnosticoTexto?: string | null;
}

function toPacienteData(i: PacienteData) {
  return {
    ci: i.ci,
    nombre: i.nombre,
    apellido: i.apellido,
    telefono: i.telefono ?? null,
    email: i.email ?? null,
    fechaNacimiento: i.fechaNacimiento ?? null,
    supabaseUid: i.supabaseUid ?? null,
  };
}
