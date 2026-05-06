BEGIN;

-- 1. Sucursales (5 sucursales + 1 depósito central)
INSERT INTO sucursal (nombre, direccion, ciudad, provincia, telefono, es_deposito_central, fecha_apertura, activa) VALUES
('Casa Central', 'Av. Vélez Sarsfield 1234', 'Córdoba', 'Córdoba', '0351-412-3456', FALSE, '2010-03-15', TRUE),
('Sucursal Capital Norte', 'Av. Recta Martinolli 5678', 'Córdoba', 'Córdoba', '0351-478-1234', FALSE, '2012-07-22', TRUE),
('Depósito Central', 'Ruta 9 km 45, Parque Industrial', 'Córdoba', 'Córdoba', '0351-456-7890', TRUE, '2010-03-15', TRUE),
('Sucursal Punilla', 'Av. Illia 456', 'Carlos Paz', 'Córdoba', '03541-44-5566', FALSE, '2015-11-10', TRUE),
('Sucursal Río Cuarto', 'Av. Sabattini 234', 'Río Cuarto', 'Córdoba', '0358-422-7788', FALSE, '2011-06-15', TRUE),
('Sucursal Villa María', 'Bv. Italia 567', 'Villa María', 'Córdoba', '0353-452-9900', FALSE, '2016-09-30', TRUE);
-- SELECT * FROM sucursal;

-- 2. Camiones (15)
INSERT INTO camion (patente, modelo, capacidad_kg, ano_fabricacion, activo) VALUES
('AB123CD', 'Mercedes Benz 1718', 8000, 2018, TRUE),
('EF456GH', 'Volkswagen Constellation 17.280', 7500, 2019, TRUE),
('IJ789KL', 'Scania R440', 12000, 2020, TRUE),
('MN012OP', 'Iveco Daily 70C', 3500, 2017, TRUE),
('QR345ST', 'Ford Cargo 815', 5000, 2020, TRUE),
('UV678WX', 'Mercedes Benz 1722', 10000, 2021, TRUE),
('YZ901AB', 'Volvo FH 460', 15000, 2019, TRUE),
('CD234EF', 'Renault Master 3.5', 3500, 2018, TRUE),
('GH567IJ', 'Volkswagen Delivery Express', 6000, 2022, TRUE),
('KL890MN', 'Scania P320', 9000, 2020, TRUE),
('OP123QR', 'Iveco Stralis 440', 13000, 2021, TRUE),
('ST456UV', 'Ford F-4000', 7000, 2017, TRUE),
('WX789YZ', 'Mercedes Benz Atego 1725', 7500, 2019, TRUE),
('AB321CD', 'Volkswagen Meteor 28.460', 18000, 2022, TRUE),
('EF654GH', 'Hyundai HD 120', 5500, 2020, TRUE);
SELECT * FROM camion;

-- Con generate series
-- INSERT INTO camion (patente, modelo, capacidad_kg, ano_fabricacion, activo)
-- SELECT 'AB' || LPAD(i::TEXT, 3, '0') || 'CD', 'Mercedes-Benz Atron', 1000 + (i*150), 2010 + (i%12), TRUE
-- FROM generate_series(1, 15) i;

-- 3. Cargos (15)
INSERT INTO cargo (nombre, familia, salario_base) VALUES
('CEO', 'ejecutivo', 5000000),
('Gerente General', 'ejecutivo', 3500000),
('Gerente de Sucursal', 'ejecutivo', 2800000),
('Gerente de Ventas', 'ejecutivo', 2500000),
('Jefe de Logística', 'transporte', 2200000),
('Supervisor de Depósito', 'administrativo', 1800000),
('Vendedor Sr', 'venta', 1500000),
('Vendedor', 'venta', 1200000),
('Cajero', 'caja', 1100000),
('Administrativo', 'administrativo', 1300000),
('Comprador', 'adquisicion', 1600000),
('Chofer', 'transporte', 1700000),
('Guardia de Seguridad', 'guardia', 1000000),
('Auxiliar de Depósito', 'administrativo', 1150000),
('Encargado de Alquileres', 'venta', 1400000);
-- SELECT * FROM cargo;

