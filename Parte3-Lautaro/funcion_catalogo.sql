CREATE OR REPLACE FUNCTION catalogo_productos()
RETURNS TABLE (
	id_producto INTEGER,
	nombre VARCHAR,
	categoria VARCHAR,
	marca VARCHAR,
	id_sku INTEGER,
	codigo_barras VARCHAR,
	descripcion_variante VARCHAR,
	precio_unitario NUMERIC(12,2),
	unidad_medida VARCHAR,
	peso_gramos INTEGER,
	stock_total BIGINT,
	sku_activo BOOLEAN,
	producto_activo BOOLEAN
) AS $$
BEGIN
	RETURN QUERY 
	SELECT 
		p.id AS id_producto,
		p.nombre,
		c.nombre AS categoria,
		m.nombre AS marca,
		s.id AS id_sku,
		s.codigo_barras,
		s.descripcion_variante,
		s.precio_unitario,
		s.unidad_medida,
		s.peso_gramos,
		COALESCE(st.stock_total, 0) AS stock_total,
		s.activo AS sku_activo,
		p.activo AS producto_activo
	FROM producto p
	LEFT JOIN categoria c ON p.categoria_id = c.id
	LEFT JOIN marca m ON p.marca_id = m.id
	LEFT JOIN sku s ON p.id = s.producto_id
	LEFT JOIN (SELECT sku_id, SUM(cantidad) AS stock_total
		FROM stock
		GROUP BY sku_id
	) st ON s.id = st.sku_id
	ORDER BY p.nombre, s.descripcion_variante;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM catalogo_productos();

CREATE INDEX idx_producto_categoria_id ON producto(categoria_id);
CREATE INDEX idx_producto_marca_id ON producto(marca_id);
CREATE INDEX idx_sku_producto_id ON sku(producto_id);
CREATE INDEX idx_stock_sku_id ON stock(sku_id);
CREATE INDEX idx_stock_sku_cantidad ON stock(sku_id, cantidad);