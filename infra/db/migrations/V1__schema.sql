-- ============================================================================
-- V1__schema.sql — Schema canonico de ms-gestion (Alimbert)
-- ============================================================================
-- Cubre: seguridad/usuarios, referencia minima de pacientes, inventario de
-- farmacia, recetas con enlace blockchain, facturacion.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Trigger generico para columnas updated_at
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================================
-- SEGURIDAD / USUARIOS
-- ===========================================================================

CREATE TABLE rol (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(40)  UNIQUE NOT NULL,
    descripcion VARCHAR(200)
);

CREATE TABLE usuario (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_uid VARCHAR(100) UNIQUE NOT NULL,
    nombre       VARCHAR(150) NOT NULL,
    email        VARCHAR(150) UNIQUE NOT NULL,
    rol_id       INTEGER      NOT NULL REFERENCES rol(id),
    activo       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_usuario_supabase_uid ON usuario(supabase_uid);
CREATE INDEX idx_usuario_rol          ON usuario(rol_id);

CREATE TRIGGER trg_usuario_updated_at
    BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ===========================================================================
-- PACIENTE (referencia minima -- Javier sera dueno canonico)
-- ===========================================================================

CREATE TABLE paciente (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_uid     VARCHAR(100) UNIQUE,
    ci               VARCHAR(20)  UNIQUE NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    telefono         VARCHAR(30),
    email            VARCHAR(150),
    fecha_nacimiento DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_paciente_ci           ON paciente(ci);
CREATE INDEX idx_paciente_supabase_uid ON paciente(supabase_uid);

CREATE TRIGGER trg_paciente_updated_at
    BEFORE UPDATE ON paciente
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ===========================================================================
-- INVENTARIO DE FARMACIA
-- ===========================================================================

CREATE TABLE categoria (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(80) UNIQUE NOT NULL,
    descripcion VARCHAR(200)
);

CREATE TABLE proveedor (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre     VARCHAR(150) NOT NULL,
    nit        VARCHAR(30)  UNIQUE,
    telefono   VARCHAR(30),
    email      VARCHAR(150),
    direccion  VARCHAR(250),
    activo     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_proveedor_updated_at
    BEFORE UPDATE ON proveedor
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE medicamento (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre           VARCHAR(150) NOT NULL,
    descripcion      TEXT,
    categoria_id     INTEGER REFERENCES categoria(id),
    precio_venta     NUMERIC(12,2) NOT NULL CHECK (precio_venta >= 0),
    requiere_receta  BOOLEAN NOT NULL DEFAULT FALSE,
    controlado       BOOLEAN NOT NULL DEFAULT FALSE,  -- dispara blockchain al emitir receta
    stock_minimo     INTEGER NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    activo           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_medicamento_nombre    ON medicamento(nombre);
CREATE INDEX idx_medicamento_categoria ON medicamento(categoria_id);

CREATE TRIGGER trg_medicamento_updated_at
    BEFORE UPDATE ON medicamento
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE lote (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicamento_id    UUID NOT NULL REFERENCES medicamento(id),
    proveedor_id      UUID REFERENCES proveedor(id),
    codigo_lote       VARCHAR(80) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    cantidad_inicial  INTEGER NOT NULL CHECK (cantidad_inicial >= 0),
    cantidad_actual   INTEGER NOT NULL CHECK (cantidad_actual >= 0),
    precio_compra     NUMERIC(12,2) NOT NULL CHECK (precio_compra >= 0),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (medicamento_id, codigo_lote)
);

CREATE INDEX idx_lote_medicamento  ON lote(medicamento_id);
CREATE INDEX idx_lote_vencimiento  ON lote(fecha_vencimiento);

CREATE TRIGGER trg_lote_updated_at
    BEFORE UPDATE ON lote
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TYPE tipo_movimiento_enum AS ENUM ('ENTRADA', 'SALIDA', 'AJUSTE');

CREATE TABLE movimiento_inventario (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lote_id    UUID NOT NULL REFERENCES lote(id),
    tipo       tipo_movimiento_enum NOT NULL,
    cantidad   INTEGER NOT NULL,
    motivo     VARCHAR(250),
    usuario_id UUID REFERENCES usuario(id),
    fecha      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_movimiento_lote  ON movimiento_inventario(lote_id);
CREATE INDEX idx_movimiento_fecha ON movimiento_inventario(fecha);

-- ===========================================================================
-- RECETA MEDICA (con enlace a blockchain)
-- ===========================================================================

CREATE TYPE estado_receta_enum AS ENUM ('EMITIDA', 'DISPENSADA', 'ANULADA');

CREATE TABLE receta (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    paciente_id     UUID NOT NULL REFERENCES paciente(id),
    medico_nombre   VARCHAR(150) NOT NULL,
    medico_uid      VARCHAR(100) NOT NULL,   -- supabase_uid del medico
    diagnostico     TEXT,
    fecha_emision   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    controlado      BOOLEAN NOT NULL DEFAULT FALSE,
    hash_documento  VARCHAR(80),             -- SHA-256 hex del documento canonico
    blockchain_tx   VARCHAR(100),            -- tx hash en Polygon
    blockchain_id   BIGINT,                  -- id del registro en el contrato
    estado          estado_receta_enum NOT NULL DEFAULT 'EMITIDA',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_receta_paciente   ON receta(paciente_id);
CREATE INDEX idx_receta_medico_uid ON receta(medico_uid);
CREATE INDEX idx_receta_fecha      ON receta(fecha_emision);
CREATE INDEX idx_receta_tx         ON receta(blockchain_tx);

CREATE TRIGGER trg_receta_updated_at
    BEFORE UPDATE ON receta
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE detalle_receta (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receta_id       UUID NOT NULL REFERENCES receta(id) ON DELETE CASCADE,
    medicamento_id  UUID NOT NULL REFERENCES medicamento(id),
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    posologia       VARCHAR(250),
    UNIQUE (receta_id, medicamento_id)
);

CREATE INDEX idx_detalle_receta_receta ON detalle_receta(receta_id);

-- ===========================================================================
-- FACTURACION / CAJA
-- ===========================================================================

CREATE TYPE metodo_pago_enum   AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'QR');
CREATE TYPE estado_factura_enum AS ENUM ('PENDIENTE', 'PAGADA', 'ANULADA');

CREATE TABLE factura (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero       VARCHAR(30) UNIQUE NOT NULL,
    paciente_id  UUID REFERENCES paciente(id),
    usuario_id   UUID NOT NULL REFERENCES usuario(id),   -- cajero
    fecha        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    subtotal     NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    descuento    NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
    total        NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    metodo_pago  metodo_pago_enum NOT NULL,
    estado       estado_factura_enum NOT NULL DEFAULT 'PAGADA',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_factura_paciente ON factura(paciente_id);
CREATE INDEX idx_factura_fecha    ON factura(fecha);
CREATE INDEX idx_factura_usuario  ON factura(usuario_id);

CREATE TRIGGER trg_factura_updated_at
    BEFORE UPDATE ON factura
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE detalle_factura (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    factura_id      UUID NOT NULL REFERENCES factura(id) ON DELETE CASCADE,
    medicamento_id  UUID NOT NULL REFERENCES medicamento(id),
    lote_id         UUID NOT NULL REFERENCES lote(id),
    receta_id       UUID REFERENCES receta(id),  -- requerido si medicamento.requiere_receta = true
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0)
);

CREATE INDEX idx_detalle_factura_factura     ON detalle_factura(factura_id);
CREATE INDEX idx_detalle_factura_medicamento ON detalle_factura(medicamento_id);
