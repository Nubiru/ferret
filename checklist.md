## Checklist de Avance - Proyecto Integrador (Parte 2 / Eje II)

Marquen con una `X` dentro de los corchetes `[ ]` (ej: `[x]`) las tareas completadas a medida que realicen los commits en el repositorio.

> **Reparto y detalle técnico:** ver [`scripts/EJE2_plan.md`](scripts/EJE2_plan.md).
> **Estado global Eje II: 3 de 5 partes (A, B, D ✅ · C, E pendientes).**

### A. Abstracción y Lógica Procedural — ✅ Federico (`scripts/05_procedures.sql`)

- [x] **1.** Categorizar correctamente la volatilidad de la función (`IMMUTABLE`, `STABLE` o `VOLATILE`) analizando el consumo de CPU.

- [x] **2.** Diseñar el procedimiento almacenado principal para la tarea compleja de negocio.

- [x] **3.** Implementar la robustez de tipos en variables usando `%TYPE`, `%ROWTYPE` o `RECORD` (evitar tipos estáticos).

###  B. Gestión Avanzada de Transacciones — ✅ Gabriel (`scripts/07_transacciones.sql`)

- [x] **1.** Asegurar la atomicidad global del procedimiento mediante sentencias explícitas de `COMMIT` y `ROLLBACK`.

- [x] **2.** Identificar el subproceso secundario propenso a fallas y aislarlo mediante la declaración de un `SAVEPOINT`.

- [x] **3.** Implementar la lógica de reversión parcial (`ROLLBACK TO SAVEPOINT`) ante un error controlado.

### C. Capa de Auditoría y Forense de Datos — ⬜ PENDIENTE

- [x] **1.** Crear la tabla física `audit_logs` con los campos necesarios para metadatos del sistema.

- [x] **2.** Implementar bloques estructurados `EXCEPTION` en los puntos críticos de los scripts.

- [x] **3.** Utilizar `GET STACKED DIAGNOSTICS` para extraer de forma limpia el `RETURNED_SQLSTATE` y el `MESSAGE_TEXT`.

### D. Seguridad y Blindaje (Hardening) — ✅ Gabriel (`scripts/06_seguridad_hardening.sql`)

- [x] **1.** Configurar la cabecera del proceso administrativo crítico bajo el contexto de `SECURITY DEFINER`.

- [x] **2.** Blindar las funciones restringiendo el vector de ataque mediante la fijación explícita del parámetro `search_path`.

### E. Automatización con Triggers — ⬜ PENDIENTE (Mariano)

- [ ] **1.** Definir la tabla objetivo y la sincronización temporal del disparador (`BEFORE` / `AFTER`).

- [ ] **2.** Crear la función asociada al disparador aplicando lógica condicional mediante las pseudovariables `OLD` y `NEW`.

- [ ] **3.** Ejecutar la sentencia `CREATE TRIGGER` y verificar la reactividad ante eventos DML (INSERT, UPDATE o DELETE).

---

*💡 Nota para el grupo: Recuerden que cada casilla tildada debe estar respaldada por su respectivo código dentro del proyecto, y el historial de commits de GitHub.*
