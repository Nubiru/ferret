# Guía de Defensa — Proyecto Integrador FeRReT (Base de Datos III)

> Ayuda-memoria para la presentación oral. **No es para leer**: es para
> que cada uno defienda **decisiones de arquitectura**. Sigue las 5
> secciones de la guía de la profe. Cada sección tiene: **qué mostrar**,
> **qué decir (en criollo)**, **el archivo/objeto real**, y **preguntas
> que puede hacer + cómo contestarlas**.

## El sistema en una frase

**FeRReT** es el sistema de gestión de una **cadena de ferreterías con
varias sucursales**: catálogo de productos, stock por sucursal, ventas y
reposición entre depósitos. Stack: **PostgreSQL** (núcleo transaccional)
+ **Redis** (caché de lectura) + **API REST en Node/Express**.

## Quién hizo qué (por si la profe pregunta autoría)

| Eje | Bloque | Responsable | Archivo |
|---|---|---|---|
| I | Schema 3NF + seed | equipo | `Parte1/01_schema.sql`, `03_seed.sql` |
| I | Índices + EXPLAIN antes/después | Mariano | `Parte1/02_indexes.sql`, `04_queries.sql` |
| I | SQL avanzado (window + CTE) | **Gabriel** | `Parte1/05_advanced_sql.sql` |
| II·A | Función + Procedure (%TYPE/%ROWTYPE) | Federico | `Parte2/05_procedures.sql` |
| II·B | Transacciones (SAVEPOINT/ROLLBACK) | **Gabriel** | `Parte2/07_transacciones.sql` |
| II·C | Auditoría (GET STACKED DIAGNOSTICS) | Lautaro | `Parte2/08_auditoria_y_forense.sql` |
| II·D | Seguridad (SECURITY DEFINER) | **Gabriel** | `Parte2/06_seguridad_hardening.sql` |
| II·E | Triggers | Mariano | `Parte2/09_triggers.sql` |
| III | Caché Cache-Aside | **Gabriel** | `Parte3/Gabriel/cache.js` |
| IV | CRUD + invalidación selectiva | **Gabriel** | `Parte3/Gabriel/server.js` + `cache.js` |

---

## 1 · El Problema y el Diseño Relacional

**Qué mostrar:** el DER (`docs/DER/`) y mencionar el volumen de datos.

**Qué decir:**
- Modelo en **3NF**, 13 tablas. Dos **jerarquías recursivas** (auto-referencia):
  - `categoria.padre_id` → árbol de rubros (3 niveles).
  - `empleado.supervisor_id` → organigrama (CEO → gerentes → mandos → staff).
- **Data seeding (números reales):** ≈ **1,74 M de registros**. Los gruesos:
  - `venta_linea` → **600.000**
  - `stock` → **480.000** (SKU × sucursal)
  - `venta` → **200.000**
  - `cliente` → **100.000** · `sku` → **80.000** · `producto` → **30.000**

**Preguntas posibles:**
- *¿Por qué 3NF y no desnormalizar?* → Integridad y no duplicar datos; la
  performance la resolvemos con **índices** (Eje I) y **caché** (Eje III),
  no rompiendo la normalización.
- *¿Dónde está la recursividad?* → En las dos CTE recursivas del Eje I
  (categorías y organigrama), que recorren esas auto-referencias.

---

## 2 · SQL Avanzado y Estrategia de Indexación

**Qué mostrar:** `Parte1/05_advanced_sql.sql`, los índices de
`02_indexes.sql`, y un "antes/después" con los diagramas de `docs/dalibo/`.

**Estrategia de índices (la clave: el tipo correcto para cada acceso):**
- **B-Tree** (rango/orden): `idx_venta_fecha`, `idx_venta_sucursal_fecha`,
  `idx_venta_cliente`, `idx_venta_linea_sku`. Son los accesos por fecha y
  por FK que más pegan en los reportes.
- **Hash** (igualdad exacta): `idx_cliente_email_hash`, `idx_sku_codbarras_hash`.
  Email y código de barras se buscan por `=`, nunca por rango → Hash es más
  chico y directo que B-Tree para ese caso.
- **GIN** (JSONB): `idx_producto_atributos_gin` sobre `producto.atributos`.
  Permite buscar **dentro** del JSON con el operador `@>`
  (ej. `atributos @> '{"material":"acero"}'`).

**Antes / Después (el caso a contar):** sin índice, una búsqueda de ventas
por fecha hace **Seq Scan** sobre 200.000 filas; con `idx_venta_fecha` pasa
a **Index Scan**. Mostrar los dos planes (PEV2 / Dalibo en `docs/dalibo/`).

**Window Functions y CTE (Eje I·E):**
- `RANK() OVER (PARTITION BY sucursal ORDER BY SUM(total) DESC)` → **top-3
  vendedores por sucursal**.
