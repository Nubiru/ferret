# Checklist — Proyecto Integrador · Parte 1 / Eje I (Optimización y SQL Avanzado)

PostgreSQL. Marquen `[x]` lo completado. Cada casilla debe tener respaldo en código/commits.

### A. Modelado y Estructura

- [x] **1.** Documentación del concepto del negocio (`propuesta_proyecto.md` / `README.md`).
- [x] **2.** DER normalizado a 3NF, exportado (`docs/DER/`).

### B. Carga Masiva de Datos — Lautaro (`sql/03_seed.sql`)

- [x] **1.** Script que inserta ≥ 1.000.000 de registros totales (cargados ~1.74M).

### C. Estrategias de Indexación — Mariano (`sql/02_indexes.sql`)

- [x] **1.** **B-Tree** (rangos/igualdad, ej. `venta.fecha_venta`).
- [x] **2.** **Hash** (igualdad exacta en texto, ej. `cliente.email` / `sku.codigo_barras`).
- [x] **3.** **GIN** sobre columna JSONB (`producto.atributos`). *(la consigna pide GIN **o** GiST: con GIN ya se cumple)*
- [ ] **4.** GiST sobre rango/geometría — *opcional* (verificar si quedó en `alquiler.ventana` / `promocion.vigencia`).

### D. Análisis de Performance — Mariano

- [x] **1.** `EXPLAIN ANALYZE` de una consulta antes y después del índice (`TAREAS.md` · sección PERFORMANCE).
- [x] **2.** 2 diagramas Dalibo/PEV2 (`docs/dalibo/`).
- [ ] **3.** ⚠️ **pg_stat_statements**: top-5 consultas más frecuentes/lentas. *(borrador listo en `sql/06_pg_stat_statements.sql`; requiere `shared_preload_libraries` + reinicio para medir en vivo).*

### E. SQL Avanzado — Gabriel (`sql/04_queries.sql`, `sql/05_advanced_sql.sql`)

- [x] **1.** **Window Functions** (≥1 métrica analítica: ranking / running total).
- [x] **2.** **CTE Recursiva** sobre estructura jerárquica (categorías y/o organigrama).

---

> **Único hueco real de Eje I:** D.3 (pg_stat_statements). GiST (C.4) es opcional porque ya hay GIN.
