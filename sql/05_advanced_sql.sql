-- =====================================================================
-- FeRReT — Stream D: SQL Avanzado (Lógica de Negocio)
-- Base de Datos III — Proyecto Integrador, Parte 1, Eje I
-- =====================================================================
-- Responsable: Gabriel — @Nubiru
-- Cumple consigna E:
--   - Window Functions (al menos una métrica analítica)
--   - CTE y Recursividad (al menos una sobre estructura jerárquica)
-- Bonus: query que aprovecha el índice GIN sobre producto.atributos
-- (creado en 02_indexes.sql) dentro de una window function.
-- =====================================================================
-- Orden de ejecución sugerido:
--   1. psql -d ferret -f sql/01_schema.sql
--   2. psql -d ferret -f sql/03_seed.sql
--   3. psql -d ferret -f sql/02_indexes.sql
--   4. psql -d ferret -f sql/05_advanced_sql.sql   <-- este archivo
-- =====================================================================


-- =====================================================================
-- 0. PREPARACIÓN DE JERARQUÍAS (idempotente)
-- =====================================================================
-- El seed cargó categorias y empleados sin relación padre/hijo
-- (todos con padre_id / supervisor_id = NULL). Las queries recursivas
-- de abajo necesitan profundidad real para demostrar la recursividad.
-- Este bloque arma la jerarquía sobre los datos existentes una sola vez:
-- si ya existe alguna relación padre/hijo, no toca nada.
-- =====================================================================

-- Categorías: 50 filas planas → 10 raíces / 20 hijas / 20 nietas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM categoria WHERE padre_id IS NOT NULL) THEN
        -- IDs 11..30  →  hijas de las raíces 1..10
        UPDATE categoria
           SET padre_id = ((id - 11) % 10) + 1
         WHERE id BETWEEN 11 AND 30;

        -- IDs 31..50  →  nietas (hijas de 11..30)
        UPDATE categoria
           SET padre_id = 11 + ((id - 31) % 20)
         WHERE id BETWEEN 31 AND 50;

        RAISE NOTICE 'Jerarquía de categorias armada (3 niveles).';
    ELSE
        RAISE NOTICE 'Categorias ya tienen jerarquia. No se modifica nada.';
    END IF;
END $$;

-- Empleados: 200 filas planas → 1 CEO / 10 gerentes / 39 mandos medios / 150 staff
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM empleado WHERE supervisor_id IS NOT NULL) THEN
        -- ID 1 queda como CEO con supervisor_id = NULL
        -- IDs 2..11   → reportan al CEO (id 1)
        UPDATE empleado
           SET supervisor_id = 1
         WHERE id BETWEEN 2 AND 11;

        -- IDs 12..50  → mandos medios (reportan a gerentes 2..11)
        UPDATE empleado
           SET supervisor_id = 2 + ((id - 12) % 10)
         WHERE id BETWEEN 12 AND 50;

        -- IDs 51..200 → staff (reportan a mandos medios 12..50)
        UPDATE empleado
           SET supervisor_id = 12 + ((id - 51) % 39)
         WHERE id BETWEEN 51 AND 200;

        RAISE NOTICE 'Organigrama armado (4 niveles: CEO -> gerentes -> mandos medios -> staff).';
    ELSE
        RAISE NOTICE 'Empleados ya tienen jerarquia. No se modifica nada.';
    END IF;
END $$;

ANALYZE categoria;
ANALYZE empleado;


-- =====================================================================
-- 1. WINDOW FUNCTION — Top 3 vendedores por sucursal
-- =====================================================================
-- Pregunta de negocio:
--   "¿Quiénes son los 3 mejores vendedores de cada sucursal según el
--    total facturado, y qué puesto ocupan?"
--
-- Window utilizada: RANK() OVER (PARTITION BY sucursal ORDER BY total DESC)
-- =====================================================================

SELECT
    sucursal,
    vendedor,
    cantidad_ventas,
    total_facturado,
    puesto
FROM (
    SELECT
        s.nombre                                      AS sucursal,
        e.nombre || ' ' || e.apellido                 AS vendedor,
        COUNT(v.id)                                   AS cantidad_ventas,
        SUM(v.total)::NUMERIC(14,2)                   AS total_facturado,
        RANK() OVER (
            PARTITION BY v.sucursal_id
            ORDER BY SUM(v.total) DESC
        )                                             AS puesto
    FROM venta v
    JOIN empleado e ON e.id = v.empleado_vendedor_id
    JOIN sucursal s ON s.id = v.sucursal_id
    GROUP BY s.nombre, v.sucursal_id, e.id, e.nombre, e.apellido
) ranking
WHERE puesto <= 3
ORDER BY sucursal, puesto;