- `SUM(...) OVER (ORDER BY mes)` + `AVG(...) OVER (... ROWS BETWEEN 2
  PRECEDING AND CURRENT ROW)` → **acumulado mensual + promedio móvil 3 meses**.
- **CTE recursivas:** `arbol_categorias` (jerarquía completa con ruta y
  nivel) y `cadena_mando` (de un empleado hasta el CEO).
- **Joya para mostrar:** la query 5 combina **GIN + window** ("top-10
  productos de acero más vendidos") → demuestra que el índice se usa en
  lógica de negocio real, no de adorno.

**Preguntas posibles:**
- *¿Por qué Hash y no B-Tree en email?* → Solo se consulta por igualdad; no
  necesitamos orden ni rango, así que Hash es el índice justo.
- *¿Cuándo NO conviene un índice?* → En tablas con mucha escritura o
  columnas de baja cardinalidad: el índice se mantiene en cada INSERT/UPDATE
  y puede costar más de lo que ahorra.
- *¿El GIN no es caro?* → Es más pesado de mantener, pero es el único que
  resuelve búsquedas dentro del JSONB; lo justificamos por el caso de uso.

---

## 3 · La "Thick Database": Lógica y Seguridad

**Idea fuerza:** la lógica crítica **vive en la base**, no en el backend.
Node orquesta; PostgreSQL garantiza las reglas.

**a) Procedimiento + Transacciones — `registrar_venta_completa` (`07_transacciones.sql`):**
- Inserta venta + línea + descuenta stock como **una sola unidad atómica**
  (`COMMIT` / `ROLLBACK` explícitos): *o se guarda todo, o no se guarda nada*.
- **SAVEPOINT (lo más fino para defender):** la **reposición automática**
  desde el depósito central es un paso secundario "propenso a fallar". Va en
  un **subbloque `BEGIN ... EXCEPTION ... END`**, que en PL/pgSQL **es** un
  savepoint: si la reposición falla, se revierte **solo ese subbloque**
  (ROLLBACK TO SAVEPOINT) y **la venta del cliente igual se confirma**.
  > Dato técnico que suma: en PL/pgSQL no se puede escribir `SAVEPOINT`
  > literal dentro de una rutina; el subbloque es el mecanismo equivalente,
  > y así es como Postgres implementa los savepoints internamente.

**b) Auditoría / "caja negra" — `audit_logs` + `sp_agregar_producto_a_sku` (`08_auditoria_y_forense.sql`):**
- Bloque `EXCEPTION WHEN OTHERS` + **`GET STACKED DIAGNOSTICS`** captura
  `RETURNED_SQLSTATE`, `MESSAGE_TEXT`, `PG_EXCEPTION_DETAIL` y
  `PG_EXCEPTION_CONTEXT`, y los guarda en `audit_logs`.
- El procedure **no explota**: devuelve `OUT p_resultado/p_mensaje` para que
  la app se entere del error de forma controlada (se prueba metiendo un SKU
  duplicado → queda registrado en el log).

**c) Seguridad / Privilegio Mínimo — `ajustar_stock_admin` (`06_seguridad_hardening.sql`):**
- **`SECURITY DEFINER`**: la función corre con los permisos del **dueño**,
  no del que la invoca → un operador con permisos mínimos ejecuta una
  operación administrativa sin tener acceso directo a la tabla.
- **`SET search_path = pg_catalog, public`**: blinda contra *search_path
  injection* (que alguien cree objetos truchos para secuestrar la función).
- **Abstracción:** rol `ferret_operador` con `REVOKE ALL` sobre `stock`, y
  `GRANT EXECUTE` solo sobre la función. **Tablas privadas, funciones públicas.**

**d) Trigger — `trg_descontar_stock_venta` (`09_triggers.sql`):**
- `AFTER INSERT` sobre `venta_linea` dispara `descontar_stock_venta()`, que
  descuenta stock y registra el movimiento automáticamente.

**Preguntas posibles:**
- *¿SECURITY DEFINER no es peligroso?* → Lo es si no fijás el `search_path`;
  por eso lo fijamos explícitamente. Es el patrón recomendado.
- *¿Definer vs Invoker?* → Invoker corre con permisos del que llama (default);
  Definer, con los del dueño. Usamos Definer para **delegar** lo crítico.
- *¿Por qué lógica en la DB y no en Node?* → Atomicidad e integridad
  garantizadas por el motor, una sola fuente de verdad, y la regla se cumple
  aunque mañana cambie el cliente (otra app, otro lenguaje).

---

## 4 · Arquitectura Híbrida: PostgreSQL + Redis

**Qué mostrar:** `Parte3/Gabriel/cache.js` (función `cacheAside`) y el
`GET /api/productos` de `server.js`.

