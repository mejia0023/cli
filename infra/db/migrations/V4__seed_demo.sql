-- ============================================================================
-- V4__seed_demo.sql — Datos demo para que el frontend tenga contenido
-- ============================================================================
-- NOTA (refactor microservicios): las tablas usuario y paciente ya NO viven en
-- MS3 (van a MS1). Por eso esta migracion ya no inserta usuarios ni pacientes.
-- Los IDs de cajero/paciente usados en facturas/recetas demo (V5) son UUIDs
-- "de referencia" sin FK; el dueño canonico de esos registros es MS1.
--   cajero farma  = 33333333-3333-3333-3333-333333333333
--   cajero admin  = 11111111-1111-1111-1111-111111111111
--   pacientes     = aaaa1111.. (Carlos) / aaaa2222.. (Paco)  [coherente con Supabase]
-- ============================================================================

-- Proveedores demo
INSERT INTO proveedor (id, nombre, nit, telefono, email, direccion) VALUES
    ('bbbb1111-bbbb-1111-bbbb-111111111111', 'FarmaSur SRL',     '1023456789', '22440011', 'ventas@farmasur.bo',   'Av. Salud 123, Santa Cruz'),
    ('bbbb2222-bbbb-2222-bbbb-222222222222', 'Distribuidora MD', '1098765432', '22550022', 'pedidos@mdistribu.bo', 'Calle Comercio 456, La Paz')
ON CONFLICT (nit) DO NOTHING;

-- Medicamentos demo
INSERT INTO medicamento (id, nombre, descripcion, categoria_id, precio_venta, requiere_receta, controlado, stock_minimo) VALUES
    ('cccc1111-cccc-1111-cccc-111111111111', 'Paracetamol 500mg',  'Tabletas analgesico-antipiretico',     1,  5.00,  FALSE, FALSE, 50),
    ('cccc2222-cccc-2222-cccc-222222222222', 'Ibuprofeno 400mg',   'Antiinflamatorio no esteroideo',       3,  8.50,  FALSE, FALSE, 40),
    ('cccc3333-cccc-3333-cccc-333333333333', 'Amoxicilina 500mg',  'Antibiotico de amplio espectro',       2, 15.00,  TRUE,  FALSE, 30),
    ('cccc4444-cccc-4444-cccc-444444444444', 'Loratadina 10mg',    'Antihistaminico de segunda generacion',4,  7.00,  FALSE, FALSE, 30),
    ('cccc5555-cccc-5555-cccc-555555555555', 'Enalapril 10mg',     'Antihipertensivo IECA',                5, 12.00,  TRUE,  FALSE, 25),
    ('cccc6666-cccc-6666-cccc-666666666666', 'Morfina 10mg',       'Opioide controlado',                   7, 45.00,  TRUE,  TRUE,  10),
    ('cccc7777-cccc-7777-cccc-777777777777', 'Diazepam 5mg',       'Benzodiacepina controlada',            7, 25.00,  TRUE,  TRUE,  15),
    ('cccc8888-cccc-8888-cccc-888888888888', 'Vitamina C 1g',      'Suplemento vitaminico',                8,  6.50,  FALSE, FALSE, 100)
ON CONFLICT (id) DO NOTHING;

-- Lotes demo (fechas en el futuro para que no se vean vencidos)
INSERT INTO lote (id, medicamento_id, proveedor_id, codigo_lote, fecha_vencimiento, cantidad_inicial, cantidad_actual, precio_compra) VALUES
    ('dddd1111-dddd-1111-dddd-111111111111', 'cccc1111-cccc-1111-cccc-111111111111', 'bbbb1111-bbbb-1111-bbbb-111111111111', 'PAR-2027-001', '2027-06-30', 200, 200, 3.00),
    ('dddd2222-dddd-2222-dddd-222222222222', 'cccc2222-cccc-2222-cccc-222222222222', 'bbbb1111-bbbb-1111-bbbb-111111111111', 'IBU-2027-002', '2027-08-15', 150, 150, 5.00),
    ('dddd3333-dddd-3333-dddd-333333333333', 'cccc3333-cccc-3333-cccc-333333333333', 'bbbb2222-bbbb-2222-bbbb-222222222222', 'AMX-2026-003', '2026-12-31',  80,  80, 9.00),
    ('dddd4444-dddd-4444-dddd-444444444444', 'cccc4444-cccc-4444-cccc-444444444444', 'bbbb1111-bbbb-1111-bbbb-111111111111', 'LOR-2027-004', '2027-04-20', 100, 100, 4.00),
    ('dddd5555-dddd-5555-dddd-555555555555', 'cccc5555-cccc-5555-cccc-555555555555', 'bbbb2222-bbbb-2222-bbbb-222222222222', 'ENA-2026-005', '2026-10-15',  60,  60, 7.50),
    ('dddd6666-dddd-6666-dddd-666666666666', 'cccc6666-cccc-6666-cccc-666666666666', 'bbbb2222-bbbb-2222-bbbb-222222222222', 'MOR-2026-006', '2026-08-30',  20,  20, 30.00),
    ('dddd7777-dddd-7777-dddd-777777777777', 'cccc7777-cccc-7777-cccc-777777777777', 'bbbb2222-bbbb-2222-bbbb-222222222222', 'DIA-2026-007', '2026-11-10',  25,  25, 16.00),
    ('dddd8888-dddd-8888-dddd-888888888888', 'cccc8888-cccc-8888-cccc-888888888888', 'bbbb1111-bbbb-1111-bbbb-111111111111', 'VTC-2027-008', '2027-09-05', 300, 300, 4.50)
ON CONFLICT (id) DO NOTHING;

-- Movimiento de entrada inicial por cada lote (trazabilidad)
INSERT INTO movimiento_inventario (lote_id, tipo, cantidad, motivo, usuario_id)
SELECT l.id, 'ENTRADA', l.cantidad_inicial, 'Carga inicial de seed', '33333333-3333-3333-3333-333333333333'
FROM lote l
WHERE NOT EXISTS (
    SELECT 1 FROM movimiento_inventario m
    WHERE m.lote_id = l.id AND m.motivo = 'Carga inicial de seed'
);
