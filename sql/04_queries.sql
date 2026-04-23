-- =====================================================================
-- FeRReT — SQL Avanzado (Window Functions + CTEs recursivas)
-- Base de Datos III — Proyecto Integrador, Parte 1
-- =====================================================================
-- Responsable: Stream D (SQL Avanzado)
--
-- Cada query lleva en comentario la pregunta de negocio que responde.
-- =====================================================================

-- ---------------------------------------------------------------------
-- WINDOW FUNCTION #1 — Top vendedores por sucursal
-- Pregunta: ¿Quiénes son los vendedores con más ventas en cada sucursal?
-- ---------------------------------------------------------------------
-- TODO:
-- SELECT
--     v.sucursal_id,
--     e.nombre || ' ' || e.apellido AS vendedor,
--     SUM(v.total) AS total_vendido,
--     RANK() OVER (PARTITION BY v.sucursal_id ORDER BY SUM(v.total) DESC) AS puesto
--   FROM venta v
--   JOIN empleado e ON e.id = v.empleado_vendedor_id
--   GROUP BY v.sucursal_id, e.id, e.nombre, e.apellido;


-- ---------------------------------------------------------------------
-- WINDOW FUNCTION #2 — Running total mensual por sucursal
-- Pregunta: ¿Cómo evoluciona el acumulado mensual de ventas en cada sucursal?
-- ---------------------------------------------------------------------
-- TODO:
-- WITH ventas_mes AS (
--     SELECT sucursal_id,
--            date_trunc('month', fecha_venta) AS mes,
--            SUM(total) AS total_mes
--       FROM venta
--      GROUP BY sucursal_id, date_trunc('month', fecha_venta)
-- )
-- SELECT sucursal_id, mes, total_mes,
--        SUM(total_mes) OVER (PARTITION BY sucursal_id ORDER BY mes) AS acumulado
--   FROM ventas_mes
--   ORDER BY sucursal_id, mes;


-- ---------------------------------------------------------------------
-- CTE RECURSIVA #1 — Árbol de categorías
-- Pregunta: Dada una categoría raíz, ¿cuáles son TODAS sus descendientes
-- y el camino completo desde la raíz?
-- ---------------------------------------------------------------------
-- TODO:
-- WITH RECURSIVE arbol AS (
--     SELECT id, nombre, padre_id, nombre::TEXT AS ruta, 0 AS nivel
--       FROM categoria WHERE padre_id IS NULL
--     UNION ALL
--     SELECT c.id, c.nombre, c.padre_id,
--            a.ruta || ' > ' || c.nombre,
--            a.nivel + 1
--       FROM categoria c
--       JOIN arbol a ON c.padre_id = a.id
-- )
-- SELECT * FROM arbol ORDER BY ruta;


-- ---------------------------------------------------------------------
-- CTE RECURSIVA #2 — Cadena de mando de un empleado (hacia arriba)
-- Pregunta: Dado un empleado, ¿cuál es su cadena de supervisores
-- hasta el CEO?
-- ---------------------------------------------------------------------
-- TODO:
-- WITH RECURSIVE cadena AS (
--     SELECT id, nombre, apellido, supervisor_id, 0 AS nivel
--       FROM empleado WHERE id = :empleado_id
--     UNION ALL
--     SELECT e.id, e.nombre, e.apellido, e.supervisor_id, c.nivel + 1
--       FROM empleado e
--       JOIN cadena c ON e.id = c.supervisor_id
-- )
-- SELECT * FROM cadena ORDER BY nivel;


-- ---------------------------------------------------------------------
-- CTE RECURSIVA #3 (bonus) — Todos los subordinados de un gerente
-- Pregunta: Dado un gerente, ¿quiénes son todos los empleados bajo
-- su responsabilidad (directos + indirectos)?
-- ---------------------------------------------------------------------
-- TODO: análoga a la anterior pero bajando por supervisor_id.
