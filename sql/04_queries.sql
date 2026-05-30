-- =====================================================================
-- FeRReT — SQL Avanzado & Lógica de Negocio (Parte 1, Eje I - Stream D)
-- Base de Datos III — Proyecto Integrador
-- =====================================================================

-- =====================================================================
-- BLOQUE 1: WINDOW FUNCTIONS (MÉTRICAS ANALÍTICAS)
-- =====================================================================

-- ---------------------------------------------------------------------
-- CONSULTA 1.1: Ranking de mejores vendedores por sucursal
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Quiénes son los vendedores que han facturado más volumen de dinero
-- en cada una de las sucursales, y cuál es su orden jerárquico relativo?
-- Esta métrica permite evaluar el desempeño de ventas individual en
-- sucursales con distinto tamaño físico y volumen de mercado.

WITH ventas_por_vendedor AS (
    SELECT 
        v.sucursal_id,
        s.nombre AS sucursal_nombre,
        v.empleado_vendedor_id,
        e.nombre || ' ' || e.apellido AS vendedor_nombre,
        SUM(v.total) AS total_vendido
    FROM venta v
    JOIN empleado e ON v.empleado_vendedor_id = e.id
    JOIN sucursal s ON v.sucursal_id = s.id
    GROUP BY v.sucursal_id, s.nombre, v.empleado_vendedor_id, e.nombre, e.apellido
)
SELECT 
    sucursal_nombre,
    vendedor_nombre,
    total_vendido,
    RANK() OVER (
        PARTITION BY sucursal_id 
        ORDER BY total_vendido DESC
    ) AS ranking_vendedor
FROM ventas_por_vendedor
ORDER BY sucursal_nombre, ranking_vendedor;


-- ---------------------------------------------------------------------
-- CONSULTA 1.2: Running Total (Acumulado Mensual) de Ventas por Sucursal
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Cómo evoluciona la facturación acumulada mensual a lo largo del tiempo
-- en cada sucursal?
-- Permite analizar la tendencia financiera de ingresos acumulativos para 
-- evaluar metas de ventas anuales y flujos de caja locales.

WITH ventas_mensuales AS (
    SELECT 
        v.sucursal_id,
        s.nombre AS sucursal_nombre,
        EXTRACT(YEAR FROM v.fecha_venta) AS anio,
        EXTRACT(MONTH FROM v.fecha_venta) AS mes,
        SUM(v.total) AS total_mensual
    FROM venta v
    JOIN sucursal s ON v.sucursal_id = s.id
    GROUP BY v.sucursal_id, s.nombre, EXTRACT(YEAR FROM v.fecha_venta), EXTRACT(MONTH FROM v.fecha_venta)
)
SELECT 
    sucursal_nombre,
    anio,
    mes,
    total_mensual,
    SUM(total_mensual) OVER (
        PARTITION BY sucursal_id 
        ORDER BY anio, mes
    ) AS total_acumulado
FROM ventas_mensuales
ORDER BY sucursal_nombre, anio, mes;


-- ---------------------------------------------------------------------
-- CONSULTA 1.3: Promedio Móvil de Ventas de los últimos 7 días (Daily Moving Avg)
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Cuál es la facturación diaria y el promedio móvil de los últimos 7 días 
-- a nivel global de la empresa?
-- Sirve para suavizar picos y valles atípicos (fines de semana, feriados)
-- y observar con claridad la inercia real del negocio día a día.