-- 4. Empleados (200)
INSERT INTO empleado (dni, nombre, apellido, email, fecha_ingreso, cargo_id, sucursal_id, supervisor_id) VALUES
('34125870', 'Matias', 'Escachofa', 'maticho@ferret.com', '2010-01-22', (SELECT id FROM cargo WHERE nombre='CEO'), NULL, NULL);

-- Supervisores
WITH ceo AS (SELECT id FROM empleado WHERE email='maticho@ferret.com') 
INSERT INTO empleado (dni, nombre, apellido, email, fecha_ingreso, cargo_id, sucursal_id, supervisor_id)
SELECT 
	'30' || (100000 + i)::text,
	CASE (i % 4)
		WHEN 0 THEN 'Martina' 
		WHEN 1 THEN 'Tomas'
		WHEN 2 THEN 'Amelia'
		ELSE 'Rodrigo'
	END,
	CASE (i % 4)
		WHEN 0 THEN 'Gonzalez'
		WHEN 1 THEN 'Buscagglia'
		WHEN 2 THEN 'Mercedes'
		ELSE 'Romero'
	END,
	'gerente_' || i || '@ferret.com',
	'2010-06-01'::date + (i * 33),
	CASE (FLOOR(RANDOM() * 3))::int
		WHEN 0 THEN (SELECT id FROM cargo WHERE nombre='Gerente General')
		WHEN 1 THEN (SELECT id FROM cargo WHERE nombre='Gerente de Sucursal')
		ELSE (SELECT id FROM cargo WHERE nombre='Gerente de Ventas')
	END,
	CASE
		WHEN i=1 THEN NULL
		ELSE (1 + FLOOR(RANDOM() * 6))::int
	END,
	(SELECT id FROM ceo)
FROM generate_series(1, 10) i;

-- Otros empleados
DO $$
DECLARE
    sup RECORD;
    base_id integer;
    cargo_id integer;
    suc_id integer;
	nombres text[] := array['Camila','Fernando','Brenda','Elian','Adriana','Martin','Josefina','Pedro','Silvia','Maximo'];
    apellidos text[] := array['Escalante','Campos','Bazan','Dávila','Ceballos','Herrera','Reinoso','Blanco','Alpes','Quinteros'];
BEGIN
    FOR i IN 1..189 LOOP
        SELECT id, sucursal_id INTO sup FROM empleado WHERE id BETWEEN 2 AND 11 ORDER BY RANDOM() LIMIT 1;
        
        IF i % 10 = 0 THEN
            cargo_id := (SELECT id FROM cargo WHERE familia='transporte' ORDER BY RANDOM() LIMIT 1);
        ELSIF i % 7 = 0 THEN
            cargo_id := (SELECT id FROM cargo WHERE familia='guardia' LIMIT 1);
        ELSIF i % 5 = 0 THEN
            cargo_id := (SELECT id FROM cargo WHERE familia='adquisicion' LIMIT 1);
        ELSIF i % 3 = 0 THEN
            cargo_id := (SELECT id FROM cargo WHERE nombre IN ('Vendedor', 'Vendedor Sr', 'Encargado de Alquileres') ORDER BY RANDOM() LIMIT 1);
        ELSE
            cargo_id := (SELECT id FROM cargo WHERE familia='administrativo' ORDER BY RANDOM() LIMIT 1);
        END IF;
        
        suc_id := sup.sucursal_id;
        IF suc_id IS NULL 
		THEN suc_id := 1; 
		END IF;
        
        INSERT INTO empleado (dni, nombre, apellido, email, fecha_ingreso, cargo_id, sucursal_id, supervisor_id)
        VALUES (
            '40' || (199999 + i)::text,
			nombres[1 + FLOOR(RANDOM() * array_length(nombres, 1))::int],
			apellidos[1 + FLOOR(RANDOM() * array_length(apellidos, 1))::int],
            'empleado_' || i || '_' || MD5(i::text) || '@ferret.com',
            '2012-01-01'::date + (i % 3000),
            cargo_id,
            suc_id,
            sup.id
        );
    END LOOP;
