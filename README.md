# FeRReT — Sistema de Gestión de Ferretería

Proyecto Integrador **Parte 1** — Unidad Curricular **Base de Datos III**, Eje I (Optimización y SQL Avanzado).

## Equipo

| Integrante | GitHub | Rol |
|---|---|---|
| Federico | [@Frederick1824](https://github.com/Frederick1824) | 🧱 Modelado & DER |
| Lautaro  | [@LautaroAi](https://github.com/LautaroAi)         | 📦 Carga masiva |
| Mariano  | [@marianof87](https://github.com/marianof87)       | ⚡ Indexación & Performance |
| Gabriel  | [@Nubiru](https://github.com/Nubiru)               | 🧠 SQL Avanzado |

Detalle de cada rol y checklist en `TAREAS.md`.

## El problema

**FeRReT** es una cadena de ferretería grande con **5 sucursales + 1 depósito central**, flota propia de camiones para mover mercadería, inventario complejo con decenas de miles de SKUs, y ~150–250 empleados organizados jerárquicamente (ejecutivos, administrativos, cajeros, vendedores, transportistas, compras, guardias).

Operaciones que el sistema debe soportar:

- **Catálogo jerárquico** de productos (categorías anidadas: ej. Construcción → Fijaciones → Tornillos → Autoperforantes).
- **SKUs / variantes** por producto (mismo producto, distintas presentaciones, precios y códigos de barra).
- **Stock multi-sucursal** y movimientos entre depósito central y sucursales usando la flota propia.
- **Ventas mayoristas y minoristas** con líneas de detalle.
- **Compras a proveedores** (órdenes y recepciones).
- **Alquiler de herramientas** con control de ventanas horarias (sin solapamientos).
- **Promociones** con vigencia controlada.
- **Organigrama** jerárquico de empleados.

## Stack

- **PostgreSQL** (≥ 14).
- **DBeaver** como cliente de modelado y administración.
- Extensiones usadas: `btree_gist`, `pg_trgm` (opcional para FTS), `pg_stat_statements`.
- Visualización de planes: **Dalibo / PEV2**.

## Requisitos oficiales cubiertos (consigna)

Ver `propuesta_proyecto.md` / `proyecto_integrador.docx` para el detalle. Resumen de cómo cada requisito se mapea en FeRReT:

| Requisito | Dónde se implementa |
|---|---|
| DER 3NF | `sql/01_schema.sql` + `docs/DER.*` |
| ≥ 1.000.000 registros | `venta_linea` (~800k) + `movimiento_stock` (~150k) + `sku` (~80k) + `cliente` (~150k) + más |
| B-Tree | PKs, FKs, `venta.fecha_venta`, `movimiento_stock.fecha` |
| Hash | `cliente.email`, `sku.codigo_barras` (igualdad exacta en texto largo) |
| GIN | `producto.atributos` (JSONB) — búsqueda por atributos (material, medida, etc.) |
| GiST | `alquiler.ventana` (tsrange) con EXCLUDE; `promocion.vigencia` (daterange) con EXCLUDE |
| EXPLAIN ANALYZE | `docs/performance.md` — comparativa antes/después |
| Dalibo PEV2 | 2 diagramas exportados en `docs/dalibo/` |
| pg_stat_statements | Top-5 consultas — `docs/performance.md` |
| Window Functions | `sql/04_queries.sql` (ranking vendedores, running totals) |
| CTE Recursiva | `sql/04_queries.sql` — dos jerarquías: **categorías** y **organigrama de empleados** |

## Estructura del repositorio

```
ferret/
├── README.md                 ← este archivo
├── TAREAS.md                 ← división de trabajo y checklist por rol
├── propuesta_proyecto.md     ← consigna original (no tocar)
├── proyecto_integrador.docx  ← consigna original (no tocar)
├── docs/
│   ├── DER.*                 ← diagrama exportado (imagen/PDF) desde DBeaver
│   ├── performance.md        ← EXPLAIN ANALYZE antes/después, top-5 queries
│   └── dalibo/               ← diagramas PEV2
├── sql/
│   ├── 01_schema.sql         ← DDL normalizado 3NF
│   ├── 02_indexes.sql        ← B-Tree / Hash / GIN / GiST + EXCLUDE
│   ├── 03_seed.sql           ← generación masiva de datos (≥ 1M)
│   ├── 04_queries.sql        ← window functions + CTEs recursivas
│   └── 05_triggers.sql       ← automatización de stock y auditoría de movimientos (triggers)
└── scripts/                  ← generadores auxiliares (Python + Faker si hace falta)
```

## Cómo correrlo (una vez que esté todo listo)

```bash
createdb ferret
psql -d ferret -f sql/01_schema.sql
psql -d ferret -f sql/02_indexes.sql
psql -d ferret -f sql/03_seed.sql   # demora varios minutos
psql -d ferret -f sql/04_queries.sql
psql -d ferret -f sql/05_triggers.sql
```
Los EXPLAIN comparativos de Stream C se corren a mano desde `sql/04_queries.sql` para poder copiar los planes JSON a [Dalibo PEV2](https://explain.dalibo.com/).

---

## Checklist: Integración de Caché con Redis (Proyecto Integrador - Parte 3)

Esta sección detalla el progreso de la implementación de la capa de persistencia políglota utilizando Redis como almacén clave-valor en memoria.

HAGA FOCO EN:
. Implementación del Patrón Cache-Aside
- [x] **Consulta a la Caché:** El endpoint verifica primero si la clave existe en Redis.
- [x] **Cache HIT:** Si el dato existe, se retorna inmediatamente al cliente (se evita ir a la DB).
- [x] **Cache MISS (Consulta a la DB):** Si el dato NO existe, el sistema realiza la consulta a la base de datos principal (PostgreSQL, MongoDB, etc.).
- [x] **Población de la Caché:** Guardamos el resultado obtenido de la base de datos en Redis.
- [x] Devolver la respuesta final al cliente en todos los flujos.

### Configuración e Inicio de Redis y Backend

1. **Iniciar un servidor Redis local** (por ejemplo, con Docker o Podman):
   ```bash
   docker run -d --name ferret-redis -p 6379:6379 redis:alpine
   ```

2. **Instalar las dependencias e iniciar el backend**:
   ```bash
   cd eje3-mean/backend
   npm install
   node server.js
   ```

3. **Verificar el flujo de Caché**:
   - En la primera petición a `http://localhost:3000/api/reporte-ventas` (Cache MISS), se consultará MongoDB, se guardará en Redis bajo la clave `reports:sales_by_category` con un TTL de 60 segundos, y se retornará.
   - En peticiones subsiguientes dentro del período de 60 segundos (Cache HIT), la respuesta se servirá de forma ultra-rápida directamente desde Redis.