**Persistencia políglota:** PostgreSQL = verdad/durabilidad; Redis = caché
en memoria para lecturas calientes. Cada uno para lo que es bueno.

**Patrón Cache-Aside (Lazy Loading), tal cual la consigna:**
1. La API pide la clave a Redis.
2. **HIT** → devuelve de Redis, no toca Postgres.
3. **MISS** → consulta Postgres (la query cara con JOINs + agregación).
4. Puebla Redis con **TTL de 60s**.
5. Devuelve el dato.
- Se ve en vivo con el header **`X-Cache: cache|db`** y el campo
  `"origen"` en la respuesta (primer GET = `db`, segundo = `cache`).

**Qué cacheamos y por qué:** el **catálogo de productos** — query con varios
JOINs + `GROUP BY` (cara), **mucha lectura y poca escritura**, y tolera
consistencia eventual de segundos. Es el caso ideal de caché.

**Resiliencia (lo que distingue el trabajo):** si **Redis se cae, la app no
se cae** (`redisClient.js`): registra el error, baja una bandera y va directo
a Postgres. El `cacheAside` devuelve `origen: 'db (redis-caido)'`.

**Preguntas posibles:**
- *¿Por qué TTL y no cachear para siempre?* → "Una caché sin vencimiento es
  un bug de memoria esperando a pasar": el TTL acota la inconsistencia y la
  memoria.
- *¿Qué pasa si cambian los datos antes de que venza el TTL?* → Para eso está
  la **invalidación selectiva** del Eje IV: en cada escritura purgamos la
  clave (ver sección 5).
- *¿Por qué Redis y no una tabla de caché en Postgres?* → En memoria, sub-ms,
  y descarga al motor relacional de las lecturas repetidas.

---

## 5 · Consolidación Full Stack: la API REST (Eje IV)

**Qué mostrar:** **Postman en vivo** (colección
`Parte3/Gabriel/ferret-parte4.postman_collection.json`) — POST, PUT, DELETE.

**Endpoints (todos sobre `producto`, ver `server.js`):**
- `POST /api/productos` → crea, responde **201** + el registro.
- `PUT /api/productos/:id` → modifica (id en la URL, valor en el body) → **200**.
- `DELETE /api/productos/:id` → **baja lógica**.
- Manejo de errores: **400** (body inválido) y **404** (no existe).

**Baja Lógica vs Física (punto que la profe pide explícito):**
- El DELETE **no borra**: hace `UPDATE producto SET activo = false`. La fila
  **sigue en Postgres** (se verifica con `SELECT ... WHERE id=...` → `activo = f`).
- Por qué: preservar histórico, no romper las FKs de ventas que referencian
  ese producto, y poder auditar/restaurar.

**Endpoint extra — `POST /api/venta` (nexo Eje IV ↔ Eje II):**
- No tiene lógica de negocio en Node: hace `CALL registrar_venta_simple(...)`
  (procedure del Eje II·A). El precio, el control de stock y la atomicidad los
  pone la **base**. Frase para la defensa: *"la API orquesta, la base decide"*.
- Si el procedure hace `RAISE` (stock insuficiente / SKU inexistente), el
  endpoint responde **400** con ese mensaje. Es la Thick DB validando, no Node.

**Invalidación Selectiva (el detalle que más suma):**
- En POST/PUT/DELETE se llama `invalidarNamespace('productos:*')`
  (`cache.js`): hace **`keys('productos:*')` + `del(...)`** — borra **solo**
  el namespace del catálogo.
- **Prohibido `flushDb()`**: se demuestra dejando una clave de otro namespace
  (`sesion:usuario:99`) que **sobrevive** a la invalidación. Se borró el
  catálogo, no media base.

**Preguntas posibles:**
- *¿`KEYS` no bloquea Redis?* → En datasets enormes sí; en producción se usa
  `SCAN`. Para el volumen de este TP, `KEYS` cumple y es lo que pide la
  consigna (está comentado en `cache.js`).
- *¿Por qué invalidar y no actualizar la caché en el escritura?* → Invalidar
  es más simple y seguro (no podés dejar la caché en un estado inconsistente);
  la próxima lectura repuebla con el dato fresco (Cache-Aside).
- *¿El POST no debería usar el procedure de la DB?* → Ver "Decisiones de
  equipo" abajo: tenemos esa variante (`registrar_venta_simple`) y la podemos
  mostrar como nexo con el Eje II.

---

## Preguntas transversales (las "trampa")

- **"Mostrame que es atómico de verdad"** → `registrar_venta_completa`: forzá
  stock insuficiente y mostrá que NO queda venta a medias (ROLLBACK).
