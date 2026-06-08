-- =====================================================================
-- FeRReT — Automatización con Triggers (Parte 2, Eje I)
-- Base de Datos III — Proyecto Integrador
-- =====================================================================

-- 1. DEFINICIÓN DE LA TABLA OBJETIVO Y SINCRONIZACIÓN TEMPORAL
-- Tabla objetivo: venta_linea
-- Tipo de trigger: AFTER INSERT
-- Se ejecuta después de insertar la línea de venta para garantizar que la venta exista antes de modificar el stock.

-- 2. CREACIÓN DE LA FUNCIÓN ASOCIADA AL TRIGGER
CREATE OR REPLACE FUNCTION descontar_stock_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_sucursal_id INTEGER;
BEGIN
    -- Obtener la sucursal donde se realizó la venta
    SELECT sucursal_id
    INTO v_sucursal_id
    FROM venta
    WHERE id = NEW.venta_id;

    -- Descontar stock
    UPDATE stock
    SET cantidad = cantidad - NEW.cantidad,
        ultima_actualizacion = NOW()
    WHERE sku_id = NEW.sku_id
      AND sucursal_id = v_sucursal_id;

    -- Registrar movimiento de stock
    INSERT INTO movimiento_stock
        (sku_id, sucursal_id, tipo, cantidad, fecha)
    VALUES
        (NEW.sku_id,
         v_sucursal_id,
         'VENTA',
         NEW.cantidad,
         NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. SENTENCIA CREATE TRIGGER
CREATE TRIGGER trg_descontar_stock_venta
AFTER INSERT
ON venta_linea
FOR EACH ROW
EXECUTE FUNCTION descontar_stock_venta();


-- =====================================================================
-- VERIFICACIÓN CON EVENTOS DML
-- Nota: Para evitar errores de clave foránea (FK), primero insertamos los 
-- registros base necesarios (sucursal, cliente, empleado, producto, sku) 
-- y luego ejecutamos las consultas de verificación provistas.
-- =====================================================================

/*

-- A. PREPARACIÓN (Garantizar integridad referencial para el ID 1)
-- -------------------------------------------------------------
INSERT INTO sucursal (id, nombre, direccion, ciudad, provincia, activa, fecha_apertura)
VALUES (1, 'Sucursal Central', 'Av. Colón 100', 'Córdoba', 'Córdoba', true, '2026-01-01')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cargo (id, nombre, familia, salario_base)
VALUES (1, 'Vendedor Inicial', 'Ventas', 45000.00)
ON CONFLICT (id) DO NOTHING;

INSERT INTO empleado (id, dni, nombre, apellido, email, fecha_ingreso, cargo_id, sucursal_id)
VALUES (1, '99999999', 'Administrador', 'Sistema', 'admin@ferret.com', '2026-01-01', 1, 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO cliente (id, tipo_cliente, nombre, email, activo)
VALUES (1, 'MINORISTA', 'Cliente Genérico', 'cliente1@ferret.com', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO categoria (id, nombre)
VALUES (1, 'Ferretería General')
ON CONFLICT (id) DO NOTHING;

INSERT INTO marca (id, nombre)
VALUES (1, 'Marca Genérica')
ON CONFLICT (id) DO NOTHING;

INSERT INTO producto (id, nombre, categoria_id, marca_id)
VALUES (1, 'Producto Genérico de Prueba', 1, 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO sku (id, producto_id, codigo_barras, descripcion_variante, precio_unitario, unidad_medida, peso_gramos)
VALUES (1, 1, '7790000000001', 'Variante Estándar', 1000.00, 'UNIDAD', 100)
ON CONFLICT (id) DO NOTHING;


-- B. DATOS INICIALES DE STOCK
-- ---------------------------
-- Insertamos 100 unidades en stock para el SKU 1 en la sucursal 1.
INSERT INTO stock
(sku_id, sucursal_id, cantidad, stock_minimo)
VALUES
(1, 1, 100, 10)
ON CONFLICT (sku_id, sucursal_id) DO UPDATE 
SET cantidad = 100, stock_minimo = 10;


-- C. CREAR UNA VENTA
-- ------------------
-- Registramos la venta con ID 1
INSERT INTO venta
(id, cliente_id, empleado_vendedor_id, sucursal_id, fecha_venta, tipo_venta, total, medio_pago)
VALUES
(1, 1, 1, 1, NOW(), 'MINORISTA', 5000, 'EFECTIVO')
ON CONFLICT (id) DO NOTHING;


-- D. AGREGAR UNA LÍNEA DE VENTA (Activa el Trigger)
-- ------------------------------------------------
-- Insertamos una línea de venta de 5 unidades. 
-- El trigger trg_descontar_stock_venta se disparará AFTER INSERT.
INSERT INTO venta_linea
(venta_id, sku_id, cantidad, precio_unitario, subtotal)
VALUES
(1, 1, 5, 1000, 5000);


-- E. VERIFICAR STOCK Y MOVIMIENTO
-- -------------------------------
-- 1. Consultar el stock. Debería haber bajado de 100 a 95 (100 - 5).
SELECT *
FROM stock
WHERE sku_id = 1
  AND sucursal_id = 1;

-- 2. Consultar el movimiento de stock. Debería registrar el egreso de 5 unidades por 'VENTA'.
SELECT *
FROM movimiento_stock
WHERE sku_id = 1
  AND sucursal_id = 1;


-- F. LIMPIEZA (Opcional, para reiniciar la prueba)
-- ------------------------------------------------
-- DELETE FROM venta_linea WHERE venta_id = 1 AND sku_id = 1;
-- DELETE FROM venta WHERE id = 1;
-- DELETE FROM stock WHERE sku_id = 1 AND sucursal_id = 1;

*/
