# Checklist — Proyecto Integrador · Parte 3 / Eje III (Caché con Redis)

Capa de persistencia políglota: Redis como almacén clave-valor en memoria, patrón **Cache-Aside**.
Implementado en [`eje4-api/`](../../eje4-api/) (mismo backend que comparte con el Eje IV).

> **Reparto:** lógica de caché (`cache.js`) = **Gabriel**. Scaffold Express/pg/redis = equipo.
> ⚠️ **Ojo con el nombre:** este es el Eje III **real** (Redis). El MongoDB/MEAN (`eje3-mean/`) es un **TP aparte**, no este eje.

### 1. Fase de Diseño y Selección

- [x] Identificamos endpoint(s) estratégico(s) para cachear (alta lectura, baja escritura).
- [x] Listado de endpoints cacheados:
  - *Endpoint 1:* `GET /api/productos` (catálogo de productos activos, query con JOINs + agregación).
- [x] El caso soporta **consistencia eventual** (catálogo: tolera 60 s de desactualización; TTL + invalidación al escribir).

### 2. Configuración (Setup)

- [x] Instalamos el cliente de Redis (`redis` en `eje4-api/package.json`).
- [x] Conexión exitosa con el servidor de Redis (`redisClient.js`, validado contra Redis real vía podman).
- [x] **Manejo de Errores (Fallback):** si Redis se cae, la app registra el error y sigue consultando PostgreSQL (`cacheAside` → rama `redis-caido`).

### 3. Implementación del Patrón Cache-Aside

- [x] **Consulta a la Caché:** el endpoint verifica primero la clave en Redis.
- [x] **Cache HIT:** si existe, se retorna sin tocar la DB *(validado: 2ª request → `origen=cache`)*.
- [x] **Cache MISS (Consulta a la DB):** si no existe, consulta PostgreSQL *(validado: 1ª request → `origen=db`)*.
- [x] **Población de la Caché:** se guarda el resultado de la DB en Redis con TTL.
- [x] Devolver la respuesta final al cliente en todos los flujos.

### 4. Buenas Prácticas Técnicas

- [x] **Nomenclatura (Namespacing):** claves con `:` (`productos:catalogo`, `productos:*`).
- [x] **Asignación de TTL:** toda clave tiene TTL (`TTL_SEGUNDOS = 60` en `cache.js`).

---

**Cómo correr y validar:** ver [`eje4-api/README.md`](../../eje4-api/README.md).
