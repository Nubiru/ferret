-- Parte B: Capa de Auditoría y Forense de Datos al momento de agregar un nuevo SKU.

-- Tabla de Logs: Crear una tabla audit_logs para registrar errores del sistema. 
-- La Caja Negra
CREATE TABLE audit_logs (
	id 				SERIAL PRIMARY KEY,
	fecha 			TIMESTAMPTZ DEFAULT NOW(),
	usuario 		TEXT DEFAULT current_user,
	codigo_error 	TEXT,	
	mensaje_error 	TEXT,	
	detalle_error 	TEXT,		
	contexto_error 	TEXT	
);

-- Captura de Excepciones: 
-- Usar bloques EXCEPTION y el comando GET STACKED DIAGNOSTICS 
-- para capturar el RETURNED_SQLSTATE y el MESSAGE_TEXT ante cualquier error.
CREATE OR REPLACE PROCEDURE sp_agregar_producto_a_sku(
	IN p_sku_id 				INTEGER,
	IN p_producto_id 			INTEGER,
	IN p_codigo_barras 			VARCHAR(20),
    IN p_descripcion_variante	VARCHAR(200),
    IN p_precio_unitario   		NUMERIC(12,2),
    IN p_unidad_medida     		VARCHAR(20),
    -- IN p_peso_gramos      	INTEGER DEFAULT NULL,
    -- IN p_activo           	BOOLEAN DEFAULT TRUE,
	-- No se incluyeron las tablas peso_gramos y activo porque da el siguiente ERROR:
	-- (los parámetros OUT no pueden aparecer después de uno que tenga valor por omisión)
	-- Como cuentan con un valor por defecto, esta operación sigue siendo consistente.
	OUT p_resultado 			BOOLEAN, -- TRUE: éxito, FALSE: error
	OUT p_mensaje 				TEXT -- mensaje para la app
)
LANGUAGE plpgsql
AS $$
DECLARE
	v_sqlstate TEXT; -- captura del RETURNED_SQLSTATE
	v_message TEXT; -- caputa del MESSAGE_TEXT
	v_detail TEXT;
	v_context TEXT;
BEGIN
	-- Operación principal
	INSERT INTO sku (id, producto_id, codigo_barras, descripcion_variante, precio_unitario, unidad_medida)
	VALUES (p_sku_id, p_producto_id, p_codigo_barras, p_descripcion_variante, p_precio_unitario, p_unidad_medida);
	
	-- Si llegamos acá, todo salió bien
	p_resultado = TRUE;
	p_mensaje = 'SKU agregado correctamente';

EXCEPTION WHEN OTHERS THEN
	-- Captura de datos del error
	GET STACKED DIAGNOSTICS
		v_sqlstate	= RETURNED_SQLSTATE,
		v_message	= MESSAGE_TEXT,
		v_detail	= PG_EXCEPTION_DETAIL,
		v_context	= PG_EXCEPTION_CONTEXT;

	-- Registrar en tabla de logs
	INSERT INTO audit_logs (codigo_error, mensaje_error, detalle_error, contexto_error)
	VALUES (v_sqlstate, v_message, v_detail, v_context);

	-- Informar al sistema
	p_resultado := FALSE;
	p_mensaje := 'Error al agregar SKU: ' || v_message;	
END;
$$;

-- Rompiendo el sistema: 
-- Intentamos agregar SKU existente
DO $$
DECLARE
	v_res BOOLEAN;
	v_msj TEXT;	
BEGIN
	CALL sp_agregar_producto_a_sku(80000, 30001, 'CB80001', 'Caja x100, 6x1 pulgada', 5980.50, 'caja', v_res, v_msj);

	-- Simulación de la app
	IF v_res = FALSE THEN
		RAISE NOTICE 'La app se enteró: %', v_msj;
	ELSE
		RAISE NOTICE 'Todo OK: %', v_msj;
	END IF;
END $$;

-- Intentamos agregar un id no existente
DO $$
DECLARE
	v_res BOOLEAN;
	v_msj TEXT;	
BEGIN
	CALL sp_agregar_producto_a_sku(80001, 30001, 'CB80001', 'Caja x100, 6x1 pulgada', 5980.50, 'caja', v_res, v_msj);

	-- Simulación de la app
	IF v_res = FALSE THEN
		RAISE NOTICE 'La app se enteró: %', v_msj;
	ELSE
		RAISE NOTICE 'Todo OK: %', v_msj;
	END IF;
END $$;

-- Intentamos agregar un código de barras existente
DO $$
DECLARE
	v_res BOOLEAN;
	v_msj TEXT;	
BEGIN
	CALL sp_agregar_producto_a_sku(80001, 30001, 'CB80000', 'Caja x100, 6x1 pulgada', 5980.50, 'caja', v_res, v_msj);

	-- Simulación de la app
	IF v_res = FALSE THEN
		RAISE NOTICE 'La app se enteró: %', v_msj;
	ELSE
		RAISE NOTICE 'Todo OK: %', v_msj;
	END IF;
END $$;

-- Consultar el Log Forense
SELECT fecha, codigo_error, mensaje_error, detalle_error FROM audit_logs
ORDER BY fecha DESC;


------------------------------------------------------------------------------------------------------------------------------
-- Inserción sin error
DO $$
DECLARE
	v_res BOOLEAN;
	v_msj TEXT;	
BEGIN
	CALL sp_agregar_producto_a_sku(80001, 30001, 'CB80001', 'Caja x100, 6x1 pulgada', 5980.50, 'caja', v_res, v_msj);

	-- Simulación de la app
	IF v_res = FALSE THEN
		RAISE NOTICE 'La app se enteró: %', v_msj;
	ELSE
		RAISE NOTICE 'Todo OK: %', v_msj;
	END IF;
END $$;