WITH ventas_diarias AS (
    SELECT 
        v.fecha_venta::date AS fecha,
        SUM(v.total) AS total_diario
    FROM venta v
    GROUP BY v.fecha_venta::date
)
SELECT 
    fecha,
    total_diario,
    ROUND(AVG(total_diario) OVER (
        ORDER BY fecha 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS promedio_movil_7_dias
FROM ventas_diarias
ORDER BY fecha;


-- =====================================================================
-- BLOQUE 2: CTEs RECURSIVAS (ESTRUCTURAS JERÁRQUICAS)
-- =====================================================================

-- ---------------------------------------------------------------------
-- CONSULTA 2.1: Jerarquía Completa de Categorías con Breadcrumb y Productos
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Cómo es la estructura jerárquica de categorías del catálogo de productos 
-- (árbol completo con nivel de anidamiento e indicador "breadcrumb"), y 
-- cuántos productos activos existen por rama (consolidando las subcategorías)?
-- Permite analizar qué áreas del catálogo tienen mayor variedad de productos 
-- y provee el menú de navegación dinámica para el e-commerce.

WITH RECURSIVE jerarquia_categorias AS (
    -- Caso base: Categorías raíz (sin padre)
    SELECT 
        id, 
        nombre, 
        padre_id, 
        1 AS nivel,
        nombre::TEXT AS ruta_completa
    FROM categoria
    WHERE padre_id IS NULL
    
    UNION ALL
    
    -- Caso recursivo: Categorías hijas
    SELECT 
        c.id, 
        c.nombre, 
        c.padre_id, 
        jc.nivel + 1 AS nivel,
        jc.ruta_completa || ' > ' || c.nombre AS ruta_completa
    FROM categoria c
    JOIN jerarquia_categorias jc ON c.padre_id = jc.id
),
mapeo_ancestros AS (
    -- Caso base: toda categoría mapea a sí misma
    SELECT id AS categoria_id, id AS ancestro_id
    FROM categoria
    
    UNION ALL
    
    -- Caso recursivo: asociar la categoría con el padre y los ancestros del padre
    SELECT c.id AS categoria_id, ma.ancestro_id
    FROM categoria c
    JOIN mapeo_ancestros ma ON c.padre_id = ma.categoria_id
),
conteo_productos AS (
    -- Cuenta los productos activos agrupando por el ancestro mapeado
    SELECT 
        ma.ancestro_id AS categoria_id,
        COUNT(p.id) AS total_productos
    FROM mapeo_ancestros ma
    LEFT JOIN producto p ON ma.categoria_id = p.categoria_id AND p.activo = true
    GROUP BY ma.ancestro_id
)
SELECT 
    jc.id,
    jc.ruta_completa,
    jc.nivel,
    COALESCE(cp.total_productos, 0) AS total_productos_rama
FROM jerarquia_categorias jc
LEFT JOIN conteo_productos cp ON jc.id = cp.categoria_id
ORDER BY jc.ruta_completa;


-- ---------------------------------------------------------------------
-- CONSULTA 2.2A: Cadena de Mando Ascendente (Hacia el CEO)
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Cuál es la ruta directa de supervisión jerárquica de un empleado 
-- determinado (por ejemplo, el vendedor de prueba ID = 999) hacia arriba 
-- hasta llegar al Director General / CEO?
-- Es útil para auditorías de supervisión y escalamiento de autorizaciones.

WITH RECURSIVE cadena_mando_arriba AS (
    -- Caso base: El empleado consultado
    SELECT 
        id, 
        nombre, 
        apellido, 
        supervisor_id, 
        cargo_id,
        1 AS nivel
    FROM empleado
    WHERE id = 999 -- Reemplazar por el ID a buscar
    
    UNION ALL
    
    -- Caso recursivo: El supervisor del empleado anterior
    SELECT 
        e.id, 
        e.nombre, 
        e.apellido, 
        e.supervisor_id, 
        e.cargo_id,
        cma.nivel + 1 AS nivel
    FROM empleado e
    JOIN cadena_mando_arriba cma ON cma.supervisor_id = e.id
)
SELECT 
    cma.nivel,
    cma.id AS empleado_id,
    cma.nombre || ' ' || cma.apellido AS empleado_nombre,
    cg.nombre AS cargo_nombre
FROM cadena_mando_arriba cma
JOIN cargo cg ON cma.cargo_id = cg.id
ORDER BY cma.nivel ASC;


-- ---------------------------------------------------------------------
-- CONSULTA 2.2B: Organigrama Descendente de Subordinados Directos e Indirectos
-- ---------------------------------------------------------------------
-- ¿PREGUNTA DE NEGOCIO?
-- ¿Quiénes son todas las personas que se encuentran bajo el mando directo 
-- o indirecto de un gerente determinado (por ejemplo, el Director ID = 1), 
-- ordenado de manera jerárquica y con sangrado visual?
-- Responde a la necesidad de ver la estructura interna de equipos de 
-- trabajo de forma gráfica y simplificada.

WITH RECURSIVE organigrama_abajo AS (
    -- Caso base: El supervisor raíz del árbol que deseamos ver
    SELECT 
        id, 
        nombre, 
        apellido, 
        supervisor_id, 
        cargo_id,
        1 AS nivel,
        nombre || ' ' || apellido AS ruta_mando
    FROM empleado
    WHERE id = 1 -- ID del Director / CEO Raíz
    
    UNION ALL
    
    -- Caso recursivo: Empleados supervisados directamente por los del nivel anterior
    SELECT 
        e.id, 
        e.nombre, 
        e.apellido, 
        e.supervisor_id, 
        e.cargo_id,
        oa.nivel + 1 AS nivel,
        oa.ruta_mando || ' -> ' || e.nombre || ' ' || e.apellido AS ruta_mando
    FROM empleado e
    JOIN organigrama_abajo oa ON e.supervisor_id = oa.id
)
SELECT 
    oa.nivel,
    oa.id AS empleado_id,
    REPEAT(' · ', oa.nivel - 1) || oa.nombre || ' ' || oa.apellido AS empleado_nombre_jerarquico,
    cg.nombre AS cargo_nombre,
    oa.ruta_mando
FROM organigrama_abajo oa
JOIN cargo cg ON oa.cargo_id = cg.id
ORDER BY oa.ruta_mando;


-- =====================================================================
-- BLOQUE 3: CONSULTAS DE ANÁLISIS DE PERFORMANCE (HISTÓRICAS)
-- =====================================================================

-- Consulta 3.1: Medición de ventas en rango de 30 días
-- Utilizada para EXPLAIN ANALYZE y diagramas Dalibo en el Stream C
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM venta
WHERE fecha_venta >= NOW() - INTERVAL '30 days';

-- Consulta 3.2: Simulación de plan forzando barrido secuencial
SET enable_indexscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM venta
WHERE fecha_venta >= NOW() - INTERVAL '30 days';
SET enable_indexscan = on;

-- Consulta 3.3: Explicación de consulta formateada en JSON para PEV2
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT *
FROM venta
WHERE fecha_venta >= NOW() - INTERVAL '30 days';