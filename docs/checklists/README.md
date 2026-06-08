# Checklists del Proyecto Integrador — FeRReT

Una checklist por entrega, con los ítems textuales de cada consigna. Marquen `[x]` al mergear.

| Entrega | Tecnología | Estado | Checklist |
|---|---|---|---|
| **Parte 1 / Eje I** — Optimización + SQL Avanzado | PostgreSQL | ✅ casi completo (falta pg_stat_statements) | [`eje1-optimizacion.md`](eje1-optimizacion.md) |
| **Parte 2 / Eje II** — Thick DB (PL/pgSQL) | PostgreSQL | ✅ completo (A·B·C·D·E) | [`eje2-thickdb.md`](eje2-thickdb.md) |
| **Parte 3 / Eje III** — Caché Cache-Aside | Redis + Node | ✅ en repo (`Parte3/Gabriel` + `Parte3/Lautaro`) | [`eje3-redis.md`](eje3-redis.md) |
| **Parte 4 / Eje IV** — CRUD + invalidación | PG + Redis + Node | 🟡 código hecho — falta Postman | [`eje4-crud.md`](eje4-crud.md) |

> **Nota:** el TP de **MongoDB/MEAN** era una entrega **individual separada** (no parte del Integrador);
> se quitó del repo. Sigue disponible en el historial git si hiciera falta.

## Qué falta para el 100% (visión global)

| Pendiente | Responsable | Bloque |
|---|---|---|
| Eje I · D.3 — `pg_stat_statements` top-5 (medición en vivo) | Mariano | `Parte1/06_pg_stat_statements.sql` (requiere `shared_preload_libraries` + reinicio) |
| Eje IV — capturas de Postman | quien tome IV | `docs/postman/` |
| Parte 3 — decidir cuál Redis es "la oficial" (hay 2: Gabriel y Lautaro) | equipo | `Parte3/` |
