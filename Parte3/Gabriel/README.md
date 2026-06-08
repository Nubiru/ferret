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

## Pendiente (paso manual del equipo)

- [ ] **Evidencia Postman** (Eje IV): 3–4 capturas de POST/PUT/DELETE con respuestas 200/201 → guardar en `docs/postman/`.

Checklists oficiales: [`docs/checklists/eje3-redis.md`](../docs/checklists/eje3-redis.md) y [`docs/checklists/eje4-crud.md`](../docs/checklists/eje4-crud.md).
