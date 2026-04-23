-- =====================================================================
-- FeRReT — Índices y análisis de performance
-- Base de Datos III — Proyecto Integrador, Parte 1
-- =====================================================================
-- Responsable: Stream C (Indexación & Performance)
--
-- Orden sugerido para completar este archivo:
--   1. Correr 01_schema.sql (DDL base).
--   2. Correr 03_seed.sql (cargar ≥ 1M registros).
--   3. VACUUM ANALYZE; para refrescar estadísticas.
--   4. Elegir una consulta representativa y correr EXPLAIN ANALYZE
--      ANTES de crear los índices. Guardar el plan.
--   5. Crear los índices de abajo.
--   6. VACUUM ANALYZE; otra vez.
--   7. Correr EXPLAIN ANALYZE DESPUÉS. Guardar el plan.
--   8. Exportar ambos planes a Dalibo / PEV2 → docs/dalibo/
--   9. Documentar todo en docs/performance.md
-- =====================================================================

-- ---------------------------------------------------------------------
-- B-Tree  — búsquedas por rango / igualdad sobre columnas numéricas,
--          fechas y FKs más consultadas.
-- ---------------------------------------------------------------------

-- TODO: CREATE INDEX idx_venta_fecha           ON venta (fecha_venta);
-- TODO: CREATE INDEX idx_venta_cliente         ON venta (cliente_id);
-- TODO: CREATE INDEX idx_venta_sucursal_fecha  ON venta (sucursal_id, fecha_venta);
-- TODO: CREATE INDEX idx_venta_linea_sku       ON venta_linea (sku_id);
-- TODO: CREATE INDEX idx_movimiento_fecha      ON movimiento_stock (fecha);
-- TODO: CREATE INDEX idx_empleado_supervisor   ON empleado (supervisor_id);
-- TODO: CREATE INDEX idx_categoria_padre       ON categoria (padre_id);

-- ---------------------------------------------------------------------
-- Hash  — igualdad exacta sobre columnas de texto largo.
-- ---------------------------------------------------------------------

-- TODO: CREATE INDEX idx_cliente_email_hash    ON cliente  USING HASH (email);
-- TODO: CREATE INDEX idx_sku_codbarras_hash    ON sku      USING HASH (codigo_barras);

-- ---------------------------------------------------------------------
-- GIN  — búsqueda de atributos dentro del JSONB de producto.
--        Ejemplo de query: WHERE atributos @> '{"material":"acero"}'
--        Con jsonb_path_ops el índice es más chico y más rápido para @>.
-- ---------------------------------------------------------------------

-- TODO: CREATE INDEX idx_producto_atributos_gin
--         ON producto USING GIN (atributos jsonb_path_ops);

-- ---------------------------------------------------------------------
-- GiST  — rangos con EXCLUDE para evitar solapamientos.
--         Las exclusiones ya están declaradas en 01_schema.sql
--         (alquiler.ventana, promocion.vigencia) y PostgreSQL crea
--         el índice GiST automáticamente por el EXCLUDE USING GIST.
--         Si hiciera falta un GiST adicional solo para búsqueda
--         (sin constraint), agregarlo acá.
-- ---------------------------------------------------------------------

-- TODO (opcional, si la consulta de "alquileres activos ahora" lo pide):
-- CREATE INDEX idx_alquiler_ventana_gist ON alquiler USING GIST (ventana);

-- =====================================================================
-- Consultas de ejemplo para medir (copiar a 04_queries.sql o a mano):
-- =====================================================================
--
-- [A] Productos de acero con medida 8mm (GIN):
--   SELECT * FROM producto WHERE atributos @> '{"material":"acero","medida":"8mm"}';
--
-- [B] Ventas del último mes en sucursal X (B-Tree compuesto):
--   SELECT * FROM venta
--    WHERE sucursal_id = 3
--      AND fecha_venta >= NOW() - INTERVAL '30 days';
--
-- [C] Alquileres activos ahora (GiST):
--   SELECT * FROM alquiler WHERE ventana @> NOW()::timestamp;
--
-- [D] Buscar cliente por email (Hash):
--   SELECT * FROM cliente WHERE email = 'foo@bar.com';
-- =====================================================================
