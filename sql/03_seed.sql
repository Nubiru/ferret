
-- =========================================================
-- 1. SUCURSALES (6)
-- =========================================================
INSERT INTO sucursal (nombre, direccion, ciudad, provincia, fecha_apertura)
SELECT 
    'Sucursal ' || i,
    'Calle ' || i,
    'Ciudad ' || i,
    'Provincia',
    CURRENT_DATE - (i * 30)
FROM generate_series(1, 6) i;

-- =========================================================
-- 2. CAMIONES (15)
-- =========================================================
INSERT INTO camion (patente, modelo, capacidad_kg, ano_fabricacion)
SELECT 
    'AAA' || i,
    'Modelo ' || i,
    (1000 + random()*5000)::int,
    (2000 + random()*20)::int
FROM generate_series(1, 15) i;

-- =========================================================
-- 3. CARGOS
-- =========================================================
INSERT INTO cargo (nombre, familia, salario_base) VALUES
('CEO','ejecutivo',1000000),
('Gerente','ejecutivo',700000),
('Vendedor','venta',300000),
('Administrativo','administrativo',250000),
('Chofer','transporte',280000);

-- =========================================================
-- 4. EMPLEADOS (~200)
-- =========================================================
INSERT INTO empleado (dni, nombre, apellido, email, fecha_ingreso, cargo_id, sucursal_id, supervisor_id)
SELECT
    'DNI' || i,
    'Nombre' || i,
    'Apellido' || i,
    'emp' || i || '@mail.com',
    CURRENT_DATE - (random()*1000)::int,
    (1 + random()*4)::int,
    (1 + random()*5)::int,
    NULL
FROM generate_series(1, 200) i;

-- =========================================================
-- 5. MARCAS (100)
-- =========================================================
INSERT INTO marca (nombre)
SELECT 'Marca ' || i
FROM generate_series(1, 100) i;

-- =========================================================
-- 6. CATEGORIAS (simples)
-- =========================================================
INSERT INTO categoria (nombre)
SELECT 'Categoria ' || i
FROM generate_series(1, 50) i;

-- =========================================================
-- 7. PRODUCTOS (30k)
-- =========================================================
INSERT INTO producto (nombre, categoria_id, marca_id, atributos)
SELECT 
    'Producto ' || i,
    (1 + random()*49)::int,
    (1 + random()*99)::int,
    jsonb_build_object(
        'color', (ARRAY['rojo','negro','azul'])[floor(random()*3)+1],
        'material', (ARRAY['acero','plastico'])[floor(random()*2)+1]
    )
FROM generate_series(1, 30000) i;

-- =========================================================
-- 8. SKU (80k)
-- =========================================================
INSERT INTO sku (producto_id, codigo_barras, descripcion_variante, precio_unitario, unidad_medida)
SELECT
    (1 + random()*29999)::int,
    'CB' || i,
    'Variante ' || i,
    (random()*1000)::numeric(10,2),
    'unidad'
FROM generate_series(1, 80000) i;

-- =========================================================
-- 9. STOCK (~480k)
-- =========================================================
INSERT INTO stock (sku_id, sucursal_id, cantidad)
SELECT s.id, suc.id, (random()*500)::int
FROM sku s CROSS JOIN sucursal suc;

-- =========================================================
-- 10. CLIENTES (100k)
-- =========================================================
INSERT INTO cliente (tipo_cliente, nombre, email)
SELECT 
    'minorista',
    'Cliente ' || i,
    'cliente' || i || '@mail.com'
FROM generate_series(1, 100000) i;

-- =========================================================
-- 11. VENTAS (200k)
-- =========================================================
INSERT INTO venta (cliente_id, empleado_vendedor_id, sucursal_id, fecha_venta, tipo_venta, total, medio_pago)
SELECT
    (1 + random()*99999)::int,
    (1 + random()*199)::int,
    (1 + random()*5)::int,
    NOW() - (random()*730)::int * INTERVAL '1 day',
    'minorista',
    (random()*10000)::numeric(10,2),
    'efectivo'
FROM generate_series(1, 200000) i;

-- =========================================================
-- 12. VENTA_LINEA (600k)
-- =========================================================
INSERT INTO venta_linea (venta_id, sku_id, cantidad, precio_unitario, subtotal)
SELECT
    (1 + random()*199999)::int,
    (1 + random()*79999)::int,
    (1 + random()*10)::int,
    (random()*1000)::numeric(10,2),
    (random()*10000)::numeric(10,2)
FROM generate_series(1, 600000) i;

-- =========================================================
-- 13. MOVIMIENTO STOCK (150k)
-- =========================================================
INSERT INTO movimiento_stock (sku_id, sucursal_id, tipo, cantidad, fecha)
SELECT
    (1 + random()*79999)::int,
    (1 + random()*5)::int,
    'salida_venta',
    (random()*10)::int,
    NOW() - (random()*365)::int * INTERVAL '1 day'
FROM generate_series(1, 150000) i;

COMMIT;

VACUUM ANALYZE;