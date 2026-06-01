import { gql } from '@apollo/client';

export const HEALTH = gql`query { health }`;

export const MIS_RECETAS_PACIENTE = gql`
  query MisRecetasPaciente {
    misRecetasPaciente {
      id fechaEmision controlado blockchainTx hashDocumento estado
      medicoNombre diagnostico
      detalles { medicamento { nombre } cantidad posologia }
    }
  }
`;

export const MIS_RECETAS_MEDICO = gql`
  query MisRecetasMedico {
    misRecetas {
      id fechaEmision controlado blockchainTx estado
      paciente { id nombre apellido }
      detalles { medicamento { nombre } cantidad }
    }
  }
`;

export const MIS_FACTURAS_PACIENTE = gql`
  query MisFacturas {
    misFacturas {
      id numero fecha total metodoPago estado
      detalles { medicamento { nombre } cantidad subtotal }
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

export const LIST_MEDICAMENTOS = gql`
  query Medicamentos($q: String) {
    medicamentos(q: $q, activo: true) {
      id nombre precioVenta controlado requiereReceta
    }
  }
`;
