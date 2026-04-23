# Guía de Trabajo en Equipo — FeRReT

Esta guía explica **cómo colaboramos los 4 en el repo**. Léela antes de empezar a tocar código.

Para ver **qué hay que hacer** mirá `TAREAS.md`. Para ver **de qué va el proyecto** mirá `README.md`.

---

## 1. Stack y setup local

### Requisitos
- **Git** ≥ 2.30
- **PostgreSQL** ≥ 14
- **DBeaver** (cliente oficial del equipo para modelado y DER)
- **Python** ≥ 3.10 (opcional, solo si armamos seeds con Faker)

### Clonar el repo
```bash
git clone git@github.com:Nubiru/ferret.git
cd ferret
```

### Crear la base local
```bash
# Con psql instalado localmente
createdb ferret
psql -d ferret -f sql/01_schema.sql
```

Si preferís usar DBeaver: crear una conexión a la base `ferret` y correr los `.sql` desde ahí en orden.

---

## 2. Flujo de git que vamos a usar

Trabajamos con **ramas por feature** y **pull requests** a `main`. Nadie pushea directo a `main`.

### Ramas
- `main` — siempre estable, siempre aplicable.
- `feature/<stream>-<descripcion>` — trabajo individual.
- `fix/<descripcion>` — correcciones puntuales.

**Ejemplos de nombres de rama:**
- `feature/A-modelado-der-inicial`
- `feature/B-seed-productos`
- `feature/C-indice-gin-atributos`
- `feature/D-cte-recursiva-categorias`

### Ciclo de trabajo
```bash
# 1. Actualizar main
git checkout main
git pull

# 2. Crear rama nueva
git checkout -b feature/A-modelado-der-inicial

# 3. Trabajar. Commits chicos y con mensaje claro (ver abajo).
git add sql/01_schema.sql
git commit -m "esquema: agrega tabla promocion con exclusion gist"

# 4. Pushear la rama
git push -u origin feature/A-modelado-der-inicial

# 5. Abrir Pull Request en GitHub → pedir review a al menos un compañero.
# 6. Mergear cuando haya aprobación. Borrar la rama después de mergear.
```

### Mensajes de commit (en español)
Formato sugerido: **`<area>: <acción en presente, minúscula>`**

**Áreas posibles:** `esquema`, `indices`, `seed`, `queries`, `docs`, `scripts`, `repo`.

Ejemplos buenos:
- `esquema: agrega tabla alquiler con exclude gist`
- `indices: gin sobre producto.atributos con jsonb_path_ops`
- `seed: genera 80k skus con atributos variados`
- `queries: cte recursiva para arbol de categorias`
- `docs: sube der exportado en png`

Ejemplos a evitar: `update`, `fix`, `cambios varios`, `wip`.

### Regla de oro
- **NUNCA** hacer `git push --force` sobre `main`.
- **NUNCA** mergear tu propio PR sin al menos un review.
- Si rompés `main`, avisar al grupo **antes** de seguir tocando.

---

## 3. Orden en que vamos a trabajar

Los 4 streams tienen dependencias — no todos arrancan a la vez.

```
Semana 1  →  Stream A (Modelado & DER)
             ↓
Semana 2  →  Stream B (Carga Masiva)           ← depende de A
             ↓
Semana 3  →  Stream C (Indexación & Perf)  ┐   ← dependen de B
             Stream D (SQL Avanzado)        ┘   (pueden ir en paralelo)
             ↓
Semana 4  →  Integración + documentación + entrega
```

**Mientras A está en curso:**
- B puede ir leyendo el schema borrador (`sql/01_schema.sql`) y planificar los volúmenes.
- C puede ir pensando qué consultas va a medir y armando el template de `docs/performance.md`.
- D puede ir escribiendo pseudo-SQL de las window functions y CTEs.

**Cuando B termina la carga:**
- C y D arrancan en paralelo sobre datos reales.

---

## 4. Responsabilidades (a auto-asignar)

La división de trabajo está en `TAREAS.md`. Cada uno elige un stream (A, B, C o D) y escribe su nombre arriba de su checklist.

**Regla:** cada stream tiene **un responsable** (dueño de la entrega), pero los demás pueden hacer **reviews y sugerencias** en los PRs.

---

## 5. Convenciones de código SQL

- **Idioma:** identificadores en **español, en minúscula, con guión bajo** (ej. `venta_linea`, `codigo_barras`).
- **Singular** para nombres de tabla (`cliente`, no `clientes`).
- **PKs**: `id` en cada tabla.
- **FKs**: `<tabla_referenciada>_id` (ej. `cliente_id`, `sucursal_id`).
- **Booleanos**: empezar con `es_` o `activo_` (ej. `es_deposito_central`, `activo`).
- **Fechas**: `fecha_<cosa>` (ej. `fecha_venta`, `fecha_alta`).
- **Timestamps**: tipo `TIMESTAMP` (sin timezone por ahora — si hace falta lo definimos).
- **Dinero**: `NUMERIC(14,2)`.
- **Comentarios SQL en español.**

---

## 6. Estructura de carpetas

```
ferret/
├── README.md                 ← qué es FeRReT
├── guia.md                   ← este archivo
├── TAREAS.md                 ← división del trabajo
├── .gitignore
├── propuesta_proyecto.md     ← consigna oficial (NO TOCAR)
├── proyecto_integrador.docx  ← consigna oficial (NO TOCAR)
├── docs/
│   ├── DER.*                 ← diagrama exportado (PNG o PDF) — Stream A
│   ├── performance.md        ← análisis EXPLAIN ANALYZE — Stream C
│   └── dalibo/               ← 2 diagramas PEV2 — Stream C
├── sql/
│   ├── 01_schema.sql         ← Stream A
│   ├── 02_indexes.sql        ← Stream C
│   ├── 03_seed.sql           ← Stream B
│   └── 04_queries.sql        ← Stream D
└── scripts/                  ← generadores auxiliares (Python/bash)
```

---

## 7. Comunicación y dudas

- Dudas de diseño → abrir un **issue** en GitHub con la etiqueta `discusion`.
- Bugs o problemas al correr el SQL → **issue** con la etiqueta `bug`.
- Decisiones tomadas en reuniones → anotarlas en `docs/decisiones.md` (lo creamos cuando aparezca la primera).

---

## 8. Checklist antes de abrir un PR

- [ ] El código corre sin errores contra una DB limpia (o indicás qué setup requiere).
- [ ] Los commits tienen mensajes claros y en español.
- [ ] Si tocaste el schema, avisaste al grupo (rompe trabajo de los demás).
- [ ] Actualizaste la documentación si corresponde.
- [ ] Nada sensible quedó commiteado (contraseñas, dumps, datos personales reales).

---

## 9. Checklist final antes de la entrega

- [ ] `sql/01_schema.sql` aplica limpio.
- [ ] `sql/03_seed.sql` llega a ≥ 1.000.000 registros.
- [ ] `sql/02_indexes.sql` crea todos los índices pedidos.
- [ ] `sql/04_queries.sql` corre sin errores y devuelve resultados lógicos.
- [ ] DER exportado en `docs/`.
- [ ] `docs/performance.md` con EXPLAIN ANALYZE antes/después.
- [ ] 2 diagramas Dalibo en `docs/dalibo/`.
- [ ] Top-5 `pg_stat_statements` documentado.
- [ ] README y guia.md actualizados.
- [ ] `main` está verde (todo mergeado y funcionando).
