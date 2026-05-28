-- ============================================================================
-- V3__seed_roles.sql — Roles del sistema + categorias base
-- ============================================================================

INSERT INTO rol (id, nombre, descripcion) VALUES
    (1, 'ADMINISTRADOR', 'Acceso total al sistema, gestion de usuarios y BI'),
    (2, 'MEDICO',        'Emite recetas, dispara blockchain, ve historia clinica'),
    (3, 'FARMACEUTICO',  'Caja, inventario, dispensacion, verificar recetas'),
    (4, 'PACIENTE',      'Consulta sus facturas y recetas')
ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion;

-- Reset de la secuencia (porque insertamos IDs explicitos)
SELECT setval('rol_id_seq', (SELECT MAX(id) FROM rol));

-- Categorias base de medicamentos
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
