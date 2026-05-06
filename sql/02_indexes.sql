-- =====================================================================
-- FeRReT — Índices y análisis de performance
-- Base de Datos III — Proyecto Integrador, Parte 1
-- =====================================================================
--
-- B-TREE
CREATE INDEX idx_venta_fecha ON venta (fecha_venta);
CREATE INDEX idx_venta_cliente ON venta (cliente_id);
CREATE INDEX idx_venta_sucursal_fecha ON venta (sucursal_id, fecha_venta);
CREATE INDEX idx_venta_linea_sku ON venta_linea (sku_id);
CREATE INDEX idx_movimiento_fecha ON movimiento_stock (fecha);
CREATE INDEX idx_empleado_supervisor ON empleado (supervisor_id);
CREATE INDEX idx_categoria_padre ON categoria (padre_id);

-- HASH
CREATE INDEX idx_cliente_email_hash ON cliente USING HASH (email);
CREATE INDEX idx_sku_codbarras_hash ON sku USING HASH (codigo_barras);

-- GIN
CREATE INDEX idx_producto_atributos_gin
ON producto USING GIN (atributos jsonb_path_ops);


-- =========================================================
-- FIN
-- =========================================================