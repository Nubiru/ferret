# Evidencia Parte 4 (Eje IV) — corrida real

Transcript de una corrida real del backend (`Parte3/Gabriel/server.js`) contra **Redis** (podman, puerto 6380) y **PostgreSQL `ferret_db`** (30.000 productos). Sirve como respaldo; la entrega oficial pide además las **capturas de Postman** (ver `evidencia/` y la colección [`ferret-parte4.postman_collection.json`](ferret-parte4.postman_collection.json)).

## Cómo reproducir

```bash
podman run -d --name ferret-redis -p 6380:6379 docker.io/library/redis:7
cd Parte3/Gabriel && npm install
REDIS_URL=redis://localhost:6380 npm start
# en otra terminal: importar la colección Postman y hacer Send en orden 1→4b
```

## Resultado (curl)

```
[1] CREATE  — POST /api/productos
    → HTTP 201
    {"producto":{"id":30002,"nombre":"Taladro Percutor X9","categoria_id":1,
      "marca_id":1,"activo":true,"fecha_alta":"...Z"}, "cache_invalidada":...}

[2] UPDATE  — PUT /api/productos/30002   (id en URL, nuevo valor en body)
    → HTTP 200
    {"producto":{"id":30002,"nombre":"Taladro Percutor X9 PRO",...}}

[3] DELETE lógico — DELETE /api/productos/30002
    → HTTP 200
    {"baja_logica":{"id":30002,"nombre":"Taladro Percutor X9 PRO","activo":false}}
    verificación en PostgreSQL:
        SELECT id,nombre,activo FROM producto WHERE id=30002;
        30002 | Taladro Percutor X9 PRO | f      ← sigue existiendo, NO se borró físicamente

[4a] ERROR 400 — POST sin "nombre"
    → HTTP 400   {"error":"nombre y categoria_id son obligatorios"}

[4b] ERROR 404 — PUT a id inexistente (999999999)
    → HTTP 404   {"error":"producto no encontrado"}

[5] INVALIDACIÓN SELECTIVA
    productos:*  en Redis tras los cambios → (vacío, purgado por del())
    sesion:usuario:99                      → "token-abc"   ← SOBREVIVE
    => se borró solo el namespace del catálogo, NO se usó flushDb()
```

## Endpoint extra — POST /api/venta (delegación en el procedure, Eje IV↔II)

```
POST /api/venta {cliente_id:1,empleado_id:1,sucursal_id:1,sku_id:1,cantidad:2}
    → HTTP 201  {"mensaje":"Venta registrada por el procedure",
                 "venta":{"id":"...","total":"532.62",...}}
POST /api/venta ... cantidad:999999999  (stock imposible)
    → HTTP 400  {"error":"Stock insuficiente"}   ← lo lanza el RAISE del procedure, no Node
POST /api/venta {cliente_id:1}  (body incompleto)
    → HTTP 400  {"error":"faltan campos: ..."}
```

## Privilegio mínimo — la API como rol `ferret_api` (no superusuario)

Verificado con `SET ROLE ferret_api` (ver `rol_api.sql`):
```
SELECT count(*) FROM producto;          → 30000        (OK: tiene SELECT)
INSERT INTO producto(...) ...           → INSERT 0 1    (OK: POST)
UPDATE producto SET activo=false ...    → UPDATE 1      (OK: baja lógica)
SELECT count(*) FROM venta;             → ERROR: permission denied for table venta
DELETE FROM producto ...                → ERROR: permission denied  (no hay DELETE físico)
CALL registrar_venta_simple(1,1,1,1,1); → CALL          (OK: EXECUTE + SECURITY DEFINER)
```
=> El rol lee el catálogo y escribe `producto`, pero NO accede directo a
`venta`/`stock` ni borra físico. La venta la hace por **delegación** (procedure).

## Capturas de Postman

Guardar aquí las 3–4 capturas requeridas por la consigna:

- `evidencia/01_post_201.png`
- `evidencia/02_put_200.png`
- `evidencia/03_delete_200.png`
- `evidencia/04_error_400_404.png` (opcional)