-- =====================================================================
-- 2. WINDOW FUNCTION — Acumulado mensual + promedio móvil de 3 meses
-- =====================================================================
-- Pregunta de negocio:
--   "Mostrar la evolución mensual de las ventas por sucursal: total del
--    mes, acumulado desde el inicio (running total) y promedio móvil de
--    los últimos 3 meses para suavizar la curva."
--
-- Windows utilizadas:
--   - SUM(...) OVER (PARTITION BY sucursal ORDER BY mes)            → running total
--   - AVG(...) OVER (PARTITION BY sucursal ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
-- =====================================================================

WITH ventas_mensuales AS (
    SELECT
        s.id                                    AS sucursal_id,
        s.nombre                                AS sucursal,
        DATE_TRUNC('month', v.fecha_venta)::DATE AS mes,
        SUM(v.total)::NUMERIC(14,2)             AS total_mes,
        COUNT(*)                                AS cantidad_ventas
    FROM venta v
    JOIN sucursal s ON s.id = v.sucursal_id
    GROUP BY s.id, s.nombre, DATE_TRUNC('month', v.fecha_venta)
)
SELECT
    sucursal,
    mes,
    cantidad_ventas,
    total_mes,
    SUM(total_mes) OVER (
        PARTITION BY sucursal_id
        ORDER BY mes
    )::NUMERIC(14,2)                            AS acumulado,
    AVG(total_mes) OVER (
        PARTITION BY sucursal_id
        ORDER BY mes
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )::NUMERIC(14,2)                            AS promedio_movil_3m
FROM ventas_mensuales
ORDER BY sucursal, mes;


-- =====================================================================
-- 3. CTE RECURSIVA — Árbol completo de categorías
-- =====================================================================
-- Pregunta de negocio:
--   "Mostrar la jerarquía completa de categorías con la ruta desde la
--    raíz, el nivel de profundidad, y la cantidad de productos asociados
--    a cada nodo."
--
-- Estructura jerárquica: categoria.padre_id (auto-referencia).
-- =====================================================================

WITH RECURSIVE arbol_categorias AS (
    -- Caso base: raíces (categorías sin padre)
    SELECT
        c.id,
        c.nombre,
        c.padre_id,
        0                       AS nivel,
        c.nombre::TEXT          AS ruta
    FROM categoria c
    WHERE c.padre_id IS NULL

    UNION ALL

    -- Caso recursivo: bajar por la jerarquía
    SELECT
        c.id,
        c.nombre,
        c.padre_id,
        a.nivel + 1,
        a.ruta || ' > ' || c.nombre
    FROM categoria c
    JOIN arbol_categorias a ON c.padre_id = a.id
)
SELECT
    a.nivel,
    REPEAT('  ', a.nivel) || a.nombre   AS categoria_indentada,
    a.ruta,
    COUNT(p.id)                         AS productos_directos
FROM arbol_categorias a
LEFT JOIN producto p ON p.categoria_id = a.id
GROUP BY a.id, a.nivel, a.nombre, a.ruta
ORDER BY a.ruta;


-- =====================================================================
-- 4. CTE RECURSIVA — Cadena de mando de un empleado al CEO
-- =====================================================================
-- Pregunta de negocio:
--   "Dado un empleado cualquiera, mostrar la cadena de supervisores
--    desde él hasta el CEO (recorrido hacia arriba en el organigrama)."
--
-- Estructura jerárquica: empleado.supervisor_id (auto-referencia).
-- Cambiar el id en la cláusula WHERE para consultar otro empleado.
-- =====================================================================

WITH RECURSIVE cadena_mando AS (
    -- Caso base: el empleado consultado
    SELECT
        e.id,
        e.nombre,
        e.apellido,
        e.cargo_id,
        e.supervisor_id,
        0 AS nivel
    FROM empleado e
    WHERE e.id = 150              -- <-- cambiar para consultar a otro empleado

    UNION ALL

    -- Caso recursivo: subir un nivel hacia el supervisor
    SELECT
        sup.id,
        sup.nombre,
        sup.apellido,
        sup.cargo_id,
        sup.supervisor_id,
        c.nivel + 1
    FROM empleado sup
    JOIN cadena_mando c ON sup.id = c.supervisor_id
)
SELECT
    c.nivel,
    c.id                                        AS empleado_id,
    c.nombre || ' ' || c.apellido               AS empleado,
    cg.nombre                                   AS cargo,
    cg.familia                                  AS familia_cargo
FROM cadena_mando c
LEFT JOIN cargo cg ON cg.id = c.cargo_id
ORDER BY c.nivel;


-- =====================================================================
-- 5. BONUS — Window Function + Filtro GIN sobre JSONB
-- =====================================================================
-- Pregunta de negocio:
--   "De todos los productos de material 'acero', ¿cuáles son los 10 que
--    más unidades vendieron, y qué puesto ocupan en el ranking?"
--
-- Window:    RANK() OVER (ORDER BY unidades DESC)
-- Índice:    idx_producto_atributos_gin (GIN sobre producto.atributos)
--            se activa por el operador @> sobre JSONB.
-- Validación: correr EXPLAIN ANALYZE de esta query y verificar que el
--             plan use "Bitmap Index Scan on idx_producto_atributos_gin".
-- =====================================================================

SELECT
    producto_id,
    nombre,
    material,
    unidades_vendidas,
    total_facturado,
    ranking_unidades
FROM (
    SELECT
        p.id                                        AS producto_id,
        p.nombre,
        p.atributos->>'material'                    AS material,
        SUM(vl.cantidad)                            AS unidades_vendidas,
        SUM(vl.subtotal)::NUMERIC(14,2)             AS total_facturado,
        RANK() OVER (ORDER BY SUM(vl.cantidad) DESC) AS ranking_unidades
    FROM producto p
    JOIN sku         sk ON sk.producto_id = p.id
    JOIN venta_linea vl ON vl.sku_id = sk.id
    WHERE p.atributos @> '{"material":"acero"}'::JSONB   -- <- usa el índice GIN
    GROUP BY p.id, p.nombre, p.atributos
) ranking
WHERE ranking_unidades <= 10
ORDER BY ranking_unidades;


-- =====================================================================
-- FIN — Stream D completo.
-- =====================================================================
-- Resumen de lo cumplido respecto a la consigna E:
--   ✓ Window Functions: queries 1, 2 y 5  (RANK, SUM OVER, AVG OVER)
--   ✓ CTE Recursivas:   queries 3 y 4    (categorias y organigrama)
--   ✓ Bonus de integración: query 5 conecta Stream D con el indice GIN
--     que armó Stream C, demostrando que la indexación se usa en logica
--     de negocio real.
-- =====================================================================
