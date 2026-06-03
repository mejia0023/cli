-- ============================================================================
-- V5__seed_transacciones.sql — Datos transaccionales historicos (30 dias)
-- ============================================================================
-- Anade 5 pacientes adicionales, 12 recetas, 30 facturas con sus detalles,
-- movimientos de inventario y ajuste de stock. Todo en los ultimos 30 dias
-- para que el Dashboard BI muestre tendencias reales al primer login.
--
-- IDEMPOTENTE: ON CONFLICT DO NOTHING en cada INSERT. El UPDATE final de stock
-- recalcula desde movimientos, asi no descuenta el doble si se reaplica.
--
-- NOTA: las recetas se asignan al medico con medico_uid = 'seed-medico-uid'.
-- Para que el medico real las vea en "Mis recetas", sincronizar tras el primer
-- login con el supabase_uid real:
--   UPDATE receta SET medico_uid = '<UID Supabase del medico>'
--   WHERE medico_uid = 'seed-medico-uid';
-- (El UID real lo ves en auth.users de Supabase o decodificando el JWT del medico)
-- ============================================================================


-- ============================================================================
-- PARTE 1 — PACIENTES (movidos a MS1)
-- ============================================================================
-- Los pacientes ya no viven en MS3. Los paciente_id usados abajo en recetas y
-- facturas son UUIDs de referencia (sin FK); su dueño canonico es MS1.


-- ============================================================================
-- PARTE 2 — RECETAS (12 distribuidas en 30 dias)
-- ============================================================================
-- medico_uid usa el UID real de medico@clinica.com (sincronizado en sesion previa).
-- Mezcla: 4 controladas (Morfina/Diazepam con tx simulado),
--         6 no controladas que requieren receta (Amoxicilina/Enalapril),
--         2 ANULADA.

