-- =========================================================
-- PARTE B - GESTION AVANZADA DE TRANSACCIONES
-- Proyecto Integrador - FeRReT  (Eje II / Parte 2)
-- =========================================================
-- Responsable: Gabriel (@Nubiru)
--
-- Requisito (consigna B):
--   B.1  Atomicidad: COMMIT / ROLLBACK explicitos.
--   B.2  SAVEPOINT: aislar un subproceso secundario propenso a fallas.
--   B.3  ROLLBACK TO SAVEPOINT: reversion parcial ante error controlado.
--
-- NOTA PL/pgSQL (importante para la defensa):
--   El lenguaje NO admite los comandos SQL literales SAVEPOINT /
--   ROLLBACK TO SAVEPOINT dentro del cuerpo de una rutina. El mecanismo
--   equivalente -- y como PostgreSQL implementa internamente los
--   savepoints -- es un subbloque BEGIN ... EXCEPTION ... END: si algo
--   falla adentro, se revierte SOLO ese subbloque (rollback al savepoint)
--   y la transaccion exterior continua. Eso es exactamente B.2 + B.3.
--
--   Ademas, una rutina con COMMIT/ROLLBACK no puede llevar un EXCEPTION
--   en su bloque EXTERIOR ni una clausula SET (search_path). Por eso la
--   Parte B vive en su propia PROCEDURE, separada de la funcion blindada
--   de la Parte D (scripts/06_seguridad_hardening.sql).
-- =========================================================

CREATE OR REPLACE PROCEDURE registrar_venta_completa(
    p_cliente_id   integer,
    p_empleado_id  integer,
    p_sucursal_id  integer,
    p_sku_id       integer,
    p_cantidad     integer,
    p_medio_pago   text DEFAULT 'EFECTIVO'
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Robustez de tipos (%TYPE): el codigo no se rompe si cambian las tablas
    v_precio          sku.precio_unitario%TYPE;
    v_subtotal        venta.total%TYPE;
    v_venta_id        venta.id%TYPE;
    v_nueva_cantidad  stock.cantidad%TYPE;
    v_deposito_id     sucursal.id%TYPE;
    v_sync_ok         boolean := true;
BEGIN
    -- =====================================================
    -- PASO PRINCIPAL (critico y atomico): la venta en si
    -- =====================================================
    SELECT precio_unitario INTO v_precio FROM sku WHERE id = p_sku_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El SKU % no existe', p_sku_id;
    END IF;

    v_subtotal := p_cantidad * v_precio;

    INSERT INTO venta (cliente_id, empleado_vendedor_id, sucursal_id,
                       fecha_venta, tipo_venta, total, medio_pago)
    VALUES (p_cliente_id, p_empleado_id, p_sucursal_id,
            now(), 'MOSTRADOR', v_subtotal, p_medio_pago)
    RETURNING id INTO v_venta_id;

    INSERT INTO venta_linea (venta_id, sku_id, cantidad, precio_unitario, subtotal)
    VALUES (v_venta_id, p_sku_id, p_cantidad, v_precio, v_subtotal);

    UPDATE stock
       SET cantidad = cantidad - p_cantidad,
           ultima_actualizacion = now()
     WHERE sku_id = p_sku_id AND sucursal_id = p_sucursal_id
    RETURNING cantidad INTO v_nueva_cantidad;

    -- Validacion de negocio -> ROLLBACK EXPLICITO (B.1)
    -- Si no hay stock suficiente, se revierte TODO (venta + linea + update).
    IF NOT FOUND OR v_nueva_cantidad < 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Stock insuficiente para SKU % en sucursal % (resultado %). Venta cancelada.',
            p_sku_id, p_sucursal_id, COALESCE(v_nueva_cantidad, 0);
    END IF;

    -- =====================================================
    -- PASO SECUNDARIO (propenso a fallar) -- SAVEPOINT (B.2/B.3)
    -- Reposicion automatica: se "reserva" stock en el deposito central
    -- para reponer la sucursal via la flota. Si el deposito no tiene
    -- registro de ese SKU, la reposicion NO puede hacerse... pero la
    -- venta del cliente NO debe abortarse por eso.
    -- =====================================================
    SELECT id INTO v_deposito_id FROM sucursal WHERE es_deposito_central LIMIT 1;

    BEGIN  -- <-- subbloque = SAVEPOINT implicito
        IF v_deposito_id IS NULL THEN
            RAISE EXCEPTION 'No hay deposito central configurado';
        END IF;

        UPDATE stock
           SET cantidad = cantidad - p_cantidad,
               ultima_actualizacion = now()
         WHERE sku_id = p_sku_id AND sucursal_id = v_deposito_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'El deposito central no tiene registro de stock para el SKU %', p_sku_id;
        END IF;

        INSERT INTO movimiento_stock (sku_id, sucursal_id, tipo, cantidad, fecha)
        VALUES (p_sku_id, v_deposito_id, 'REPOSICION_AUTO', -p_cantidad, now());

    EXCEPTION
        WHEN OTHERS THEN
            -- ROLLBACK TO SAVEPOINT implicito: se deshace SOLO este subbloque.
            -- La venta principal queda intacta y se confirma igual.
            v_sync_ok := false;
            RAISE NOTICE 'Paso secundario (reposicion) fallo: %. La venta se confirma igual.', SQLERRM;
    END;

    -- Rastro del movimiento principal de la venta (siempre se registra)
    INSERT INTO movimiento_stock (sku_id, sucursal_id, tipo, cantidad, fecha)
    VALUES (p_sku_id, p_sucursal_id, 'VENTA', -p_cantidad, now());

    -- =====================================================
    -- ATOMICIDAD: confirmar la transaccion (B.1)
    -- =====================================================
    COMMIT;

    RAISE NOTICE 'Venta % confirmada. Total=%. Reposicion deposito central=%.',
        v_venta_id, v_subtotal, CASE WHEN v_sync_ok THEN 'OK' ELSE 'OMITIDA' END;
END;
$$;
