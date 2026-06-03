// Seed de MS1 (ms-pacientes). UUIDs alineados con los seeds de MS3 (ms-gestion)
// para que receta.paciente_id / factura.usuario_id de MS3 resuelvan contra MS1.
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const roles = [
  { id: 1, nombre: 'ADMINISTRADOR', descripcion: 'Acceso total al sistema, gestion de usuarios y BI' },
  { id: 2, nombre: 'MEDICO', descripcion: 'Emite recetas, dispara blockchain, ve historia clinica' },
  { id: 3, nombre: 'FARMACEUTICO', descripcion: 'Caja, inventario, dispensacion, verificar recetas' },
  { id: 4, nombre: 'PACIENTE', descripcion: 'Consulta sus facturas y recetas' },
];

const usuarios = [
  { id: '11111111-1111-1111-1111-111111111111', supabaseUid: 'seed-admin-uid', nombre: 'Admin Demo', email: 'admin@clinica.com', rolId: 1 },
  { id: '22222222-2222-2222-2222-222222222222', supabaseUid: 'seed-medico-uid', nombre: 'Dr. Juan Perez', email: 'medico@clinica.com', rolId: 2 },
  { id: '33333333-3333-3333-3333-333333333333', supabaseUid: 'seed-farma-uid', nombre: 'Maria Gonzalez', email: 'farma@clinica.com', rolId: 3 },
  { id: '44444444-4444-4444-4444-444444444444', supabaseUid: 'seed-paciente-uid', nombre: 'Carlos Rodriguez', email: 'paciente@clinica.com', rolId: 4 },
];

const pacientes = [
  { id: 'aaaa1111-aaaa-1111-aaaa-111111111111', supabaseUid: 'seed-paciente-uid', ci: '1234567', nombre: 'Carlos', apellido: 'Rodriguez', telefono: '70011223', email: 'paciente@clinica.com', fechaNacimiento: new Date('1985-04-12') },
  { id: 'aaaa2222-aaaa-2222-aaaa-222222222222', ci: '7654321', nombre: 'Ana', apellido: 'Mamani', telefono: '70022334', fechaNacimiento: new Date('1990-09-23') },
  { id: 'aaaa3333-aaaa-3333-aaaa-333333333333', ci: '9876543', nombre: 'Pedro', apellido: 'Choque', telefono: '70033445', fechaNacimiento: new Date('1978-01-07') },
  { id: 'aaaa4444-aaaa-4444-aaaa-444444444444', ci: '1122334', nombre: 'Maria', apellido: 'Lopez', telefono: '70044556', email: 'maria.lopez@example.com', fechaNacimiento: new Date('1985-03-15') },
  { id: 'aaaa5555-aaaa-5555-aaaa-555555555555', ci: '2233445', nombre: 'Jose', apellido: 'Vargas', telefono: '70055667', email: 'jose.vargas@example.com', fechaNacimiento: new Date('1978-07-20') },
  { id: 'aaaa6666-aaaa-6666-aaaa-666666666666', ci: '3344556', nombre: 'Lucia', apellido: 'Mamani', telefono: '70066778', email: 'lucia.mamani@example.com', fechaNacimiento: new Date('1992-11-08') },
  { id: 'aaaa7777-aaaa-7777-aaaa-777777777777', ci: '4455667', nombre: 'Roberto', apellido: 'Quispe', telefono: '70077889', email: 'roberto.quispe@example.com', fechaNacimiento: new Date('1980-05-30') },
  { id: 'aaaa8888-aaaa-8888-aaaa-888888888888', ci: '5566778', nombre: 'Sandra', apellido: 'Flores', telefono: '70088990', email: 'sandra.flores@example.com', fechaNacimiento: new Date('1995-09-22') },
];

const CARLOS = 'aaaa1111-aaaa-1111-aaaa-111111111111';
const HISTORIA = 'b0000001-0000-4000-8000-000000000001';
const CITA1 = 'c0000001-0000-4000-8000-000000000001';
const CITA2 = 'c0000002-0000-4000-8000-000000000002';
const EPISODIO = 'e0000001-0000-4000-8000-000000000001';

async function main() {
  for (const r of roles) {
    await prisma.rol.upsert({ where: { id: r.id }, update: { nombre: r.nombre, descripcion: r.descripcion }, create: r });
  }
  for (const u of usuarios) {
    await prisma.usuario.upsert({ where: { id: u.id }, update: {}, create: u });
  }
  for (const p of pacientes) {
    await prisma.paciente.upsert({ where: { id: p.id }, update: {}, create: p });
  }

  // Historia clinica + citas + episodio demo para Carlos
  await prisma.historiaClinica.upsert({
    where: { pacienteId: CARLOS },
    update: {},
    create: { id: HISTORIA, pacienteId: CARLOS, estado: 'ABIERTA' },
  });
  await prisma.cita.upsert({
    where: { id: CITA1 },
    update: {},
    create: { id: CITA1, pacienteId: CARLOS, medicoUid: 'seed-medico-uid', especialidad: 'Medicina General', fechaHora: new Date('2026-06-10T15:00:00Z'), estado: 'ATENDIDA', motivo: 'Dolor postoperatorio' },
  });
  await prisma.cita.upsert({
    where: { id: CITA2 },
    update: {},
    create: { id: CITA2, pacienteId: CARLOS, medicoUid: 'seed-medico-uid', especialidad: 'Traumatologia', fechaHora: new Date('2026-06-20T10:30:00Z'), estado: 'AGENDADA', urgencia: 'MEDIA', motivo: 'Control' },
  });
  await prisma.episodio.upsert({
    where: { id: EPISODIO },
    update: {},
    create: { id: EPISODIO, historiaId: HISTORIA, citaId: CITA1, medicoUid: 'seed-medico-uid', motivoConsulta: 'Dolor postoperatorio agudo', evolucion: 'Paciente estable, dolor controlado con analgesia', diagnosticoTexto: 'Dolor postquirurgico en manejo' },
  });

  console.log('Seed MS1 completado: %d roles, %d usuarios, %d pacientes, 1 historia, 2 citas, 1 episodio', roles.length, usuarios.length, pacientes.length);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