END $$;

-- SELECT * FROM empleado;

-- 5. Marcas 
INSERT INTO marca (nombre) SELECT 'Marca ' || i FROM generate_series(1, 100) i;
-- SELECT * FROM marca;

-- 6. Categorías (140 - jerarquía simple)
INSERT INTO categoria (nombre, padre_id) SELECT 'Cat_' || i, NULL FROM generate_series(1, 10) i;
INSERT INTO categoria (nombre, padre_id) SELECT 'Subcat_' || i, (SELECT id FROM categoria WHERE padre_id IS NULL ORDER BY RANDOM()* i LIMIT 1)
FROM generate_series(1, 140) i;
-- SELECT * FROM categoria;


-- 7. Productos (5.000) --> queda por modificar el estado
INSERT INTO producto (nombre, categoria_id, marca_id, descripcion_larga, atributos, activo, fecha_alta)
SELECT 
	'Producto ' || i,
	 (SELECT id FROM categoria WHERE id BETWEEN 11 AND 150 ORDER BY RANDOM() * i LIMIT 1),
     (SELECT id FROM marca ORDER BY RANDOM() * i LIMIT 1),
     'Descripción ' || i,
     jsonb_build_object('material', (array['acero','plástico','madera'])[floor(random()*3)+1],
                          'medida', (array['5cm','10cm','15cm'])[floor(random()*3)+1],
                          'color', (array['rojo','verde','azul'])[floor(random()*3)+1]),
     CASE WHEN RANDOM() < 0.10 THEN FALSE ELSE TRUE END,
	 NOW() - (RANDOM() * interval '3 years')
FROM generate_series(1, 5000) i;
-- SELECT * FROM producto;

-- 8. SKUs (15.000) --> lógica de la columna "activo" de productos y sku no conectada
INSERT INTO sku (producto_id, codigo_barras, descripcion_variante, precio_unitario, unidad_medida, peso_gramos, activo)
SELECT 
	(SELECT id FROM producto ORDER BY RANDOM() * i LIMIT 1),
	LPAD(i::text, 13, '0'),
	'Descripción ' || i,
	ROUND((RANDOM() * 5000 + 10)::numeric, 2),
	(array['unidad','kg','metro','caja'])[FLOOR(RANDOM() * 4)+ 1],
	(RANDOM() * 5000)::integer,
	CASE WHEN RANDOM() < 0.10 THEN FALSE ELSE TRUE END
FROM generate_series(1, 15000) i;

SELECT * FROM sku;

-- 9. Stock (90.000 = 15k SKUs × 6 sucursales)
INSERT INTO stock (sku_id, sucursal_id, cantidad, stock_minimo, ultima_actualizacion)
SELECT 
	s.id,
	suc.id, 
	(RANDOM() * 300)::integer, 
	(RANDOM() * 15)::integer, 
	NOW() - (RANDOM() * interval '30 days')
FROM sku s CROSS JOIN sucursal suc LIMIT 90000;
-- SELECT * FROM stock;

-- 10. Proveedores (200)
INSERT INTO proveedor (razon_social, cuit, email, telefono, direccion, activo)
SELECT 
	'Proveedor ' || i, 
	 LPAD((30000000000 + i)::text, 11, '0'), 'prov'||i||'@mail.com',
    '0351 ' || LPAD((RANDOM() * 9999999)::integer::text, 7, '0'), 
	'Dirección ' || i, 
	TRUE
FROM generate_series(1, 200) i;
-- SELECT * FROM proveedor;

