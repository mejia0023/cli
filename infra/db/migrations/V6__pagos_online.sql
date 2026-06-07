-- V6: pagos online con Stripe Checkout.
-- Los enums estado_factura_enum (PENDIENTE) y metodo_pago_enum (TARJETA) ya
-- existen desde V1; solo agregamos trazabilidad del pago en la factura.

ALTER TABLE factura
    ADD COLUMN IF NOT EXISTS stripe_session_id VARCHAR(255),
    ADD COLUMN IF NOT EXISTS pagada_en TIMESTAMPTZ;

COMMENT ON COLUMN factura.stripe_session_id IS 'ID de la Checkout Session de Stripe (cs_test_... / cs_live_...)';
COMMENT ON COLUMN factura.pagada_en IS 'Momento en que el webhook de Stripe confirmo el pago';

-- Busquedas del webhook / auditoria
CREATE INDEX IF NOT EXISTS idx_factura_stripe_session ON factura (stripe_session_id);
