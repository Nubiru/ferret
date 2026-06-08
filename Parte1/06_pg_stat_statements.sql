-- =====================================================================
-- FeRReT — Eje I / D: Métricas con pg_stat_statements
-- Base de Datos III — Proyecto Integrador, Parte 1
-- =====================================================================
-- Requisito (consigna D): "Mostrar las 5 consultas más frecuentes o
-- lentas del sistema".
--
-- Responsable: Mariano (Indexación & Performance).
-- Apoyo de integración: Gabriel.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. HABILITACIÓN (una sola vez por servidor)
-- ---------------------------------------------------------------------
-- pg_stat_statements necesita cargarse al arranque del servidor; NO
-- alcanza con CREATE EXTENSION. Hay que precargar la librería y reiniciar:
--
--   ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
--   ALTER SYSTEM SET pg_stat_statements.track = 'all';
--   -- luego reiniciar el servidor:
--   --   sudo systemctl restart postgresql        (instalación local)
--   --   o reiniciar el contenedor de Postgres
--
-- Verificar que quedó precargada:
--   SHOW shared_preload_libraries;   -- debe incluir pg_stat_statements
--
-- Recién entonces crear la extensión en la base:
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Reiniciar el acumulador de estadísticas antes de medir (opcional):
-- SELECT pg_stat_statements_reset();

-- ---------------------------------------------------------------------
-- 1. TOP 5 consultas más LENTAS (por tiempo total acumulado)
-- ---------------------------------------------------------------------
SELECT
    left(regexp_replace(query, '\s+', ' ', 'g'), 80) AS consulta,
    calls,
    round(total_exec_time::numeric, 1)              AS total_ms,
    round(mean_exec_time::numeric, 2)               AS media_ms,
    rows
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- 2. TOP 5 consultas más LENTAS por ejecución (tiempo medio)
-- ---------------------------------------------------------------------
SELECT
    left(regexp_replace(query, '\s+', ' ', 'g'), 80) AS consulta,
    calls,
    round(mean_exec_time::numeric, 2)               AS media_ms,
    round(total_exec_time::numeric, 1)              AS total_ms
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- 3. TOP 5 consultas más FRECUENTES (por cantidad de llamadas)
-- ---------------------------------------------------------------------
SELECT
    left(regexp_replace(query, '\s+', ' ', 'g'), 80) AS consulta,
    calls,
    round(total_exec_time::numeric, 1)              AS total_ms
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat_statements%'
ORDER BY calls DESC
LIMIT 5;

-- =====================================================================
-- RESULTADO DE MUESTRA (capturado sobre ferret_db con 1.74M registros,
-- tras correr el workload de 04_queries.sql / 05_advanced_sql.sql):
--
--                    consulta                     | calls | total_ms | media_ms | rows
-- -----------------------------------------------+-------+----------+----------+------
--  SELECT p.id, SUM(vl.cantidad) ... atributos @> |   5   |   684.1  |  136.82  |  50
--  SELECT producto_id, nombre, material ... acero |   1   |   219.6  |  219.60  |  10
--  SELECT v.sucursal_id, COUNT(*) ... GROUP BY    |   5   |   109.4  |   21.87  |  30
--  WITH ventas_mensuales AS ( ... ) acumulado     |   1   |    35.2  |   35.20  | 150
--  SELECT sucursal, vendedor ... RANK() puesto    |   1   |    34.3  |   34.27  |  18
--
-- Lectura: la consulta JSONB sobre producto.atributos (que usa el índice
-- GIN) domina el tiempo total — es la candidata #1 a vigilar/optimizar.
-- =====================================================================