-- 11. Clientes (200.000)
INSERT INTO cliente (tipo_cliente, nombre, email, telefono, direccion, ciudad, cuit, razon_social, limite_credito, fecha_alta, activo)
WITH datos AS (
    SELECT 
        CASE WHEN RANDOM() < 0.7 THEN 'minorista' ELSE 'mayorista' END AS tipo,
        i,
        '0351' || LPAD((RANDOM() * 9999999)::integer::text, 7, '0') AS telefono,
        'Calle ' || (RANDOM() * 5000)::integer AS direccion,
        (array['Córdoba Capital', 'Villa Carlos Paz', 'Río Cuarto', 'Villa María', 'San Francisco', 'Jesús María', 'Alta Gracia', 'La Calera', 'Río Ceballos', 'Unquillo'])[FLOOR(RANDOM()*10)+1] AS ciudad
    FROM generate_series(1, 200000) i
)
SELECT 
    tipo,
    'Cliente ' || i,
    'cli'|| i ||'@mail.com',
    telefono,
    direccion,
    ciudad,
    CASE 
        WHEN tipo = 'mayorista' THEN LPAD((30000000000 + i)::text, 11, '0')
        WHEN RANDOM() < 0.3 THEN NULL
        ELSE LPAD((30000000000 + i)::text, 11, '0')
    END AS cuit,
    CASE 
        WHEN tipo = 'mayorista' THEN 'RS ' || i
        WHEN RANDOM() < 0.7 THEN NULL
        ELSE 'RS ' || i
    END AS razon_social,
    CASE 
        WHEN tipo = 'mayorista' THEN (RANDOM() * 100000)::numeric(14,2)
        WHEN RANDOM() < 0.7 THEN NULL
        ELSE (RANDOM() * 100000)::numeric(14,2)
    END AS limite_credito,
    NOW() - (RANDOM() * interval '2 years'),
    TRUE
FROM datos;
-- SELECT * FROM cliente;

-- 12. Órdenes Compra (15.000) -- lógica estado y recepción no está conectada, la dejo así para no emplayar más el código
INSERT INTO orden_compra (proveedor_id, empleado_comprador_id, sucursal_destino_id, fecha_orden, fecha_recepcion, estado, total)
SELECT 
	(SELECT id FROM proveedor ORDER BY RANDOM() * i LIMIT 1),
    (SELECT id FROM empleado ORDER BY RANDOM() * i LIMIT 1),
	(SELECT id FROM sucursal ORDER BY RANDOM() * i LIMIT 1),
    NOW() - (RANDOM() * interval '1 year'),
    CASE 
		WHEN RANDOM() < 0.8 THEN NOW() - (RANDOM() * interval '300 days') 
		ELSE NULL 
	END,
    (array['pendiente','recibida','cancelada'])[FLOOR(RANDOM()*3)+1],
    (RANDOM() * 50000)::numeric(14,2)
FROM generate_series(1, 15000) i;
-- SELECT * FROM orden_compra;

-- 13. Líneas OC (40.000)
INSERT INTO orden_compra_linea (orden_compra_id, sku_id, cantidad, precio_unitario)
WITH
	oc_id AS (SELECT ARRAY_AGG(id) AS ids FROM orden_compra WHERE id IS NOT NULL),
	sku_id AS (SELECT ARRAY_AGG(id) AS ids FROM sku WHERE id IS NOT NULL)
SELECT 
	oc.ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(oc.ids, 1))::int],
    sku.ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sku.ids, 1))::int],
    (RANDOM() * 100 + 1)::integer, 
	ROUND((RANDOM() * 500 + 5)::numeric, 2)
FROM generate_series(1, 40000) i
CROSS JOIN oc_id oc
CROSS JOIN sku_id sku; 
-- No utilicé RANDOM() * i en los id porque se volvió interminable y extremadamente lento para generar datos aleatorios.

-- SELECT * FROM orden_compra_linea;

-- 14. Viajes (3.000)
DO $$
DECLARE
    v_camiones record;
    v_choferes record;
    v_sucursales record;
