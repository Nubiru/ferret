-- =========================================================
-- PARTE D - SEGURIDAD Y BLINDAJE (HARDENING)
-- Proyecto Integrador - FeRReT  (Eje II / Parte 2)
-- =========================================================
-- Responsable: Gabriel (@Nubiru)
--
-- Requisito (consigna D - Privilegio Mínimo):
--   D.1  Definidor vs Invocador: lógica crítica con SECURITY DEFINER
--        para que usuarios con permisos limitados ejecuten procesos
--        administrativos controlados.
--   D.2  Protección contra inyección: fijar explícitamente el search_path
--        en las funciones SECURITY DEFINER para evitar escalada de
--        privilegios.
--
-- Criterio de evaluación que cubre:
--   "Las tablas deben ser privadas y las funciones públicas (Abstracción)".
--
-- NOTA DE COORDINACIÓN (Parte B vs Parte D):
--   Una función/procedure con cláusula SET (search_path) NO puede ejecutar
--   COMMIT/ROLLBACK (Parte B). Por eso D vive en su PROPIA función
--   administrativa (no se monta sobre el procedure transaccional de A/B).
-- =========================================================


-- =========================================================
-- 1. ROL DE APLICACIÓN CON PRIVILEGIO MÍNIMO
--    El operador puede LOGIN pero NO tiene acceso directo a las tablas.
-- =========================================================
DROP ROLE IF EXISTS ferret_operador;
CREATE ROLE ferret_operador LOGIN PASSWORD 'demo_operador';

-- Defensa en profundidad: dejamos explícito que NO toca las tablas sensibles.
-- (Un rol nuevo no recibe privilegios por defecto, pero lo declaramos.)
REVOKE ALL ON stock            FROM ferret_operador;
REVOKE ALL ON movimiento_stock FROM ferret_operador;


-- =========================================================
-- 2. FUNCIÓN ADMINISTRATIVA CON SECURITY DEFINER  (D.1)
--    Ajuste controlado de stock + rastro en movimiento_stock.
--    - SECURITY DEFINER  -> corre con privilegios del DUEÑO (no del invocador)
--    - SET search_path   -> blindaje contra search_path injection (D.2)
--    - %TYPE             -> robustez de tipos (se apoya en A.3)
-- =========================================================
CREATE OR REPLACE FUNCTION ajustar_stock_admin(
    p_sku_id       integer,
    p_sucursal_id  integer,
    p_delta        integer,
    p_motivo       text
)
RETURNS stock.cantidad%TYPE
LANGUAGE plpgsql
SECURITY DEFINER                       -- D.1: se ejecuta como el dueño de la función
SET search_path = pg_catalog, public   -- D.2: search_path fijo (anti-escalada)
AS $$
DECLARE
    v_nueva_cantidad stock.cantidad%TYPE;
BEGIN
    -- Operación crítica sobre una tabla "privada"
    UPDATE stock
       SET cantidad = cantidad + p_delta,
           ultima_actualizacion = now()
     WHERE sku_id = p_sku_id
       AND sucursal_id = p_sucursal_id
    RETURNING cantidad INTO v_nueva_cantidad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe stock para sku=% en sucursal=%',
            p_sku_id, p_sucursal_id;
    END IF;

    IF v_nueva_cantidad < 0 THEN
        RAISE EXCEPTION 'El ajuste dejaría stock negativo (resultado=%)',
            v_nueva_cantidad;
    END IF;

    -- Rastro del movimiento. El p_motivo alimentará la tabla audit_logs
    -- de la Parte C cuando esté disponible (cruce con el trabajo del equipo).
    INSERT INTO movimiento_stock (sku_id, sucursal_id, tipo, cantidad, fecha)
    VALUES (p_sku_id, p_sucursal_id, left('AJUSTE_ADMIN:' || p_motivo, 30),
            p_delta, now());

    RETURN v_nueva_cantidad;
END;
$$;


-- =========================================================
-- 3. ABSTRACCIÓN: tabla PRIVADA, función PÚBLICA
--    Nadie ejecuta la función "por las dudas"; solo el operador autorizado.
-- =========================================================
REVOKE ALL ON FUNCTION ajustar_stock_admin(integer, integer, integer, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION ajustar_stock_admin(integer, integer, integer, text) TO ferret_operador;


-- =========================================================
-- 4. DEMOSTRACIÓN (ejecutar conectado como ferret_operador)
-- ---------------------------------------------------------
--   -- Acceso directo a la tabla: DEBE FALLAR (permission denied)
--   SELECT * FROM stock LIMIT 1;
--
--   -- Vía la función SECURITY DEFINER: FUNCIONA (corre como el dueño)
--   SELECT ajustar_stock_admin(<sku_id>, <sucursal_id>, -1, 'correccion inventario');
--
-- Resultado esperado: el operador NO puede leer la tabla directamente,
-- pero SÍ puede ejecutar la operación administrativa controlada.
-- =========================================================
