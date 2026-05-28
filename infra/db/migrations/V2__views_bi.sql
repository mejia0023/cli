-- ============================================================================
-- V2__views_bi.sql — Vistas SQL para el Dashboard BI
-- ============================================================================
-- Cada vista alimenta un panel del dashboard (solo rol ADMINISTRADOR).
-- ============================================================================

-- 1. Ventas por dia (line chart)
CREATE OR REPLACE VIEW vw_ventas_diarias AS
SELECT
    DATE(fecha)                                     AS dia,
    COUNT(*)                                        AS num_facturas,
    COALESCE(SUM(total), 0)                         AS total_vendido,
    COALESCE(AVG(total), 0)::NUMERIC(12,2)          AS ticket_promedio
FROM factura
WHERE estado = 'PAGADA'
GROUP BY DATE(fecha)
ORDER BY dia DESC;

-- 2. Top medicamentos mas vendidos (bar chart horizontal)
CREATE OR REPLACE VIEW vw_top_medicamentos AS
SELECT
    m.id                                            AS medicamento_id,
    m.nombre                                        AS medicamento,
    SUM(df.cantidad)                                AS unidades_vendidas,
    SUM(df.subtotal)                                AS monto_total,
    COUNT(DISTINCT df.factura_id)                   AS num_facturas
FROM detalle_factura df
JOIN medicamento m ON m.id = df.medicamento_id
JOIN factura f     ON f.id = df.factura_id AND f.estado = 'PAGADA'
GROUP BY m.id, m.nombre
ORDER BY unidades_vendidas DESC;

-- 3. Inventario critico (tabla con badges)
CREATE OR REPLACE VIEW vw_inventario_critico AS
SELECT
    m.id                                            AS medicamento_id,
    m.nombre                                        AS medicamento,
    m.stock_minimo,
    COALESCE(SUM(l.cantidad_actual), 0)             AS stock_actual,
    CASE
        WHEN COALESCE(SUM(l.cantidad_actual), 0) = 0                    THEN 'SIN_STOCK'
        WHEN COALESCE(SUM(l.cantidad_actual), 0) <= m.stock_minimo      THEN 'CRITICO'
        WHEN COALESCE(SUM(l.cantidad_actual), 0) <= m.stock_minimo * 2  THEN 'BAJO'
        ELSE 'OK'
    END                                             AS nivel
FROM medicamento m
LEFT JOIN lote l ON l.medicamento_id = m.id
WHERE m.activo = TRUE
GROUP BY m.id, m.nombre, m.stock_minimo
ORDER BY stock_actual ASC;

-- 4. Recetas registradas en blockchain por mes (stacked bar)
CREATE OR REPLACE VIEW vw_recetas_blockchain AS
SELECT
    DATE_TRUNC('month', fecha_emision)::DATE        AS mes,
    COUNT(*)                                        AS total_recetas,
    COUNT(blockchain_tx)                            AS registradas_en_blockchain,
    COUNT(*) FILTER (WHERE controlado = TRUE)       AS controladas,
    COUNT(*) FILTER (WHERE estado = 'DISPENSADA')   AS dispensadas
FROM receta
GROUP BY DATE_TRUNC('month', fecha_emision)
ORDER BY mes DESC;