BEGIN
    FOR i IN 1..3000 LOOP
        -- Obtener IDs aleatorios
        SELECT id INTO v_camiones FROM camion ORDER BY random() LIMIT 1;
        SELECT id INTO v_choferes FROM empleado 
        WHERE cargo_id = (SELECT id FROM cargo WHERE nombre='Chofer') 
        ORDER BY random() LIMIT 1;
        
        WITH suc_rand AS (
            SELECT id, row_number() OVER (ORDER BY random()) as rn 
            FROM sucursal
        )
        SELECT 
            MAX(CASE WHEN rn = 1 THEN id END) as origen,
            MAX(CASE WHEN rn = 2 THEN id END) as destino
        INTO v_sucursales
        FROM suc_rand
        WHERE rn <= 2;
        
        INSERT INTO viaje (camion_id, chofer_id, sucursal_origen_id, sucursal_destino_id, 
                          fecha_salida, fecha_llegada, estado)
        VALUES (
            v_camiones.id,
            v_choferes.id,
            v_sucursales.origen,
            v_sucursales.destino,
            NOW() - (RANDOM() * interval '200 days'),
            CASE 
				WHEN random() < 0.7 THEN NOW() - (RANDOM() * interval '100 days') 
				ELSE NULL 
			END,
            (array['planificado','en_ruta','completado','cancelado'])[FLOOR(RANDOM() * 4)+ 1]
        );
    END LOOP;
END $$;
-- SELECT * FROM viaje;

-- 15. Ventas (100.000)
DO $$
DECLARE
    cliente_ids integer[];
    vendedor_ids integer[];
    sucursal_ids integer[];
    medio_pago text[] := array['efectivo', 'tarjeta', 'transferencia'];
BEGIN
    -- Cargar arrays con todos los IDs disponibles
    SELECT ARRAY_AGG(id) INTO cliente_ids FROM cliente;
    SELECT ARRAY_AGG(id) INTO vendedor_ids FROM empleado WHERE cargo_id IN (SELECT id FROM cargo WHERE familia='venta');
    SELECT ARRAY_AGG(id) INTO sucursal_ids FROM sucursal;
    
    -- Insertar usando los arrays
    INSERT INTO venta (cliente_id, empleado_vendedor_id, sucursal_id, fecha_venta, tipo_venta, total, medio_pago)
    SELECT 
        cliente_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(cliente_ids, 1))::int],
        vendedor_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(vendedor_ids, 1))::int],
        sucursal_ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(sucursal_ids, 1))::int],
        NOW() - (RANDOM() * interval '1 year'),
        CASE 
			WHEN RANDOM() < 0.7 THEN 'minorista' 
			ELSE 'mayorista' 
		END,
        (RANDOM() * 10000 + 50)::numeric(14,2),
        medio_pago[1 + FLOOR(RANDOM() * ARRAY_LENGTH(medio_pago, 1))::int]
    FROM generate_series(1, 100000);
END $$;
-- SELECT * FROM venta;

-- 16. Líneas Venta (400.000)
WITH 
ventas_ids AS (SELECT ARRAY_AGG(id) as ids FROM venta),
skus_ids AS (SELECT ARRAY_AGG(id) as ids FROM sku)
INSERT INTO venta_linea (venta_id, sku_id, cantidad, precio_unitario, descuento_pct, subtotal)
SELECT 
	ventas_ids.ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(ventas_ids.ids, 1))::int],
	skus_ids.ids[1 + FLOOR(RANDOM() * ARRAY_LENGTH(skus_ids.ids, 1))::int],
	(RANDOM() * 10 + 1)::integer, 
	ROUND((RANDOM() * 500 + 5)::numeric, 2),
	ROUND((RANDOM() * 30)::numeric, 2), 
	0
FROM generate_series(1, 400000) i
CROSS JOIN ventas_ids
CROSS JOIN skus_ids;
UPDATE venta_linea SET subtotal = cantidad * precio_unitario * (1 - descuento_pct/100);
-- SELECT * FROM venta_linea;