- **"¿La API con qué usuario se conecta?"** → Con el rol **`ferret_api`**
  (`Parte3/Gabriel/rol_api.sql`), de privilegio mínimo: puede leer el catálogo
  y escribir en `producto`, pero **no** puede borrar físicamente ni tocar
  `venta`/`stock` directos. **Es el default**: `npm start` ya se conecta como
  `ferret_api` (no hay que exportar nada). Demo en vivo con `SET ROLE
  ferret_api`. Tanto la venta como la lectura de la venta creada van por
  **delegación** vía funciones `SECURITY DEFINER` — el rol solo tiene `EXECUTE`.
- **"¿Y si se cae Redis en plena demo?"** → Perfecto, lo cortás a propósito:
  la app sigue sirviendo desde Postgres (`origen: db (redis-caido)`).
- **"¿Esto escala?"** → Índices para el acceso, caché para la lectura caliente,
  lógica en la DB para integridad. Lo que falta para producción está
  identificado (SCAN en vez de KEYS, rol de app en la API).

---

## Cosas a tener en cuenta ANTES de defender (gaps honestos)

1. **Cargar el resto del Eje II en la base de la demo.** Ya está cargado
   `Parte2/05_procedures.sql` (`calcular_subtotal` + `registrar_venta_simple`,
   que usa el endpoint de venta). Los demás objetos de la Parte 2 (triggers,
   `audit_logs`, `ajustar_stock_admin`, `registrar_venta_completa`) **siguen
   sin cargar** en el `ferret_db` de Gabriel. Si la profe quiere verlos correr:
   ```bash
   for f in Parte2/07_transacciones.sql Parte2/06_seguridad_hardening.sql \
            Parte2/08_auditoria_y_forense.sql Parte2/09_triggers.sql; do
     psql -d ferret_db -f "$f"; done
   ```
   > ⚠️ OJO con el trigger: `trg_descontar_stock_venta` (09) descuenta stock al
   > insertar en `venta_linea`, y `registrar_venta_completa` (07) **también**
   > descuenta stock a mano → si cargás los dos, el stock se descuenta DOBLE.
   > Para la demo, mostrá uno u otro mecanismo, no ambos a la vez.
2. ~~La API se conecta como superusuario.~~ **CERRADO.** La API se conecta
   **por defecto** como el rol `ferret_api` (`Parte3/Gabriel/rol_api.sql`) de
   privilegio mínimo — `npm start` ya corre así, sin variables. Único requisito:
   correr `psql -d ferret_db -f rol_api.sql` una vez para crear el rol. El relato
   de la sección 3 es real punta a punta.
3. **`pg_stat_statements` top-5 (Eje I·D.3):** requiere
   `shared_preload_libraries` + reinicio de Postgres (pendiente de Mariano).
4. **Capturas de Postman (Eje IV):** único paso manual que falta —
   ver `Parte3/Gabriel/evidencia/COMO_SACAR_CAPTURAS.md`.

---

## Decisiones de equipo abiertas

- **Dos soluciones de Parte 3/Redis:** `Parte3/Gabriel/` (catálogo +
  invalidación selectiva, integra Eje III y IV en un backend) y
  `Parte3/Lautaro/` (catálogo con paginación + producto por id). Decidir cuál
  es "la oficial" o presentarlas como dos enfoques.
- **POST vía stored procedure (propuesta de Lautaro):** ✅ **incorporado**
  como `POST /api/venta` en `server.js` (llama a `registrar_venta_simple`). El
  CRUD de `producto` sigue siendo el caso canónico de POST/PUT/DELETE + baja
  lógica; el de venta es el **endpoint extra** que conecta Eje IV ↔ Eje II.

---

## Ayuda-memoria express (para tener al lado)

- **Sistema:** cadena de ferreterías (catálogo, stock, ventas, reposición).
- **Volumen:** ≈1,74M filas (venta_linea 600k, stock 480k, venta 200k).
- **Índices:** B-Tree (fechas/FK) · Hash (email, cod_barras) · GIN (JSONB).
- **Avanzado:** RANK top-3 vendedores · running total + media móvil · 2 CTE recursivas.
- **Thick DB:** atomicidad (COMMIT/ROLLBACK) · SAVEPOINT = subbloque · GET
  STACKED DIAGNOSTICS → audit_logs · SECURITY DEFINER + search_path fijo · trigger de stock.
- **Caché:** Cache-Aside, TTL 60s, cacheamos el catálogo, fallback si Redis muere.
- **API:** POST 201 / PUT / DELETE baja lógica (activo=false) / invalidación
  selectiva keys()+del(), nunca flushDb (sesion:* sobrevive).
- **API extra:** POST /api/venta delega en el procedure (Eje IV↔II).
- **Privilegio mínimo:** la API corre como `ferret_api` (rol_api.sql), no super-
  usuario: lee catálogo, escribe producto, NO borra físico ni toca venta/stock.
