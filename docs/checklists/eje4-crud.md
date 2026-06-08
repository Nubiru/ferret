# Checklist — Proyecto Integrador · Parte 4 / Eje IV (CRUD + Invalidación Selectiva)

API REST sobre PostgreSQL con caché Redis consistente. Implementado en [`Parte3/Gabriel/`](../../Parte3/Gabriel/).
Entidad elegida: **`producto`** (ya tiene columna `activo` → baja lógica sin tocar el schema).

> **Reparto:** backend completo de Parte 4 = **Gabriel** — CRUD (`server.js`) + invalidación selectiva (`cache.js`),
> sobre el mismo backend de la Parte 3 (la consigna pide *"agregar endpoints a su `index.js`"*).

### Endpoints (≥ 3 sobre las tablas principales)

- [x] **1. CREATE (POST `/api/productos`)** — datos en el Body (JSON), responde **201 Created** + el registro insertado.
- [x] **2. UPDATE (PUT `/api/productos/:id`)** — ID en la URL (`req.params`), nuevo valor en el Body.
- [x] **3. DELETE (Baja Lógica)** — **prohibido `DELETE FROM`**; usa `UPDATE ... SET activo = false`.

### 4. Invalidación Selectiva de Caché

- [x] Cualquier escritura en PostgreSQL invalida la caché del catálogo (POST/PUT/DELETE → `invalidarNamespace`).
- [x] **Prohibido `flushDb()`** — se borran solo las llaves del namespace `productos:*` con `keys()` + `del()`.
- [x] Las sesiones / otros datos en memoria **sobreviven** *(validado: `sesion:usuario:99` queda intacta tras invalidar `productos:*`)*.

### Testing y Validación con Postman

- [x] Manejo de errores: la API devuelve **400** (body inválido) y **404** (no encontrado) *(validado, ver EVIDENCIA.md)*.
- [x] **Colección Postman lista:** [`Parte3/Gabriel/ferret-parte4.postman_collection.json`](../../Parte3/Gabriel/ferret-parte4.postman_collection.json) (POST/PUT/DELETE + 400/404 pre-armados).
- [ ] ⏳ **Capturas:** importar la colección, hacer *Send* y sacar 3–4 screenshots → `Parte3/Gabriel/evidencia/`. *(paso manual con GUI — no se puede automatizar).*

### Formato de Entrega

- [x] Repo actualizado con el backend (`Parte3/Gabriel/`) — mergeado en `main`.
- [ ] Archivo con las capturas de Postman (`Parte3/Gabriel/evidencia/`).

---

**Cómo correr y probar en Postman:** ver [`Parte3/Gabriel/README.md`](../../Parte3/Gabriel/README.md).
