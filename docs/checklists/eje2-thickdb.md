# Checklist — Proyecto Integrador · Parte 2 / Eje II (Thick DB · PL/pgSQL)

Marquen con una `X` dentro de los corchetes `[ ]` (ej: `[x]`) a medida que mergeen en el repo.

> **Reparto y detalle técnico:** ver [`scripts/EJE2_plan.md`](../../scripts/EJE2_plan.md).
> **Estado global Eje II: 4 de 5 partes (A, B, C, D ✅ · solo falta E).**

### A. Abstracción y Lógica Procedural — ✅ Federico (`scripts/05_procedures.sql`)

- [x] **1.** Categorizar la volatilidad de la función (`IMMUTABLE` / `STABLE` / `VOLATILE`).
- [x] **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.
- [x] **3.** Robustez de tipos con `%TYPE`, `%ROWTYPE` o `RECORD`.

### B. Gestión Avanzada de Transacciones — ✅ Gabriel (`scripts/07_transacciones.sql`)

- [x] **1.** Atomicidad con `COMMIT` y `ROLLBACK` explícitos.
- [x] **2.** Aislar un subproceso secundario propenso a fallas con un `SAVEPOINT`.
- [x] **3.** Reversión parcial con `ROLLBACK TO SAVEPOINT` ante error controlado.

### C. Capa de Auditoría y Forense de Datos — ✅ (`scripts/08_auditoria_y_forense.sql`)

- [x] **1.** Tabla física `audit_logs` con metadatos del sistema.
- [x] **2.** Bloques estructurados `EXCEPTION` en los puntos críticos.
- [x] **3.** `GET STACKED DIAGNOSTICS` para extraer `RETURNED_SQLSTATE` y `MESSAGE_TEXT`.

### D. Seguridad y Blindaje (Hardening) — ✅ Gabriel (`scripts/06_seguridad_hardening.sql`)

- [x] **1.** Proceso administrativo crítico bajo `SECURITY DEFINER`.
- [x] **2.** `search_path` fijo para blindar contra inyección/escalada.

### E. Automatización con Triggers — ⬜ PENDIENTE (Mariano) → `scripts/09_triggers.sql`

- [ ] **1.** Definir tabla objetivo y sincronización del disparador (`BEFORE` / `AFTER`).
- [ ] **2.** Función del trigger con lógica condicional sobre `OLD` y `NEW`.
- [ ] **3.** `CREATE TRIGGER` y verificar la reactividad ante DML (INSERT/UPDATE/DELETE).

---

*💡 Cada casilla tildada debe estar respaldada por su código en el proyecto y el historial de commits.*
