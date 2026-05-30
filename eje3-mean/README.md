# Eje III — Ecosistema MEAN + Aggregation Framework

Dashboard analítico de recaudación que **traslada el cálculo al motor de base de datos**
(MongoDB Aggregation Framework) en vez de procesarlo en el backend/frontend.

Stack: **M**ongoDB · **E**xpress · **A**ngular · **N**ode.

> **Responsable del pipeline (lo evaluado):** Gabriel [@Nubiru](https://github.com/Nubiru)
> Backend y frontend: resto del equipo.

---

## Estructura

```
eje3-mean/
├── pipeline.json        ← El pipeline de 5 etapas (entregable principal — ToDo 3)
├── ventas.seed.json     ← Los 4 documentos de la consigna (Fase 1, paso 2)
├── backend/
│   ├── server.js        ← Express con los 3 ToDo completados
│   └── package.json     ← "type": "module" + express/cors/mongodb
└── frontend/            ← Angular (lo arma el equipo, ver Fase 3 abajo)
```

---

## El Pipeline (Fase 1 — el corazón de la nota)

5 etapas, validadas contra un MongoDB real. Para los 4 datos de la consigna:

| Categoría | totalRecaudado | ¿pasa `> $315`? |
|---|---|---|
| Almacenamiento | 240 + 70 = **310** | ❌ (310 no es > 315) |
| Memoria | 80×4 = **320** | ✅ |
| Procesadores | 350×1 = **350** | ✅ |

Salida confirmada (ordenada de mayor a menor):

```json
[
  { "_id": "Procesadores", "totalRecaudado": 350, "cantidadItems": 1, "ticketPromedio": 350 },
  { "_id": "Memoria",      "totalRecaudado": 320, "cantidadItems": 4, "ticketPromedio": 320 }
]
```

### Las dos sutilezas que evalúa la profe

1. **Stage 4 — el nombre del campo (el "doble filtrado").**
   Después del `$group`, el campo ya **no** se llama `precio`. Se llama `totalRecaudado`
   (el creado en el `$group`). Por eso el segundo `$match` filtra por `totalRecaudado`, no por `precio`.
   Esa es la pista de la consigna: *"Pensemos cómo se llama el campo en este punto del pipeline"*.

2. **`ticketPromedio` vs `ventaPromedio` (inconsistencia del enunciado).**
   La consigna (Stage 3) dice crear el campo `ventaPromedio`, **pero el HTML que entrega la profe
   lee `item.ticketPromedio`**. Si lo nombramos `ventaPromedio`, la columna "Venta Promedio"
   sale **vacía** en el dashboard. Elegimos **`ticketPromedio`** para que el frontend renderice
   sin tocar el HTML provisto. (Si la profe exige el nombre `ventaPromedio`, se cambia esa única
   clave en el `$group` y se corrige el `app.html`.)

---

## Cómo reproducirlo

### MongoDB (con podman o docker)

```bash
podman run -d --name ferret-mongo -p 27017:27017 docker.io/library/mongo:7
podman exec -i ferret-mongo mongoimport --db ferret_hardware --collection ventas \
  --drop --jsonArray < ventas.seed.json
```

> En **MongoDB Compass** (lo que pide la consigna): crear la DB `ferret_hardware`,
> colección `ventas`, pegar `ventas.seed.json` en la vista JSON, armar el pipeline en la
> pestaña *Aggregation* y exportarlo con **Export to Language → Node.js**.

### Backend (Fase 2)

```bash
cd backend
pnpm install        # o: npm install
node server.js      # → http://localhost:3000/api/reporte-ventas
```

Los 3 `ToDo` ya están resueltos en `server.js`:
- **ToDo 1** — `uri = "mongodb://localhost:27017"`
- **ToDo 2** — db `ferret_hardware`, colección `ventas`
- **ToDo 3** — el pipeline de 5 etapas

### Frontend (Fase 3 — lo arma el equipo)

La profe entrega el frontend ya estilizado. Pasos:

```bash
pnpm dlx @angular/cli new frontend --package-manager=pnpm --routing=false --style=css   # NO a SSR
cd frontend
pnpm add bootstrap
```

- En `src/styles.css`: `@import 'bootstrap/dist/css/bootstrap.min.css';`
- En `tsconfig.app.json` → `compilerOptions`: agregar `"rootDir": "./src"`
- Inyectar en `src/app/` los 3 archivos del enunciado: `app.config.ts`, `app.ts`, `app.html`
- Levantar con `pnpm start` (con el backend corriendo en otra terminal).

⚠️ El `app.html` provisto lee `item.ticketPromedio` — por eso el pipeline usa ese nombre (ver sutileza #2).

---

## Entregable

Según la consigna: repositorio en GitHub con **backend funcional** + **el JSON exacto del pipeline**
(`pipeline.json`). La evaluación se centra en el **ToDo 3** (doble filtrado + promedio en el motor),
que está resuelto y validado acá.
