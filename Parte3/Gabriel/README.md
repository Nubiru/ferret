# Parte 3 (Gabriel) — Backend Express + PostgreSQL + Redis

Backend compartido por **dos entregas del Proyecto Integrador**:

| Eje | Parte | Qué cubre | Archivo clave |
|---|---|---|---|
| **III** | Parte 3 | Caché **Cache-Aside** con Redis (lectura) | `cache.js` → `cacheAside()` |
| **IV** | Parte 4 | CRUD + **invalidación selectiva** de caché | `cache.js` → `invalidarNamespace()`, `server.js` |

> ⚠️ Este backend habla con **PostgreSQL (`ferret_db`)** + **Redis** — la base relacional del proyecto.

## Estructura

```
Parte3/Gabriel/
├── server.js        ← Express: GET (cache) + POST/PUT/DELETE (CRUD + invalidación)
├── cache.js         ← ★ núcleo evaluado (Gabriel): cache-aside + invalidación selectiva
├── db.js            ← pool de PostgreSQL (ferret_db)
├── redisClient.js   ← conexión Redis con fallback (si Redis se cae, la app sigue)
└── package.json
```

## Cómo correr

```bash
# 1. Redis (con podman; si el host ya usa 6379, mapear a otro puerto)
podman run -d --name ferret-redis -p 6380:6379 docker.io/library/redis:7

# 2. Backend
cd Parte3/Gabriel
npm install
REDIS_URL=redis://localhost:6380 npm start      # usa ferret_db por socket local
# → [api] escuchando en http://localhost:3000
```

Variables de entorno (todas opcionales): `REDIS_URL`, `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PORT`.

## Endpoints

| Método | Ruta | Qué hace |
|---|---|---|
| `GET` | `/api/productos` | Catálogo (cache-aside). Header `X-Cache: cache\|db` indica HIT/MISS. |
| `POST` | `/api/productos` | Alta → `201`. Body: `{nombre, categoria_id, marca_id?, atributos?}`. Invalida `productos:*`. |
| `PUT` | `/api/productos/:id` | Modifica `nombre`. Invalida `productos:*`. |
| `DELETE` | `/api/productos/:id` | Baja **lógica** (`activo=false`, nunca `DELETE FROM`). Invalida `productos:*`. |

## ¿Por qué Parte 3 y Parte 4 están en la misma carpeta?

Porque la **consigna de Parte 4 lo pide así**: *"Deberán **agregar a su archivo `index.js`** … al menos tres nuevos endpoints."* La Parte 4 (Eje IV) **extiende el mismo backend** de la Parte 3 (Eje III) — es un único `server.js`. Separar el código en dos carpetas obligaría a duplicar el servidor. Por eso conviven aquí, claramente etiquetados.

### Parte 4 (Eje IV) — requisito de la consigna → dónde está implementado

| Requisito Parte 4 | Implementación |
|---|---|
| **1. CREATE (POST)** — body JSON, `201` + registro insertado | `server.js` → `POST /api/productos` |
| **2. UPDATE (PUT)** — id en `req.params`, valor en body | `server.js` → `PUT /api/productos/:id` |
| **3. DELETE lógico** — columna `activo`, `UPDATE` (nunca `DELETE FROM`) | `server.js` → `DELETE /api/productos/:id` |
| **4. Invalidación selectiva** — `keys()`+`del()`, prohibido `flushDb()` | `cache.js` → `invalidarNamespace('productos')` |
| **Manejo de errores** — `400` / `404` | validaciones en cada ruta de `server.js` |

## Validación end-to-end (hecha contra Redis + ferret_db reales)

```
GET ×1            → X-Cache: db      (MISS, 100 productos desde PostgreSQL)
GET ×2            → X-Cache: cache   (HIT, sin tocar la DB)
POST nuevo        → 201 + cache_invalidada:1
GET ×3            → X-Cache: db      (la caché se invalidó → vuelve a la DB)
Invalidación selectiva → sesion:usuario:99 SOBREVIVE; solo productos:* se borra
DELETE            → activo:false (baja lógica)
POST sin nombre   → 400
PUT id inexistente→ 404
```

## Evidencia para la entrega (Parte 4)

- **Colección Postman lista para importar:** [`ferret-parte4.postman_collection.json`](ferret-parte4.postman_collection.json) — trae POST, PUT, DELETE y los casos 400/404 ya armados.
- **Transcript de la corrida real** (curl contra Redis + ferret_db): [`EVIDENCIA.md`](EVIDENCIA.md).
- ⬜ **Falta (paso manual con GUI):** importar la colección, hacer *Send* en POST/PUT/DELETE y sacar las **3–4 capturas** → guardarlas en `evidencia/`. (Esto necesita la app Postman; no se puede automatizar.)

Checklists oficiales: [`../../docs/checklists/eje3-redis.md`](../../docs/checklists/eje3-redis.md) y [`../../docs/checklists/eje4-crud.md`](../../docs/checklists/eje4-crud.md).
