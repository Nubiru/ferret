-- =====================================================================
-- rol_api.sql — Rol de aplicacion con PRIVILEGIO MINIMO para la API REST
-- =====================================================================
-- Cierra el gap entre el relato del Eje II.D ("la API se conecta con un
-- usuario de permisos restringidos") y la realidad del backend Node.
--
-- Crea el rol `ferret_api` que usa el backend (db.js) en lugar de un
-- superusuario. Le damos SOLO lo que cada endpoint necesita:
--
--   GET    /api/productos     -> SELECT en el catalogo (4 tablas)
--   POST   /api/productos     -> INSERT en producto (+ secuencia)
--   PUT    /api/productos/:id -> UPDATE en producto
--   DELETE /api/productos/:id -> UPDATE en producto (baja logica)
--   POST   /api/venta         -> EXECUTE del procedure (NO toca tablas)
--
-- Correr como DUENO de la base (superusuario):
--   psql -d ferret_db -f Parte3/Gabriel/rol_api.sql
-- =====================================================================

-- 1) El rol de la API (login con password; lo usa el backend por TCP).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ferret_api') THEN
    CREATE ROLE ferret_api LOGIN PASSWORD 'api_demo';
  END IF;
END $$;

GRANT USAGE ON SCHEMA public TO ferret_api;

-- 2) Lectura del catalogo (lo que arma el GET /api/productos).
GRANT SELECT ON producto, categoria, marca, sku TO ferret_api;

-- 3) Escritura ACOTADA a producto (POST/PUT/DELETE-logico).
--    Nada de DELETE fisico: no otorgamos privilegio DELETE a proposito.
GRANT INSERT, UPDATE ON producto TO ferret_api;
GRANT USAGE, SELECT ON SEQUENCE producto_id_seq TO ferret_api;   -- para nextval() en INSERT

-- 4) Venta: DELEGACION via procedure (mismo principio que ajustar_stock_admin, Eje II.D).
--    Hardening del procedure de Federico: pasa a SECURITY DEFINER con
--    search_path fijo. Asi corre con los privilegios del DUENO, y el rol
--    ferret_api solo necesita EXECUTE: NUNCA toca venta / venta_linea / stock.
ALTER PROCEDURE registrar_venta_simple(integer, integer, integer, integer, integer)
  SECURITY DEFINER
  SET search_path = pg_catalog, public;

REVOKE EXECUTE ON PROCEDURE registrar_venta_simple(integer, integer, integer, integer, integer) FROM PUBLIC;
GRANT  EXECUTE ON PROCEDURE registrar_venta_simple(integer, integer, integer, integer, integer) TO ferret_api;

-- 4b) Lectura de la venta recien creada, TAMBIEN por delegacion.
--     El procedure no devuelve nada, y ferret_api NO puede leer `venta`
--     directamente (lo prohibimos abajo). Asi que exponemos SOLO la ultima
--     venta de un (cliente, empleado) via una funcion SECURITY DEFINER.
--     El endpoint POST /api/venta llama a esta funcion para responder.
CREATE OR REPLACE FUNCTION ultima_venta(p_cliente_id integer, p_empleado_id integer)
RETURNS venta
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT * FROM venta
     WHERE cliente_id = p_cliente_id AND empleado_vendedor_id = p_empleado_id
     ORDER BY fecha_venta DESC
     LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION ultima_venta(integer, integer) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION ultima_venta(integer, integer) TO ferret_api;

-- 5) Defensa en profundidad: dejamos EXPLICITO que el rol NO accede a las
--    tablas sensibles de forma directa (aunque por defecto ya no las ve).
REVOKE ALL ON venta, venta_linea, stock, movimiento_stock, cliente, empleado FROM ferret_api;

-- =====================================================================
-- COMO CORRER LA API CON ESTE ROL (privilegio minimo de verdad):
--   PGHOST=localhost PGUSER=ferret_api PGPASSWORD=api_demo \
--   REDIS_URL=redis://localhost:6379 npm start
--
-- (Requiere una linea en pg_hba.conf que permita md5/scram para conexiones
--  TCP locales; por defecto suele estar para 127.0.0.1/32.)
-- =====================================================================

-- DEMOSTRACION para la defensa (probar sin reconectar, con SET ROLE):
--   SET ROLE ferret_api;
--   SELECT count(*) FROM producto;                 -- OK (tiene SELECT)
--   SELECT count(*) FROM venta;                    -- ERROR: permission denied
--   CALL registrar_venta_simple(1,1,1,1,1);        -- OK (EXECUTE + DEFINER)
--   RESET ROLE;
