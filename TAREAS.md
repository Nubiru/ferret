# División de Tareas — FeRReT

Equipo: **Lautaro, Mariano, Federico, Gabriel**.

Hay 4 streams de trabajo pensados para que puedan avanzar **en paralelo** después de que el schema esté listo. La idea es que cada persona elija uno y escriba su nombre al lado.

## Dependencias entre streams

```
[A. Modelado & DER]
        │
        ▼
[B. Carga Masiva]
        │
        ├──► [C. Indexación & Performance]
        └──► [D. SQL Avanzado]
```

A bloquea a B. B es necesario para que C y D tengan datos reales contra los cuales medir (EXPLAIN ANALYZE, window functions, recursivas). C y D corren **en paralelo** una vez que hay datos cargados.

Mientras A termina, los otros tres pueden ir leyendo el schema borrador y armando drafts de sus partes.

---

## Stream A — Modelado & DER

**Responsable:** Federico — [@Frederick1824](https://github.com/Frederick1824)

**Entregables:**

- [ ] Revisar `sql/01_schema.sql` (borrador inicial ya creado) y ajustar junto con el equipo.
- [ ] Documentar el concepto del negocio (sección en `docs/concepto.md` o ampliar README).
- [ ] Generar el **DER normalizado a 3NF** en DBeaver → exportar a `docs/DER.png` o `docs/DER.pdf`.
- [ ] Verificar que el modelo cumple 3NF (sin dependencias transitivas, sin atributos multivaluados).
- [ ] Dejar listo el `sql/01_schema.sql` aplicable limpio contra una DB vacía.

**Puntos de atención:**

- Categorías de productos con auto-referencia (recursividad).
- Empleados con auto-referencia `supervisor_id` (organigrama recursivo).
- Relación producto ↔ SKU (1:N) — las variantes son el "subproducto".
- Stock como tabla N:M con atributos (cantidad por sucursal).
- Venta mayorista vs minorista: decidir si se resuelve con flag `tipo_cliente` (elegido) o subtipos.

---

## Stream B — Carga Masiva (≥ 1.000.000 registros)

**Responsable:** Lautaro — [@LautaroAi](https://github.com/LautaroAi)

**Entregables:**

- [ ] Poblar `sql/03_seed.sql` (o scripts en `scripts/` si usan Python + Faker).
- [ ] Orden sugerido y volúmenes objetivo:

  | Tabla                                 | Registros objetivo                    |
  | ------------------------------------- | ------------------------------------- |
  | `sucursal`                            | 6 (5 sucursales + 1 depósito central) |
  | `camion`                              | ~15                                   |
  | `categoria`                           | ~250 (con jerarquía de 4–5 niveles)   |
  | `proveedor`                           | ~300                                  |
  | `empleado`                            | ~200 (con jerarquía de 5 niveles)     |
  | `cliente`                             | ~150.000                              |
  | `producto`                            | ~30.000                               |
  | `sku`                                 | ~80.000                               |
  | `stock`                               | ~480.000 (80k SKUs × 6 ubicaciones)   |
  | `orden_compra` + `orden_compra_linea` | 20.000 + 80.000                       |
  | `venta`                               | ~250.000                              |
  | `venta_linea`                         | ~800.000 (~3.2 líneas por venta)      |
  | `movimiento_stock`                    | ~150.000                              |
  | `alquiler`                            | ~15.000                               |
  | `promocion`                           | ~1.000                                |
  | `viaje` (transporte)                  | ~5.000                                |
  | **TOTAL aprox.**                      | **~2.000.000+**                       |

- [ ] Usar `generate_series` + funciones aleatorias, o Python+Faker si necesitan datos más realistas.
- [ ] Atributos JSONB de productos con variedad suficiente para que GIN tenga sentido (ej. `{"material":"acero","medida":"8mm","rosca":"métrica","marca":"Bremen"}`).
- [ ] Rangos `tsrange` / `daterange` con solapamientos realistas para que el EXCLUDE de GiST sea visible.
- [ ] Documentar en comentarios del SQL cuánto tarda la carga y cuánto pesa la DB al final.

**Puntos de atención:**

- Desactivar índices no-críticos durante la carga y recrearlos al final acelera mucho.
- Cargar en transacciones grandes (`BEGIN; ... COMMIT;`) y con `COPY` cuando se pueda.

---

## Stream C — Indexación & Performance

**Responsable:** Mariano — [@marianof87](https://github.com/marianof87)

**Entregables:**

- [ ] Poblar `sql/02_indexes.sql` con cada tipo de índice pedido + justificación en comentario:
  - **B-Tree**: `venta.fecha_venta`, `movimiento_stock.fecha`, FKs más consultadas.
  - **Hash**: `cliente.email`, `sku.codigo_barras`.
  - **GIN**: `producto.atributos` (JSONB) con `jsonb_path_ops`.
  - **GiST**: `alquiler.ventana` (tsrange) + constraint `EXCLUDE`; `promocion.vigencia` (daterange) + `EXCLUDE`.
- [ ] Elegir **una consulta representativa** para el análisis antes/después:
  - Correr `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` **sin** el índice → capturar.
  - Crear el índice.
  - Correr de nuevo → capturar.
  - Documentar en `docs/performance.md`.
- [ ] Exportar **2 diagramas Dalibo/PEV2** (uno antes, uno después) a `docs/dalibo/`.
- [ ] Habilitar `pg_stat_statements` y publicar las 5 queries más lentas/frecuentes.

**Puntos de atención:**

- Correr `VACUUM ANALYZE` después de la carga antes de medir — si no, las estadísticas están frías y el planner no aprovecha los índices.
- Para GIN sobre JSONB con búsquedas tipo `atributos @> '{"material":"acero"}'`, usar `jsonb_path_ops` (más chico, más rápido para `@>`).

PERFORMANCE

--Sin indice (forzado seq scan)
QUERY PLAN
"Bitmap Heap Scan on venta (cost=95.35..2509.71 rows=8135 width=53) (actual time=0.620..3.325 rows=8049.00 loops=1)"
" Recheck Cond: (fecha_venta >= (now() - '30 days'::interval))"
" Heap Blocks: exact=2209"
" Buffers: shared hit=2218"
" -> Bitmap Index Scan on idx_venta_fecha (cost=0.00..93.31 rows=8135 width=0) (actual time=0.414..0.414 rows=8049.00 loops=1)"
" Index Cond: (fecha_venta >= (now() - '30 days'::interval))"
" Index Searches: 1"
" Buffers: shared hit=9"
"Planning:"
" Buffers: shared hit=3"
"Planning Time: 0.108 ms"
"Execution Time: 3.534 ms"

--Con indice

QUERY PLAN
"Bitmap Heap Scan on venta (cost=95.35..2509.71 rows=8135 width=53) (actual time=0.618..2.323 rows=8049.00 loops=1)"
" Recheck Cond: (fecha_venta >= (now() - '30 days'::interval))"
" Heap Blocks: exact=2209"
" Buffers: shared hit=2218"
" -> Bitmap Index Scan on idx_venta_fecha (cost=0.00..93.31 rows=8135 width=0) (actual time=0.432..0.432 rows=8049.00 loops=1)"
" Index Cond: (fecha_venta >= (now() - '30 days'::interval))"
" Index Searches: 1"
" Buffers: shared hit=9"
"Planning Time: 0.126 ms"
"Execution Time: 2.524 ms"

EXPLAIN ANALYZE SELECT \* FROM venta WHERE fecha_venta > NOW() - INTERVAL '30 days';

QUERY PLAN
"Bitmap Heap Scan on venta (cost=93.39..2503.32 rows=7882 width=53) (actual time=0.593..5.874 rows=8049.00 loops=1)"
" Recheck Cond: (fecha_venta > (now() - '30 days'::interval))"
" Heap Blocks: exact=2209"
" Buffers: shared hit=2221"
" -> Bitmap Index Scan on idx_venta_fecha --> Indexacion Validada (cost=0.00..91.42 rows=7882 width=0) (actual time=0.404..0.405 rows=8049.00 loops=1)"
" Index Cond: (fecha_venta > (now() - '30 days'::interval))"
" Index Searches: 1"
" Buffers: shared hit=12"
"Planning:"
" Buffers: shared hit=107 read=1"
"Planning Time: 1.645 ms"
"Execution Time: 6.095 ms"

Bitmap Heap Scan on venta
→ Bitmap Index Scan on idx_venta_fecha

👉 Traducción:

PostgreSQL SÍ está usando el índice idx_venta_fecha ✅
Pero no hace un Index Scan directo, sino un:
👉 Bitmap Heap Scan
🔍 ¿Qué es un Bitmap Heap Scan?

Es una estrategia intermedia:

Usa el índice:

Bitmap Index Scan
Construye un “mapa” de filas
Luego va a la tabla a buscarlas

👉 Se usa cuando:

hay muchas filas coincidentes (como en tu caso: ~8000)
un Index Scan puro sería menos eficiente

✔️ No hay Seq Scan

👉 Esto es clave:

❌ antes: Seq Scan (mal)
✅ ahora: Bitmap + Index (bien)

---

## Stream D — SQL Avanzado (Lógica de Negocio)

**Responsable:** Gabriel — [@Nubiru](https://github.com/Nubiru)

**Entregables en `sql/04_queries.sql`:**

- [ ] **Window Functions** (al menos 2):
  - Ranking de top vendedores por sucursal (`RANK()` sobre total vendido).
  - Running total mensual por sucursal (`SUM() OVER (PARTITION BY sucursal ORDER BY mes)`).
  - Bonus: promedio móvil de ventas de los últimos 7 días.

- [ ] **CTE Recursiva #1** — Categorías:
  - Dada una categoría raíz, traer todos sus descendientes con la ruta completa (ej. `Construcción > Fijaciones > Tornillos > Autoperforantes`).
  - Contar productos totales por rama (incluyendo subcategorías).

- [ ] **CTE Recursiva #2** — Organigrama:
  - Dado un empleado, traer toda la cadena de mando hacia arriba (hacia el CEO).
  - Dado un gerente, traer todos los subordinados directos e indirectos.

- [ ] Escribir cada query con un comentario que explique **qué pregunta de negocio responde**.

**Puntos de atención:**

- Validar que las CTEs recursivas tengan caso base + caso recursivo claros.
- Usar `LIMIT` en pruebas — algunas recursivas mal escritas explotan la DB.
- Las window functions deben lucirse contra datos reales (los 800k de `venta_linea`) — acá se ven los millones.

---

## Checklist general del grupo (antes de entregar)

- [ ] `sql/01_schema.sql` aplica limpio en DB vacía.
- [ ] `sql/03_seed.sql` carga ≥ 1.000.000 registros sin errores.
- [ ] `sql/02_indexes.sql` crea todos los índices requeridos.
- [ ] `sql/04_queries.sql` corre todas las consultas sin error.
- [ ] DER exportado en `docs/`.
- [ ] `docs/performance.md` con EXPLAIN ANALYZE antes/después.
- [ ] 2 diagramas Dalibo en `docs/dalibo/`.
- [ ] Top-5 de `pg_stat_statements` documentado.
- [ ] README actualizado con instrucciones de reproducción.
