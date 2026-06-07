# Checklists del Proyecto Integrador — FeRReT

Una checklist por entrega, con los ítems textuales de cada consigna. Marquen `[x]` al mergear.

| Entrega | Tecnología | Estado | Checklist |
|---|---|---|---|
| **Parte 1 / Eje I** — Optimización + SQL Avanzado | PostgreSQL | ✅ casi completo (falta pg_stat_statements) | [`eje1-optimizacion.md`](eje1-optimizacion.md) |
| **Parte 2 / Eje II** — Thick DB (PL/pgSQL) | PostgreSQL | ✅ A·B·C·D — falta **E (triggers)** | [`eje2-thickdb.md`](eje2-thickdb.md) |
| **Parte 3 / Eje III** — Caché Cache-Aside | Redis + Node | ✅ lógica hecha — falta merge | [`eje3-redis.md`](eje3-redis.md) |
| **Parte 4 / Eje IV** — CRUD + invalidación | PG + Redis + Node | ✅ código hecho — falta Postman + merge | [`eje4-crud.md`](eje4-crud.md) |
| **TP3 (aparte)** — MEAN / Aggregation | MongoDB | ✅ pipeline + backend | [`../../eje3-mean/README.md`](../../eje3-mean/README.md) |

> **Nota sobre nombres:** "Eje III" oficial = **Redis** (`eje4-api/`). El **MongoDB/MEAN** (`eje3-mean/`)
> es un Trabajo Práctico **separado**, no forma parte de la serie Parte 1→4 del Integrador.

## Qué falta para el 100% (visión global)

| Pendiente | Responsable | Bloque |
|---|---|---|
| Eje I · D.3 — `pg_stat_statements` top-5 | Mariano | `sql/06_pg_stat_statements.sql` (borrador listo) |
| Eje II · E — trigger BEFORE/AFTER con OLD/NEW | Mariano | `scripts/09_triggers.sql` |
| Eje III/IV — scaffold + CRUD plano review + merge | equipo | `eje4-api/` (base ya funcional) |
| Eje IV — capturas de Postman | quien tome IV | `docs/postman/` |
