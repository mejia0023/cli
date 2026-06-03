export const typeDefs = /* GraphQL */ `
  scalar DateTime

  enum RolNombre { ADMINISTRADOR MEDICO FARMACEUTICO PACIENTE }
  enum EstadoCita { AGENDADA ATENDIDA CANCELADA }
  enum EstadoHistoria { ABIERTA CERRADA }

  type Rol {
    id: Int!
    nombre: RolNombre!
    descripcion: String
  }

  type Usuario {
    id: ID!
    supabaseUid: String!
    nombre: String!
    email: String!
    rol: Rol!
    activo: Boolean!
  }

  type Paciente {
    id: ID!
    supabaseUid: String
    ci: String!
    nombre: String!
    apellido: String!
    telefono: String
    email: String
    fechaNacimiento: DateTime
    citas: [Cita!]!
    historia: HistoriaClinica
  }

  type Cita {
    id: ID!
    pacienteId: ID!
    paciente: Paciente
    medicoUid: String!
    especialidad: String
    fechaHora: DateTime!
    urgencia: String
    estado: EstadoCita!
    motivo: String
    createdAt: DateTime
  }

  type HistoriaClinica {
    id: ID!
    pacienteId: ID!
    fechaApertura: DateTime!
    estado: EstadoHistoria!
    episodios: [Episodio!]!
  }

  type Episodio {
    id: ID!
    historiaId: ID!
    citaId: ID
    medicoUid: String!
    fecha: DateTime!
    motivoConsulta: String
    evolucion: String
    diagnosticoTexto: String
  }

  input PacienteInput {
    ci: String!
    nombre: String!
    apellido: String!
    telefono: String
    email: String
    fechaNacimiento: DateTime
    supabaseUid: String
  }

  input CitaInput {
    pacienteId: ID!
    medicoUid: String
    especialidad: String
    fechaHora: DateTime!
    urgencia: String
    motivo: String
  }

  input EpisodioInput {
    historiaId: ID!
    citaId: ID
    motivoConsulta: String
    evolucion: String
    diagnosticoTexto: String
  }

  type Query {
    me: Usuario
    miPaciente: Paciente
    usuarios: [Usuario!]!
    pacientes(q: String): [Paciente!]!
    paciente(id: ID!): Paciente
    citas: [Cita!]!
    misCitas: [Cita!]!
    historiaPorPaciente(pacienteId: ID!): HistoriaClinica
  }

  type Mutation {
    crearPaciente(input: PacienteInput!): Paciente!
    actualizarPaciente(id: ID!, input: PacienteInput!): Paciente!
    crearCita(input: CitaInput!): Cita!
    crearEpisodio(input: EpisodioInput!): Episodio!
    cambiarRolUsuario(id: ID!, rol: RolNombre!): Usuario!
  }
`;
