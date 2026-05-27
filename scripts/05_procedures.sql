-- =========================================================
-- PARTE A - ABSTRACCION Y LOGICA PROCEDURAL
-- Proyecto Integrador - FerreT
-- =========================================================

-- =========================================================
-- A.1 FUNCION IMMUTABLE
-- =========================================================

CREATE OR REPLACE FUNCTION calcular_subtotal(
    p_cantidad INTEGER,
    p_precio_unitario NUMERIC,
    p_descuento_pct NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN p_cantidad * p_precio_unitario * (1 - p_descuento_pct / 100);
END;
$$;


-- =========================================================
-- A.2 + A.3 PROCEDIMIENTO PRINCIPAL
-- Uso de %TYPE, %ROWTYPE y RECORD
-- =========================================================

CREATE OR REPLACE PROCEDURE registrar_venta_simple(
    p_cliente_id INTEGER,
    p_empleado_id INTEGER,
    p_sucursal_id INTEGER,
    p_sku_id INTEGER,
    p_cantidad INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE

    -- %TYPE
    v_precio sku.precio_unitario%TYPE;
    v_stock_actual stock.cantidad%TYPE;
    v_total venta.total%TYPE;

    -- %ROWTYPE
    v_sku sku%ROWTYPE;

BEGIN

    -- Obtener datos del SKU
    SELECT *
    INTO v_sku
    FROM sku
    WHERE id = p_sku_id;

    -- Validar existencia
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El SKU no existe';
    END IF;

    v_precio := v_sku.precio_unitario;

    -- Obtener stock actual
    SELECT cantidad
    INTO v_stock_actual
    FROM stock
    WHERE sku_id = p_sku_id
      AND sucursal_id = p_sucursal_id;

    -- Validar stock
    IF v_stock_actual < p_cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente';
    END IF;

    -- Calcular total usando la funcion IMMUTABLE
    v_total := calcular_subtotal(
        p_cantidad,
        v_precio,
        0
    );

    -- Crear venta
    INSERT INTO venta (
        cliente_id,
        empleado_vendedor_id,
        sucursal_id,
        fecha_venta,
        tipo_venta,
        total,
        medio_pago
    )
    VALUES (
        p_cliente_id,
        p_empleado_id,
        p_sucursal_id,
        NOW(),
        'MOSTRADOR',
        v_total,
        'EFECTIVO'
    );

    -- Descontar stock
    UPDATE stock
    SET cantidad = cantidad - p_cantidad,
        ultima_actualizacion = NOW()
    WHERE sku_id = p_sku_id
      AND sucursal_id = p_sucursal_id;

END;
$$;