# Checklist — Proyecto Integrador · Parte 4 / Eje IV (CRUD + Invalidación Selectiva)

API REST sobre PostgreSQL con caché Redis consistente. Implementado en [`Parte3/Gabriel/`](../../Parte3/Gabriel/).
Entidad elegida: **`producto`** (ya tiene columna `activo` → baja lógica sin tocar el schema).

> **Reparto:** invalidación selectiva (`cache.js`) = **Gabriel**. Scaffold + CRUD plano (`server.js`) = equipo
> (Gabriel dejó una base funcional y validada para que el compañero la tome).

### Endpoints (≥ 3 sobre las tablas principales)

- [x] **1. CREATE (POST `/api/productos`)** — datos en el Body (JSON), responde **201 Created** + el registro insertado.
- [x] **2. UPDATE (PUT `/api/productos/:id`)** — ID en la URL (`req.params`), nuevo valor en el Body.
- [x] **3. DELETE (Baja Lógica)** — **prohibido `DELETE FROM`**; usa `UPDATE ... SET activo = false`.

### 4. Invalidación Selectiva de Caché

- [x] Cualquier escritura en PostgreSQL invalida la caché del catálogo (POST/PUT/DELETE → `invalidarNamespace`).
- [x] **Prohibido `flushDb()`** — se borran solo las llaves del namespace `productos:*` con `keys()` + `del()`.
- [x] Las sesiones / otros datos en memoria **sobreviven** *(validado: `sesion:usuario:99` queda intacta tras invalidar `productos:*`)*.

### Testing y Validación con Postman

- [x] Manejo de errores: la API devuelve **400** (body inválido) y **404** (no encontrado) *(validado por código)*.
- [ ] ⏳ **Evidencia:** 3–4 capturas de Postman ejecutando POST, PUT y DELETE con respuestas 200/201. *(paso manual — falta sacar las screenshots y guardarlas en `docs/postman/`).*

### Formato de Entrega

- [ ] Repo actualizado con el backend (`Parte3/Gabriel/`). *(falta el commit/PR)*
- [ ] Archivo con las capturas de Postman.

---

**Cómo correr y probar en Postman:** ver [`Parte3/Gabriel/README.md`](../../Parte3/Gabriel/README.md).