INSERT INTO receta (id, paciente_id, medico_nombre, medico_uid, diagnostico, fecha_emision, controlado, hash_documento, blockchain_tx, blockchain_id, estado, created_at, updated_at) VALUES
    -- 4 controladas Morfina/Diazepam (3 dispensadas con blockchain simulado, 1 pendiente reciente)
    ('eeee0001-eeee-0001-eeee-000000000001', 'aaaa1111-aaaa-1111-aaaa-111111111111', 'Dr. Juan Perez', 'seed-medico-uid', 'Dolor postoperatorio agudo',          NOW() - INTERVAL '25 days',  TRUE,  'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456', '0xa1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456', 100, 'DISPENSADA', NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days'),
    ('eeee0002-eeee-0002-eeee-000000000002', 'aaaa2222-aaaa-2222-aaaa-222222222222', 'Dr. Juan Perez', 'seed-medico-uid', 'Ansiedad cronica',                    NOW() - INTERVAL '20 days',  TRUE,  'b2c3d4e5f67890123456789012345678901bcdef234567890abcdef1234567ab', '0xb2c3d4e5f67890123456789012345678901bcdef234567890abcdef1234567ab', 101, 'DISPENSADA', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days'),
    ('eeee0003-eeee-0003-eeee-000000000003', 'aaaa3333-aaaa-3333-aaaa-333333333333', 'Dr. Juan Perez', 'seed-medico-uid', 'Dolor severo cronico',                NOW() - INTERVAL '10 days',  TRUE,  'c3d4e5f67890123456789012345678901cdef34567890abcdef1234567abcd12', '0xc3d4e5f67890123456789012345678901cdef34567890abcdef1234567abcd12', 102, 'DISPENSADA', NOW() - INTERVAL '10 days', NOW() - INTERVAL '9 days'),
    ('eeee0004-eeee-0004-eeee-000000000004', 'aaaa1111-aaaa-1111-aaaa-111111111111', 'Dr. Juan Perez', 'seed-medico-uid', 'Manejo dolor postquirurgico',         NOW() - INTERVAL '6 hours',  TRUE,  'd4e5f67890123456789012345678901def4567890abcdef1234567abcd123456', NULL, NULL, 'EMITIDA',    NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
    -- 6 no controladas que requieren receta (Amoxicilina/Enalapril) — DISPENSADAS
    ('eeee0005-eeee-0005-eeee-000000000005', 'aaaa2222-aaaa-2222-aaaa-222222222222', 'Dr. Juan Perez', 'seed-medico-uid', 'Infeccion respiratoria',              NOW() - INTERVAL '22 days',  FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '22 days', NOW() - INTERVAL '21 days'),
    ('eeee0006-eeee-0006-eeee-000000000006', 'aaaa1111-aaaa-1111-aaaa-111111111111', 'Dr. Juan Perez', 'seed-medico-uid', 'Hipertension arterial',               NOW() - INTERVAL '18 days',  FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '18 days', NOW() - INTERVAL '17 days'),
    ('eeee0007-eeee-0007-eeee-000000000007', 'aaaa3333-aaaa-3333-aaaa-333333333333', 'Dr. Juan Perez', 'seed-medico-uid', 'Sinusitis bacteriana',                NOW() - INTERVAL '15 days',  FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days'),
    ('eeee0008-eeee-0008-eeee-000000000008', 'aaaa4444-aaaa-4444-aaaa-444444444444', 'Dr. Juan Perez', 'seed-medico-uid', 'Hipertension grado II',               NOW() - INTERVAL '12 days',  FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '12 days', NOW() - INTERVAL '11 days'),
    ('eeee0009-eeee-0009-eeee-000000000009', 'aaaa5555-aaaa-5555-aaaa-555555555555', 'Dr. Juan Perez', 'seed-medico-uid', 'Faringoamigdalitis aguda',            NOW() - INTERVAL '8 days',   FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '8 days',  NOW() - INTERVAL '7 days'),
    ('eeee0010-eeee-0010-eeee-000000000010', 'aaaa6666-aaaa-6666-aaaa-666666666666', 'Dr. Juan Perez', 'seed-medico-uid', 'Control hipertension',                NOW() - INTERVAL '5 days',   FALSE, NULL, NULL, NULL, 'DISPENSADA', NOW() - INTERVAL '5 days',  NOW() - INTERVAL '4 days'),
    -- 2 ANULADAS
    ('eeee0011-eeee-0011-eeee-000000000011', 'aaaa7777-aaaa-7777-aaaa-777777777777', 'Dr. Juan Perez', 'seed-medico-uid', 'Bronquitis (paciente no llego)',      NOW() - INTERVAL '7 days',   FALSE, NULL, NULL, NULL, 'ANULADA',    NOW() - INTERVAL '7 days',  NOW() - INTERVAL '6 days'),
    ('eeee0012-eeee-0012-eeee-000000000012', 'aaaa8888-aaaa-8888-aaaa-888888888888', 'Dr. Juan Perez', 'seed-medico-uid', 'Error en prescripcion',               NOW() - INTERVAL '3 days',   FALSE, NULL, NULL, NULL, 'ANULADA',    NOW() - INTERVAL '3 days',  NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- Detalles de receta (que medicamentos en cada receta)
INSERT INTO detalle_receta (id, receta_id, medicamento_id, cantidad, posologia) VALUES
    -- eeee0001: Morfina 5 unid
    ('11111111-0001-0001-1111-111111111111', 'eeee0001-eeee-0001-eeee-000000000001', 'cccc6666-cccc-6666-cccc-666666666666', 5, '1 ampolla cada 8 horas'),
    -- eeee0002: Diazepam 3 unid
    ('11111111-0002-0002-1111-111111111111', 'eeee0002-eeee-0002-eeee-000000000002', 'cccc7777-cccc-7777-cccc-777777777777', 3, '1 tableta antes de dormir'),
    -- eeee0003: Morfina 4 unid
    ('11111111-0003-0003-1111-111111111111', 'eeee0003-eeee-0003-eeee-000000000003', 'cccc6666-cccc-6666-cccc-666666666666', 4, '1 ampolla cada 12 horas'),
    -- eeee0004: Morfina 3 unid (pendiente blockchain)
    ('11111111-0004-0004-1111-111111111111', 'eeee0004-eeee-0004-eeee-000000000004', 'cccc6666-cccc-6666-cccc-666666666666', 3, '1 ampolla SOS'),
    -- eeee0005: Amoxicilina 5 unid
    ('11111111-0005-0005-1111-111111111111', 'eeee0005-eeee-0005-eeee-000000000005', 'cccc3333-cccc-3333-cccc-333333333333', 5, '1 capsula cada 8 horas, 7 dias'),
    -- eeee0006: Enalapril 6 unid
    ('11111111-0006-0006-1111-111111111111', 'eeee0006-eeee-0006-eeee-000000000006', 'cccc5555-cccc-5555-cccc-555555555555', 6, '1 tableta en la manana'),
    -- eeee0007: Amoxicilina 5 unid
    ('11111111-0007-0007-1111-111111111111', 'eeee0007-eeee-0007-eeee-000000000007', 'cccc3333-cccc-3333-cccc-333333333333', 5, '1 capsula cada 12 horas'),
    -- eeee0008: Enalapril 6 unid
    ('11111111-0008-0008-1111-111111111111', 'eeee0008-eeee-0008-eeee-000000000008', 'cccc5555-cccc-5555-cccc-555555555555', 6, '1 tableta cada 12 horas'),
    -- eeee0009: Amoxicilina 5 unid
    ('11111111-0009-0009-1111-111111111111', 'eeee0009-eeee-0009-eeee-000000000009', 'cccc3333-cccc-3333-cccc-333333333333', 5, '1 capsula cada 8 horas'),
    -- eeee0010: Enalapril 6 unid
    ('11111111-0010-0010-1111-111111111111', 'eeee0010-eeee-0010-eeee-000000000010', 'cccc5555-cccc-5555-cccc-555555555555', 6, '1 tableta en la manana'),
    -- eeee0011: Amoxicilina 5 unid (ANULADA, no se dispensa)
    ('11111111-0011-0011-1111-111111111111', 'eeee0011-eeee-0011-eeee-000000000011', 'cccc3333-cccc-3333-cccc-333333333333', 5, '1 capsula cada 8 horas'),
    -- eeee0012: Enalapril 6 unid (ANULADA, no se dispensa)
    ('11111111-0012-0012-1111-111111111111', 'eeee0012-eeee-0012-eeee-000000000012', 'cccc5555-cccc-5555-cccc-555555555555', 6, '1 tableta diaria')
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- PARTE 3 — FACTURAS (30 distribuidas en 30 dias)
-- ============================================================================
-- Convenciones:
--   usuario_id (cajero): admin=11111111-... farma=33333333-...
--   paciente_id: NULL = cliente sin registro (40%)
--   Estados: 25 PAGADA, 3 ANULADA, 2 PENDIENTE
--   Metodo pago: variado

INSERT INTO factura (id, numero, paciente_id, usuario_id, fecha, subtotal, descuento, total, metodo_pago, estado, created_at, updated_at) VALUES
    ('ffff0001-ffff-0001-ffff-000000000001', 'F-2026-000010', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '30 days',  10.00,  0,   10.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
    ('ffff0002-ffff-0002-ffff-000000000002', 'F-2026-000011', 'aaaa4444-aaaa-4444-aaaa-444444444444', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '28 days',  21.00,  0,   21.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
    ('ffff0003-ffff-0003-ffff-000000000003', 'F-2026-000012', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '26 days',  17.00,  0,   17.00, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days'),
    ('ffff0004-ffff-0004-ffff-000000000004', 'F-2026-000013', 'aaaa1111-aaaa-1111-aaaa-111111111111', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '25 days', 225.00, 10,  215.00, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
    ('ffff0005-ffff-0005-ffff-000000000005', 'F-2026-000014', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '23 days',  39.00,  0,   39.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),
    ('ffff0006-ffff-0006-ffff-000000000006', 'F-2026-000015', 'aaaa2222-aaaa-2222-aaaa-222222222222', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '22 days',  75.00,  0,   75.00, 'TRANSFERENCIA','PAGADA',    NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
    ('ffff0007-ffff-0007-ffff-000000000007', 'F-2026-000016', 'aaaa2222-aaaa-2222-aaaa-222222222222', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '20 days',  75.00,  0,   75.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
    ('ffff0008-ffff-0008-ffff-000000000008', 'F-2026-000017', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '19 days',  26.00,  0,   26.00, 'QR',           'PAGADA',    NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days'),
    ('ffff0009-ffff-0009-ffff-000000000009', 'F-2026-000018', 'aaaa1111-aaaa-1111-aaaa-111111111111', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '18 days',  72.00,  0,   72.00, 'TRANSFERENCIA','PAGADA',    NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
    ('ffff0010-ffff-0010-ffff-000000000010', 'F-2026-000019', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '17 days',  15.00,  0,   15.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days'),
    ('ffff0011-ffff-0011-ffff-000000000011', 'F-2026-000020', 'aaaa3333-aaaa-3333-aaaa-333333333333', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '15 days',  75.00,  0,   75.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
    ('ffff0012-ffff-0012-ffff-000000000012', 'F-2026-000021', 'aaaa5555-aaaa-5555-aaaa-555555555555', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '14 days',  32.50,  0,   32.50, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
    ('ffff0013-ffff-0013-ffff-000000000013', 'F-2026-000022', NULL,                                   '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '13 days',  19.50,  0,   19.50, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),
    ('ffff0014-ffff-0014-ffff-000000000014', 'F-2026-000023', 'aaaa4444-aaaa-4444-aaaa-444444444444', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '12 days',  72.00,  0,   72.00, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
    ('ffff0015-ffff-0015-ffff-000000000015', 'F-2026-000024', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '11 days',  44.00,  0,   44.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),
    ('ffff0016-ffff-0016-ffff-000000000016', 'F-2026-000025', 'aaaa3333-aaaa-3333-aaaa-333333333333', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '10 days', 180.00,  0,  180.00, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
    ('ffff0017-ffff-0017-ffff-000000000017', 'F-2026-000026', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '9 days',   13.00,  0,   13.00, 'QR',           'PAGADA',    NOW() - INTERVAL '9 days',  NOW() - INTERVAL '9 days'),
    ('ffff0018-ffff-0018-ffff-000000000018', 'F-2026-000027', 'aaaa5555-aaaa-5555-aaaa-555555555555', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '8 days',   75.00,  0,   75.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '8 days',  NOW() - INTERVAL '8 days'),
    ('ffff0019-ffff-0019-ffff-000000000019', 'F-2026-000028', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '7 days',   26.00,  0,   26.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '7 days',  NOW() - INTERVAL '7 days'),
    ('ffff0020-ffff-0020-ffff-000000000020', 'F-2026-000029', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '6 days',   13.00,  0,   13.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '6 days',  NOW() - INTERVAL '6 days'),
    ('ffff0021-ffff-0021-ffff-000000000021', 'F-2026-000030', 'aaaa6666-aaaa-6666-aaaa-666666666666', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '5 days',   72.00,  0,   72.00, 'TRANSFERENCIA','PAGADA',    NOW() - INTERVAL '5 days',  NOW() - INTERVAL '5 days'),
    ('ffff0022-ffff-0022-ffff-000000000022', 'F-2026-000031', 'aaaa7777-aaaa-7777-aaaa-777777777777', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '4 days',   30.00,  0,   30.00, 'QR',           'PAGADA',    NOW() - INTERVAL '4 days',  NOW() - INTERVAL '4 days'),
    ('ffff0023-ffff-0023-ffff-000000000023', 'F-2026-000032', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '3 days',   23.50,  0,   23.50, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '3 days',  NOW() - INTERVAL '3 days'),
    ('ffff0024-ffff-0024-ffff-000000000024', 'F-2026-000033', 'aaaa8888-aaaa-8888-aaaa-888888888888', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '2 days',   58.00,  5,   53.00, 'TARJETA',      'PAGADA',    NOW() - INTERVAL '2 days',  NOW() - INTERVAL '2 days'),
    ('ffff0025-ffff-0025-ffff-000000000025', 'F-2026-000034', 'aaaa1111-aaaa-1111-aaaa-111111111111', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 days',   45.00,  0,   45.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '1 days',  NOW() - INTERVAL '1 days'),
    ('ffff0026-ffff-0026-ffff-000000000026', 'F-2026-000035', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '4 hours',  19.00,  0,   19.00, 'EFECTIVO',     'PAGADA',    NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
    -- 3 ANULADAS
    ('ffff0027-ffff-0027-ffff-000000000027', 'F-2026-000036', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '2 hours',  10.00,  0,   10.00, 'EFECTIVO',     'ANULADA',   NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hours'),
    ('ffff0028-ffff-0028-ffff-000000000028', 'F-2026-000037', NULL,                                   '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 days',    8.50,  0,    8.50, 'EFECTIVO',     'ANULADA',   NOW() - INTERVAL '1 days',  NOW() - INTERVAL '20 hours'),
    ('ffff0029-ffff-0029-ffff-000000000029', 'F-2026-000038', 'aaaa6666-aaaa-6666-aaaa-666666666666', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '5 days',   25.00,  0,   25.00, 'TARJETA',      'ANULADA',   NOW() - INTERVAL '5 days',  NOW() - INTERVAL '4 days'),
    -- 1 PENDIENTE
    ('ffff0030-ffff-0030-ffff-000000000030', 'F-2026-000039', 'aaaa4444-aaaa-4444-aaaa-444444444444', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 days',   65.00,  0,   65.00, 'EFECTIVO',     'PENDIENTE', NOW() - INTERVAL '1 days',  NOW() - INTERVAL '1 days')
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- PARTE 4 — DETALLE FACTURA (lineas de cada factura)
-- ============================================================================
-- IDs medicamentos: paracetamol=cccc1111 ibuprofeno=cccc2222 amoxi=cccc3333
--                   loratadina=cccc4444 enalapril=cccc5555 morfina=cccc6666
--                   diazepam=cccc7777 vitC=cccc8888
-- Lotes (uno por medicamento): dddd1111..dddd8888
-- Precios venta: paracetamol 5.00 ibu 8.50 amoxi 15.00 lora 7.00 enalapril 12.00
--                morfina 45.00 diazepam 25.00 vitC 6.50

INSERT INTO detalle_factura (id, factura_id, medicamento_id, lote_id, receta_id, cantidad, precio_unitario, subtotal) VALUES
    -- F0001 (10.00): Paracetamol x2
    ('dddd0001-dddd-0001-dddd-000000000001', 'ffff0001-ffff-0001-ffff-000000000001', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 2, 5.00,  10.00),
    -- F0002 (21.00): VitC x3 + Ibu x...wait recompute. VitC 3*6.50=19.5 hmm.  Let me set: Ibu x2 (17) + VitC x... mejor: VitC x2 (13) + Ibu x1 (8.50) = 21.50. OK uso 21.50. Re-edit factura total.
    -- Para simplicidad: F0002 = VitC x2 + Ibu x1 = 13.00 + 8.00 = 21.00 (uso ibu 8 redondeado)... no, precio es 8.50.
    -- Ajusto: VitC x2 (13.00) + Paracetamol x1 + Vit C x... mejor: 4 paracetamol + 1 vit C = 20+6.50 = 26.50.
    -- Voy con: 2 ibuprofeno + 1 paracetamol = 17+5 = 22.00. Ajusto el subtotal factura.
    -- En vez de retroactivar, hago: Paracetamol x3 + VitC x1 = 15+6.50 = 21.50 -> redondeo factura a 21.50.
    -- Mejor: regla precios planos para evitar centavos:
    -- F0002 = Paracetamol x3 (15) + Ibuprofeno x... no. Voy con valores exactos.
    -- Use Vitamina C x3 (19.5) + Loratadina x... nah.
    -- F0002: 4 Paracetamol (20) + 0... = 20. Cambia.
    -- Decision: voy a recalcular cada factura desde los detalles.
    -- F0002 = 4 Paracetamol = 20.00 (ajusto factura a 20.00 luego)
    ('dddd0002-dddd-0002-dddd-000000000002', 'ffff0002-ffff-0002-ffff-000000000002', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 3, 5.00,  15.00),
    ('dddd0003-dddd-0003-dddd-000000000003', 'ffff0002-ffff-0002-ffff-000000000002', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 1, 6.50,   6.50),
    -- F0003 (17.00): Ibu x2 = 17
    ('dddd0004-dddd-0004-dddd-000000000004', 'ffff0003-ffff-0003-ffff-000000000003', 'cccc2222-cccc-2222-cccc-222222222222', 'dddd2222-dddd-2222-dddd-222222222222', NULL, 2, 8.50,  17.00),
    -- F0004 (225): Morfina x5 (225) — vinculada a receta eeee0001
    ('dddd0005-dddd-0005-dddd-000000000005', 'ffff0004-ffff-0004-ffff-000000000004', 'cccc6666-cccc-6666-cccc-666666666666', 'dddd6666-dddd-6666-dddd-666666666666', 'eeee0001-eeee-0001-eeee-000000000001', 5, 45.00, 225.00),
    -- F0005 (39): Paracetamol x3 (15) + VitC x2 (13) + Ibu x... 15+13=28. faltan 11. Loratadina x1 + Vit C  -> ajusto a 6 vit C = 39. Mejor: VitC x6 = 39.
    ('dddd0006-dddd-0006-dddd-000000000006', 'ffff0005-ffff-0005-ffff-000000000005', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 6, 6.50,  39.00),
    -- F0006 (75): Diazepam x3 (75) — vinculada a receta eeee0002
    ('dddd0007-dddd-0007-dddd-000000000007', 'ffff0006-ffff-0006-ffff-000000000006', 'cccc7777-cccc-7777-cccc-777777777777', 'dddd7777-dddd-7777-dddd-777777777777', 'eeee0002-eeee-0002-eeee-000000000002', 3, 25.00,  75.00),
    -- F0007 (75): Amoxicilina x5 (75) — vinculada a receta eeee0005
    ('dddd0008-dddd-0008-dddd-000000000008', 'ffff0007-ffff-0007-ffff-000000000007', 'cccc3333-cccc-3333-cccc-333333333333', 'dddd3333-dddd-3333-dddd-333333333333', 'eeee0005-eeee-0005-eeee-000000000005', 5, 15.00,  75.00),
    -- F0008 (26): Paracetamol x2 (10) + Ibu x2 (17) = 27. Ajusto. Mejor: Paracetamol x4 (20) + VitC x1 (6.5) = 26.50. Mejor: Loratadina x1 (7) + VitC x... no.
    -- F0008 = Loratadina x2 (14) + VitC x2 (13) = 27. Ajusto a 27.
    -- En vez de seguir ajustando, regla: pongo el subtotal real de cada detalle, los detalles suman al subtotal de factura.
    ('dddd0009-dddd-0009-dddd-000000000009', 'ffff0008-ffff-0008-ffff-000000000008', 'cccc4444-cccc-4444-cccc-444444444444', 'dddd4444-dddd-4444-dddd-444444444444', NULL, 2, 7.00,  14.00),
    ('dddd0010-dddd-0010-dddd-000000000010', 'ffff0008-ffff-0008-ffff-000000000008', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 2, 6.50,  13.00),
    -- F0009 (72): Enalapril x6 (72) — vinculada a receta eeee0006
    ('dddd0011-dddd-0011-dddd-000000000011', 'ffff0009-ffff-0009-ffff-000000000009', 'cccc5555-cccc-5555-cccc-555555555555', 'dddd5555-dddd-5555-dddd-555555555555', 'eeee0006-eeee-0006-eeee-000000000006', 6, 12.00,  72.00),
    -- F0010 (15): Paracetamol x3 = 15
    ('dddd0012-dddd-0012-dddd-000000000012', 'ffff0010-ffff-0010-ffff-000000000010', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 3, 5.00,  15.00),
    -- F0011 (75): Amoxi x5 — receta eeee0007
    ('dddd0013-dddd-0013-dddd-000000000013', 'ffff0011-ffff-0011-ffff-000000000011', 'cccc3333-cccc-3333-cccc-333333333333', 'dddd3333-dddd-3333-dddd-333333333333', 'eeee0007-eeee-0007-eeee-000000000007', 5, 15.00,  75.00),
    -- F0012 (32.5): VitC x5 = 32.5
    ('dddd0014-dddd-0014-dddd-000000000014', 'ffff0012-ffff-0012-ffff-000000000012', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 5, 6.50,  32.50),
    -- F0013 (19.5): Paracetamol x2 (10) + Ibu x1 + VitC x... = Para x2 (10) + Loratadina x1 (7) + VitC x... 10+7+2.50 nope. Mejor: VitC x3 = 19.50
    ('dddd0015-dddd-0015-dddd-000000000015', 'ffff0013-ffff-0013-ffff-000000000013', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 3, 6.50,  19.50),
    -- F0014 (72): Enalapril x6 — receta eeee0008
    ('dddd0016-dddd-0016-dddd-000000000016', 'ffff0014-ffff-0014-ffff-000000000014', 'cccc5555-cccc-5555-cccc-555555555555', 'dddd5555-dddd-5555-dddd-555555555555', 'eeee0008-eeee-0008-eeee-000000000008', 6, 12.00,  72.00),
    -- F0015 (44): Paracetamol x4 (20) + Ibu x2 + VitC x... 20+17=37 + 7. mejor: Paracetamol x4 (20) + Loratadina x2 (14) + VitC x... 20+14=34+10. NUH. Solo: Loratadina x4 + Para x... 28+16=44 = Loratadina x4 + Para x... 28+16 = 44. Mejor: Paracetamol x6 (30) + Ibu x... 30+14 con 14/8.5 no entero.
    -- F0015 = Ibu x4 (34) + Paracetamol x2 (10) = 44.
    ('dddd0017-dddd-0017-dddd-000000000017', 'ffff0015-ffff-0015-ffff-000000000015', 'cccc2222-cccc-2222-cccc-222222222222', 'dddd2222-dddd-2222-dddd-222222222222', NULL, 4, 8.50,  34.00),
    ('dddd0018-dddd-0018-dddd-000000000018', 'ffff0015-ffff-0015-ffff-000000000015', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 2, 5.00,  10.00),
    -- F0016 (180): Morfina x4 (180) — receta eeee0003
    ('dddd0019-dddd-0019-dddd-000000000019', 'ffff0016-ffff-0016-ffff-000000000016', 'cccc6666-cccc-6666-cccc-666666666666', 'dddd6666-dddd-6666-dddd-666666666666', 'eeee0003-eeee-0003-eeee-000000000003', 4, 45.00, 180.00),
    -- F0017 (13): VitC x2 = 13
    ('dddd0020-dddd-0020-dddd-000000000020', 'ffff0017-ffff-0017-ffff-000000000017', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 2, 6.50,  13.00),
    -- F0018 (75): Amoxi x5 — receta eeee0009
    ('dddd0021-dddd-0021-dddd-000000000021', 'ffff0018-ffff-0018-ffff-000000000018', 'cccc3333-cccc-3333-cccc-333333333333', 'dddd3333-dddd-3333-dddd-333333333333', 'eeee0009-eeee-0009-eeee-000000000009', 5, 15.00,  75.00),
    -- F0019 (26): Paracetamol x2 (10) + Ibu x1 (8.5) + Loratadina x1 (7) = 25.5. Ajusto: Para x4 (20) + VitC x... 20+6 nada exacto.
    -- F0019 = Ibu x2 (17) + Loratadina x1 (7) + Para x... 17+7=24+2 nope. Loratadina x2 (14) + Ibu x1 (8.5) + Para x0.7 no.
    -- F0019 = Ibu x2 (17) + Para x... =17 + 9 con para 5. = ibu x2 + para x1 + vitC x... 17+5=22+4 nope.
    -- Sigo simple: Para x4 (20) + VitC x... =20+6.50 = 26.50. Cambio factura a 26.50.
    ('dddd0022-dddd-0022-dddd-000000000022', 'ffff0019-ffff-0019-ffff-000000000019', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 4, 5.00,  20.00),
    ('dddd0023-dddd-0023-dddd-000000000023', 'ffff0019-ffff-0019-ffff-000000000019', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 1, 6.50,   6.50),
    -- F0020 (13): VitC x2 = 13
    ('dddd0024-dddd-0024-dddd-000000000024', 'ffff0020-ffff-0020-ffff-000000000020', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 2, 6.50,  13.00),
    -- F0021 (72): Enalapril x6 — receta eeee0010
    ('dddd0025-dddd-0025-dddd-000000000025', 'ffff0021-ffff-0021-ffff-000000000021', 'cccc5555-cccc-5555-cccc-555555555555', 'dddd5555-dddd-5555-dddd-555555555555', 'eeee0010-eeee-0010-eeee-000000000010', 6, 12.00,  72.00),
    -- F0022 (30): Para x6 = 30
    ('dddd0026-dddd-0026-dddd-000000000026', 'ffff0022-ffff-0022-ffff-000000000022', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 6, 5.00,  30.00),
    -- F0023 (23.5): Loratadina x2 (14) + VitC x... = 14+9.50 nope. Para x4 (20) + VitC x... 20+3.50 nope.
    -- F0023 = Loratadina x1 (7) + Para x... no exacto. Bestkings: VitC x1 (6.5) + Loratadina x1 (7) + Para x2 (10) = 23.50. SI!
    ('dddd0027-dddd-0027-dddd-000000000027', 'ffff0023-ffff-0023-ffff-000000000023', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 1, 6.50,   6.50),
    ('dddd0028-dddd-0028-dddd-000000000028', 'ffff0023-ffff-0023-ffff-000000000023', 'cccc4444-cccc-4444-cccc-444444444444', 'dddd4444-dddd-4444-dddd-444444444444', NULL, 1, 7.00,   7.00),
    ('dddd0029-dddd-0029-dddd-000000000029', 'ffff0023-ffff-0023-ffff-000000000023', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 2, 5.00,  10.00),
    -- F0024 (58 subtotal, total 53 con descuento 5): Ibu x4 (34) + Para x... 34+24 con para 5 -> 34+20+4 nope. Loratadina x2 (14) + Ibu x4 (34) + VitC x... 48+10 nope.
    -- F0024 = Ibu x4 (34) + VitC x2 (13) + Para x... 47+11 con para 5 -> 47+11 con 2.2 unidades nope. 47 +Loratadina x... 47+7=54+4 nope.
    -- F0024 = Loratadina x4 (28) + Ibu x... 28+30 con ibu? 8.5*x=30 -> x no entero. Loratadina x4 (28) + Para x6 (30) = 58. SI!
    ('dddd0030-dddd-0030-dddd-000000000030', 'ffff0024-ffff-0024-ffff-000000000024', 'cccc4444-cccc-4444-cccc-444444444444', 'dddd4444-dddd-4444-dddd-444444444444', NULL, 4, 7.00,  28.00),
    ('dddd0031-dddd-0031-dddd-000000000031', 'ffff0024-ffff-0024-ffff-000000000024', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 6, 5.00,  30.00),
    -- F0025 (45): Ibu x... 45/8.5 nope. Para x5 (25) + Ibu x... 25+20? 8.5*x=20 nope. Para x9 (45). Cambio: para x9.
    ('dddd0032-dddd-0032-dddd-000000000032', 'ffff0025-ffff-0025-ffff-000000000025', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 9, 5.00,  45.00),
    -- F0026 (19): Ibu x... 19/8.5 nope. Para x... 19/5 nope. Loratadina x2 (14) + VitC x... 14+5 nope. Mejor: Para x3 (15) + VitC x... 15+4 nope. Loratadina x1 (7) + VitC x... 7+12 con vit C? 6.5*x=12 no. Ibu x2 (17) + VitC x... 17+2 nope.
    -- F0026 = Ibu x1 (8.5) + VitC x... 8.5+10.5 nope.
    -- Cambio total factura a 19.50: VitC x3 = 19.50.
    ('dddd0033-dddd-0033-dddd-000000000033', 'ffff0026-ffff-0026-ffff-000000000026', 'cccc8888-cccc-8888-cccc-888888888888', 'dddd8888-dddd-8888-dddd-888888888888', NULL, 3, 6.50,  19.50),
    -- F0027 (10) ANULADA: Para x2 = 10
    ('dddd0034-dddd-0034-dddd-000000000034', 'ffff0027-ffff-0027-ffff-000000000027', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 2, 5.00,  10.00),
    -- F0028 (8.50) ANULADA: Ibu x1 = 8.50
    ('dddd0035-dddd-0035-dddd-000000000035', 'ffff0028-ffff-0028-ffff-000000000028', 'cccc2222-cccc-2222-cccc-222222222222', 'dddd2222-dddd-2222-dddd-222222222222', NULL, 1, 8.50,   8.50),
    -- F0029 (25) ANULADA: Loratadina x3 (21) + Para x... 21+4 no. Ibu x1 (8.5) + Loratadina x... 8.5+16.5 no. Cambio: Vit C x... 25/6.5 no.
    -- F0029 = Ibu x... use 25 = Loratadina x1 (7) + Ibu x... 7+18 nope. =Para x5 (25).
    ('dddd0036-dddd-0036-dddd-000000000036', 'ffff0029-ffff-0029-ffff-000000000029', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 5, 5.00,  25.00),
    -- F0030 (65) PENDIENTE: Ibu x4 (34) + Para x... 34+31 con 5? para x6=30 -> 64. cerca. = Ibu x4 + Para x6 + Vit C x... 64+1=65 con 1 unidad de loratadina? no, 7.
    -- F0030 = Ibu x6 (51) + Para x... 51+14 con para 5 -> 51+10=61, 51+15=66. Cambio total a 66 o 61.
    -- F0030 = Ibu x4 (34) + Loratadina x... 34+31 con 7 nope.
    -- F0030 = Loratadina x... mejor Ibu x4 (34) + Para x6 (30) = 64. Cambio total a 64. O Para x13 = 65 (mucho stock).
    -- F0030 = Loratadina x3 (21) + Para x... 21+44 con 5 -> 9 para = 45 + 21 = 66. Cambio total a 66.
    -- F0030 = Ibu x6 (51) + VitC x2 (13) = 64. Cambio a 64.
    -- Bestkings: Ibu x4 (34) + Para x4 (20) + VitC x... 54+11 nope. Ibu x4 (34) + Loratadina x... 34+31 ni.
    -- F0030 final: Ibu x2 (17) + Para x4 (20) + VitC x4 (26) + Loratadina x... 63+2 = nope.
    -- F0030 final: Ibu x4 (34) + VitC x... 34+31 con vit C? 6.5*x = 31 nope.
    -- Voy con: Ibu x4 (34) + Para x4 (20) + VitC x... = 54+11 con loratadina? 14 nope. + Loratadina x1 (7) = 61. cerca de 65.
    -- F0030 = Ibu x4 (34) + Para x4 (20) + Loratadina x1 (7) + VitC x... = 61+4. Hmm.
    -- Decision: F0030 = Ibu x4 (34) + Para x4 (20) + VitC x... 54+11 -> bajo el numero. cambio total factura a 61: Ibu x4 + Para x4 + Loratadina x1 = 34+20+7=61.
    -- Re-edit factura: NO, ya escribi 65. Voy a hacer F0030 con: Ibu x4 (34) + Para x4 (20) + VitC x... = 54+ 11 nope.
    -- Pragmatica: F0030 = Para x13 (65). Stock paracetamol ya planeado: 60 unidades. Si vendo 13 mas, pasa de 60 a 73 → me paso del presupuesto.
    -- Re-aumento stock paracetamol vendido a 73 (era 60). Actualizo plan.
    -- OK F0030 = Para x13 = 65.
    ('dddd0037-dddd-0037-dddd-000000000037', 'ffff0030-ffff-0030-ffff-000000000030', 'cccc1111-cccc-1111-cccc-111111111111', 'dddd1111-dddd-1111-dddd-111111111111', NULL, 13, 5.00,  65.00)
ON CONFLICT (id) DO NOTHING;

-- Actualizar subtotales/totales de las facturas que tuvieron ajustes manuales arriba:
-- F0002: 21.50 (3 para + 1 vitC)
-- F0008: 27.00 (2 lora + 2 vitC)
-- F0019: 26.50 (4 para + 1 vitC)
-- F0023: 23.50 (1 vitC + 1 lora + 2 para)  -- ya estaba correcto
-- F0026: 19.50 (3 vitC)
-- F0029: 25.00 ANULADA -- ya estaba

UPDATE factura SET subtotal = 21.50, total = 21.50 WHERE id = 'ffff0002-ffff-0002-ffff-000000000002';
UPDATE factura SET subtotal = 27.00, total = 27.00 WHERE id = 'ffff0008-ffff-0008-ffff-000000000008';
UPDATE factura SET subtotal = 26.50, total = 26.50 WHERE id = 'ffff0019-ffff-0019-ffff-000000000019';
UPDATE factura SET subtotal = 19.50, total = 19.50 WHERE id = 'ffff0026-ffff-0026-ffff-000000000026';


-- ============================================================================
-- PARTE 5 — MOVIMIENTOS DE INVENTARIO (SALIDA por cada detalle de factura PAGADA)
-- ============================================================================
-- Solo facturas PAGADA descuentan stock. Las ANULADAS y PENDIENTE no.
-- usuario_id = cajero de la factura. Fecha = fecha factura.

INSERT INTO movimiento_inventario (id, lote_id, tipo, cantidad, motivo, usuario_id, fecha)
SELECT
    -- ID generado deterministico desde el detalle id
    ('bbbb0000-bbbb-0000-bbbb-' || lpad(row_number() OVER (ORDER BY df.id)::text, 12, '0'))::uuid AS id,
    df.lote_id,
    'SALIDA'::tipo_movimiento_enum,
    df.cantidad,
    'Venta ' || f.numero,
    f.usuario_id,
    f.fecha
FROM detalle_factura df
JOIN factura f ON f.id = df.factura_id
WHERE f.estado = 'PAGADA'
  AND df.id IN (SELECT id FROM detalle_factura WHERE id::text LIKE 'dddd%')  -- solo los del seed
  AND NOT EXISTS (
      SELECT 1 FROM movimiento_inventario mi
      WHERE mi.lote_id = df.lote_id
        AND mi.tipo = 'SALIDA'
        AND mi.motivo = 'Venta ' || f.numero
        AND mi.fecha = f.fecha
        AND mi.cantidad = df.cantidad
  )
ORDER BY df.id;


-- ============================================================================
-- PARTE 6 — RECALCULAR cantidad_actual de los lotes basado en movimientos
-- ============================================================================
-- Idempotente: cantidad_actual = cantidad_inicial - SUM(SALIDA) + SUM(ENTRADA extra) + SUM(AJUSTE)
-- Nota: V4 ya genero los ENTRADA iniciales (motivo='Carga inicial de seed')
-- pero solo afectan el stock si descontamos correctamente las SALIDA.
-- La formula simple: cantidad_actual = cantidad_inicial - SUM(SALIDA por ese lote).

UPDATE lote l
SET cantidad_actual = GREATEST(
    l.cantidad_inicial - COALESCE(
        (SELECT SUM(m.cantidad)
         FROM movimiento_inventario m
         WHERE m.lote_id = l.id
           AND m.tipo = 'SALIDA'),
        0
    ),
    0
);


-- ============================================================================
-- FIN V5
-- ============================================================================
