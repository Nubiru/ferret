-- =====================================================================
-- FeRReT — Carga masiva de datos (≥ 1.000.000 registros)
-- Base de Datos III — Proyecto Integrador, Parte 1
-- =====================================================================
-- Responsable: Stream B (Carga Masiva)
--
-- Orden de carga (respetar dependencias de FKs):
--   1. sucursal        →  6
--   2. camion          →  ~15
--   3. cargo           →  ~20 (catálogo de cargos)
--   4. empleado        →  ~200  (organigrama: raíz primero, después niveles)
--   5. marca           →  ~200
--   6. categoria       →  ~250  (raíces → hijas → nietos)
--   7. producto        →  ~30.000
--   8. sku             →  ~80.000
--   9. stock           →  ~480.000 (80k SKUs × 6 ubicaciones)
--  10. proveedor       →  ~300
--  11. cliente         →  ~150.000
--  12. orden_compra    →  ~20.000
--  13. orden_compra_linea → ~80.000
--  14. viaje           →  ~5.000
--  15. venta           →  ~250.000
--  16. venta_linea     →  ~800.000
--  17. movimiento_stock → ~150.000
--  18. alquiler        →  ~15.000   (cuidado con el EXCLUDE por solapamiento)
--  19. promocion       →  ~1.000    (cuidado con el EXCLUDE por solapamiento)
--
-- Tips:
--  - Envolver en BEGIN; ... COMMIT; los bloques grandes.
--  - Usar generate_series + random() + md5() para generar volumen.
--  - Usar Faker (Python) en scripts/ si se quieren datos más realistas.
--  - Desactivar constraints que se puedan desactivar durante la carga
--    y verificar al final con VACUUM ANALYZE.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. Sucursales (5 sucursales + 1 depósito central)
-- ---------------------------------------------------------------------
-- TODO: INSERT INTO sucursal (...)

-- ---------------------------------------------------------------------
-- 2. Camiones
-- ---------------------------------------------------------------------
-- TODO: INSERT INTO camion (...) SELECT ... FROM generate_series(1, 15);

-- ---------------------------------------------------------------------
-- 3. Cargos
-- ---------------------------------------------------------------------
-- TODO: cargos por familia (ejecutivo, administrativo, caja, venta,
--       transporte, adquisicion, guardia)

-- ---------------------------------------------------------------------
-- 4. Empleados (organigrama, ~200)
-- ---------------------------------------------------------------------
-- Idea: insertar primero al CEO (supervisor_id = NULL) y luego ir bajando
-- por niveles usando CTEs o varias sentencias encadenadas.

-- ---------------------------------------------------------------------
-- 5. Marcas
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 6. Categorías (jerarquía de 4–5 niveles)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 7. Productos (~30.000) con JSONB variado
-- ---------------------------------------------------------------------
-- Ejemplo de atributos (generar aleatoriamente dentro de un set acotado):
--   {"material":"acero","medida":"8mm","rosca":"metrica","color":"negro"}

-- ---------------------------------------------------------------------
-- 8. SKUs (~80.000)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 9. Stock (~480.000)
-- ---------------------------------------------------------------------
-- INSERT INTO stock (sku_id, sucursal_id, cantidad)
-- SELECT s.id, suc.id, (random()*500)::int
--   FROM sku s CROSS JOIN sucursal suc;

-- ---------------------------------------------------------------------
-- 10–14. Proveedores, Clientes, Órdenes de Compra, Viajes
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 15. Ventas (~250.000) — distribuidas en un rango de fechas de ~2 años
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 16. Venta_linea (~800.000)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 17. Movimientos de stock
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 18. Alquiler (ojo: EXCLUDE no permite solapamientos por sku)
-- ---------------------------------------------------------------------
-- Generar ventanas bien espaciadas o manejar excepciones.

-- ---------------------------------------------------------------------
-- 19. Promociones (ojo: EXCLUDE no permite solapamientos por producto)
-- ---------------------------------------------------------------------

COMMIT;

-- Al finalizar:
VACUUM ANALYZE;
