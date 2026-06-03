-- ============================================================================
-- V3__seed_roles.sql — Categorias base de medicamentos
-- ============================================================================
-- NOTA (refactor microservicios): la tabla `rol` ya no existe en MS3. Los roles
-- viven en MS1 / Supabase (claim app_metadata.role). Aqui solo quedan las
-- categorias de medicamentos, que son catalogo local de farmacia.
-- ============================================================================

INSERT INTO categoria (nombre, descripcion) VALUES
    ('Analgesicos',       'Para alivio del dolor'),
    ('Antibioticos',      'Combate infecciones bacterianas'),
    ('Antiinflamatorios', 'Reduce la inflamacion'),
    ('Antihistaminicos',  'Para alergias'),
    ('Antihipertensivos', 'Control de presion arterial'),
    ('Cardiologicos',     'Salud cardiovascular'),
    ('Controlados',       'Sustancias controladas (requieren receta inmutable)'),
    ('Vitaminas',         'Suplementos vitaminicos y minerales')
ON CONFLICT (nombre) DO NOTHING;
