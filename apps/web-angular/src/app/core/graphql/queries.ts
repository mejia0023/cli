import { gql } from 'apollo-angular';

// === Health ===
export const HEALTH = gql`query { health }`;

// === Medicamentos ===
export const LIST_MEDICAMENTOS = gql`
  query Medicamentos($q: String, $activo: Boolean) {
    medicamentos(q: $q, activo: $activo) {
      id nombre precioVenta requiereReceta controlado stockMinimo activo
      categoria { id nombre }
    }
  }
`;

export const CREATE_MEDICAMENTO = gql`
  mutation CrearMedicamento($input: MedicamentoInput!) {
    crearMedicamento(input: $input) {
      id nombre precioVenta requiereReceta controlado stockMinimo
    }
  }
`;

// === Lotes ===
export const LIST_LOTES = gql`
  query Lotes($medicamentoId: UUID!) {
    lotesByMedicamento(medicamentoId: $medicamentoId) {
      id codigoLote fechaVencimiento cantidadActual precioCompra
      proveedor { id nombre }
    }
  }
`;

export const REGISTRAR_LOTE = gql`
  mutation RegistrarLote($input: LoteInput!) {
    registrarEntradaLote(input: $input) {
      id codigoLote cantidadActual fechaVencimiento
    }
  }
`;

// === Pacientes ===
export const LIST_PACIENTES = gql`
  query Pacientes($q: String) {
    pacientes(q: $q) {
      id ci nombre apellido telefono email fechaNacimiento
    }
  }
`;

export const CREATE_PACIENTE = gql`
  mutation CrearPaciente($input: PacienteInput!) {
    crearPaciente(input: $input) { id ci nombre apellido }
  }
`;

// === Facturas ===
export const CREATE_FACTURA = gql`
  mutation CrearFactura($input: FacturaInput!) {
    crearFactura(input: $input) {
      id numero total fecha metodoPago estado
    }
  }
`;

export const LIST_FACTURAS = gql`
  query Facturas {
    facturas {
      id numero fecha total metodoPago estado
      paciente { id nombre apellido }
    }
  }
`;

// === Recetas ===
export const EMITIR_RECETA = gql`
  mutation EmitirReceta($input: RecetaInput!) {
    emitirReceta(input: $input) {
      id fechaEmision controlado blockchainTx estado
      detalles { medicamento { nombre } cantidad }
    }
  }
`;

export const MIS_RECETAS = gql`
  query MisRecetas {
    misRecetas {
      id fechaEmision controlado blockchainTx hashDocumento estado
      paciente { id nombre apellido }
      detalles { medicamento { nombre } cantidad posologia }
    }
  }
`;

export const VERIFICAR_RECETA = gql`
  query VerificarReceta($id: UUID!) {
    verificarReceta(id: $id) {
      exists id timestamp blockNumber razon error
    }
  }
`;

export const MIS_RECETAS_PACIENTE = gql`
  query MisRecetasPaciente {
    misRecetasPaciente {
      id fechaEmision controlado blockchainTx hashDocumento estado
      medicoNombre diagnostico
      detalles { medicamento { nombre } cantidad posologia }
    }
  }
`;

// === Categorias / Proveedores ===
export const LIST_CATEGORIAS = gql`query { categorias { id nombre } }`;

export const LIST_PROVEEDORES = gql`
  query Proveedores {
    proveedores { id nombre nit telefono email activo }
  }
`;

// === Usuarios ===
export const LIST_USUARIOS = gql`
  query Usuarios {
    usuarios { id nombre email rol activo }
  }
`;

export const ME = gql`
  query Me {
    me { id nombre email rol }
  }
`;

// === BI ===
export const BI_VENTAS_DIARIAS = gql`
  query BiVentasDiarias($desde: Date, $hasta: Date) {
    biVentasDiarias(desde: $desde, hasta: $hasta) {
      dia numFacturas totalVendido ticketPromedio
    }
  }
`;

export const BI_TOP_MEDICAMENTOS = gql`
  query BiTop($limit: Int) {
    biTopMedicamentos(limit: $limit) {
      medicamento unidadesVendidas montoTotal
    }
  }
`;

export const BI_INVENTARIO_CRITICO = gql`
  query BiInventario {
    biInventarioCritico {
      medicamentoId medicamento stockMinimo stockActual nivel
    }
  }
`;

export const BI_RECETAS_BLOCKCHAIN = gql`
  query BiRecetasBC($desde: Date, $hasta: Date) {
    biRecetasBlockchain(desde: $desde, hasta: $hasta) {
      mes totalRecetas registradasEnBlockchain controladas dispensadas
    }
  }
`;
