# Cómo sacar las capturas de Postman (Parte 4 / Eje IV)

Las capturas son el **único paso manual** que falta. Son 10 minutos.
Hay dos formas de levantar Redis — elegí la que te quede más cómoda.

---

## Paso 0 — Levantar Redis (elegí UNA opción)

**Opción A — ya tenés Redis nativo** (lo más simple; es lo que usa Gabriel):
```bash
redis-cli ping          # si responde PONG, ya está, no hagas nada más
```
El backend por defecto se conecta a `redis://localhost:6379`.

**Opción B — no tenés Redis / no querés instalarlo** (Docker o Podman):
```bash
cd Parte3/Gabriel
podman-compose up -d      # o:  docker compose up -d
```
Esto levanta Redis en el puerto **6380**. Después arrancás el backend con
`REDIS_URL=redis://localhost:6380` (ver Paso 1).

---

## Paso 1 — Arrancar el backend

```bash
cd Parte3/Gabriel
npm install                      # solo la primera vez
psql -d ferret_db -f rol_api.sql # solo la primera vez: crea el rol ferret_api
npm start                        # si usaste la Opción A (Redis nativo, 6379)
# --- o, si usaste la Opción B (compose en 6380): ---
REDIS_URL=redis://localhost:6380 npm start
```
Tenés que ver:
```
[redis] conectado a redis://localhost:...
[api] escuchando en http://localhost:3000
```
> La API se conecta a `ferret_db` como el rol **`ferret_api`** (privilegio mínimo),
> por eso hay que correr `rol_api.sql` una vez. Si tu Postgres no permite TCP local
> con password, podés volver al usuario de siempre: `PGHOST=/var/run/postgresql
> PGUSER=$USER npm start`.

---

## Paso 2 — Importar la colección en Postman

1. Abrí Postman → botón **Import** (arriba a la izquierda).
2. Arrastrá el archivo **`Parte3/Gabriel/ferret-parte4.postman_collection.json`**.
3. Aparece la colección **"FeRReT — Parte 4 (Eje IV)"** con los requests numerados
   (POST/PUT/DELETE de producto, errores 400/404, y el bonus `POST /api/venta`).

> La colección ya encadena los datos: el **POST** guarda el `id` creado en la
> variable `{{nuevoId}}`, y el **PUT** y el **DELETE** lo reutilizan solos.
> Por eso hay que ejecutarlos **en orden**.

---

## Paso 3 — Ejecutar y capturar (en orden)

Para cada request: clic en el request → botón **Send** → **captura de pantalla**
mostrando el **método + URL + el body de la respuesta + el código de estado**
(la franja verde "200 OK" / "201 Created" arriba a la derecha).

| # | Request | Qué tiene que mostrar | Guardar como |
|---|---------|------------------------|--------------|
| 1 | **1. CREATE — POST** | `201 Created` + el producto nuevo con su `id` | `evidencia/01_post_201.png` |
| 2 | **2. UPDATE — PUT** | `200 OK` + el `nombre` cambiado a "...PRO" | `evidencia/02_put_200.png` |
| 3 | **3. DELETE lógico** | `200 OK` + `"activo": false` | `evidencia/03_delete_200.png` |
| 4 | **4a. ERROR 400** / **4b. ERROR 404** | `400` y `404` (manejo de errores) | `evidencia/04_errores_400_404.png` |

> **Tip para lucirte en la defensa (invalidación selectiva):** antes del POST,
> ejecutá el request **"0. GET /api/productos"** una vez (puebla la caché). En la
> respuesta vas a ver `"origen":"db"`; si lo mandás otra vez, `"origen":"cache"`
> (HIT). Después del POST, el campo `"cache_invalidada"` te dice cuántas claves
> se purgaron. Una captura del GET mostrando `origen: cache` → `origen: db` tras
> el POST es la prueba visual del Cache-Aside + invalidación.

---

## Paso 4 — Guardar en el repo

Poné los `.png` dentro de `Parte3/Gabriel/evidencia/` y subilos:
```bash
git add Parte3/Gabriel/evidencia/*.png
git commit -m "Parte 4: capturas de Postman (evidencia Eje IV)"
git push
```

Listo. Con eso la Parte 4 queda 100% entregada.