-- 17. Movimientos Stock (150.000)
DO $$
DECLARE
    sku_ids integer[];
    suc_ids integer[];
    venta_ids bigint[];
    oc_ids bigint[];
    viaje_ids bigint[];
    tipos text[] := ARRAY['entrada_compra','salida_venta','transferencia_entrada','transferencia_salida','ajuste'];
    tipo_elegido text;
    prob_ajuste float := 0.05;  -- 5% de ajustes manuales
BEGIN
    SELECT ARRAY_AGG(id) INTO sku_ids FROM sku;
    SELECT ARRAY_AGG(id) INTO suc_ids FROM sucursal;
    SELECT ARRAY_AGG(id) INTO venta_ids FROM venta;
    SELECT ARRAY_AGG(id) INTO oc_ids FROM orden_compra;
    SELECT ARRAY_AGG(id) INTO viaje_ids FROM viaje;
    
    FOR i IN 1..150000 LOOP
        tipo_elegido := tipos[1 + FLOOR(RANDOM() * 5)];
        
        INSERT INTO movimiento_stock (
            sku_id, sucursal_id, tipo, cantidad, fecha,
            venta_id, orden_compra_id, viaje_id
        ) VALUES (
            sku_ids[1 + FLOOR(RANDOM() * array_length(sku_ids, 1))],
            suc_ids[1 + FLOOR(RANDOM() * array_length(suc_ids, 1))],
            tipo_elegido,
            (FLOOR(RANDOM() * 100) + 1) * CASE 
                WHEN tipo_elegido IN ('salida_venta', 'transferencia_salida') THEN -1 
                ELSE 1 
            END,
            NOW() - (RANDOM() * interval '200 days'),
            CASE WHEN tipo_elegido = 'salida_venta' THEN venta_ids[1 + FLOOR(RANDOM() * array_length(venta_ids, 1))] ELSE NULL END,
            CASE WHEN tipo_elegido = 'entrada_compra' THEN oc_ids[1 + FLOOR(RANDOM() * array_length(oc_ids, 1))] ELSE NULL END,
            CASE WHEN tipo_elegido IN ('transferencia_entrada', 'transferencia_salida') 
                 THEN viaje_ids[1 + FLOOR(RANDOM() * array_length(viaje_ids, 1))] 
                 ELSE NULL 
            END
        );
    END LOOP;
END $$;

-- SELECT * FROM movimiento_stock;

-- 18. Promociones (500)
DO $$
DECLARE
    i integer;
    intentos integer;
    start_date DATE;
    end_date DATE;
    producto_id integer;
BEGIN
    FOR i IN 1..500 LOOP
        intentos := 0;
        LOOP
            -- Elegir un producto aleatorio
            SELECT id INTO producto_id FROM producto ORDER BY random() LIMIT 1;
            
            -- Generar fechas válidas
            start_date := CURRENT_DATE - (random() * 180)::integer;
            end_date := start_date + (random() * 60 + 1)::integer;
            
            BEGIN
                INSERT INTO promocion (producto_id, descripcion, descuento_pct, vigencia)
                VALUES (producto_id,
                        'Promo ' || i || ' (intento ' || intentos || ')',
                        round((random() * 40 + 5)::numeric, 2),
                        daterange(start_date, end_date, '[)'));
                EXIT; -- Éxito, salir del LOOP interno
            EXCEPTION 
                WHEN exclusion_violation THEN
                    -- Conflicto, intentar con otro producto (máximo 10 intentos)
                    intentos := intentos + 1;
                    IF intentos >= 10 THEN
                        EXIT; -- No se pudo después de 10 intentos, saltar esta iteración
                    END IF;
                WHEN OTHERS THEN
                    EXIT; -- Otro error, saltar
            END;
        END LOOP;
    END LOOP;
END $$;

-- SELECT * FROM promocion;

COMMIT;

VACUUM ANALYZE;