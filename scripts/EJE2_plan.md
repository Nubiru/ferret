# Eje II — Programación en el Servidor (Thick DB) · Plan de trabajo

PostgreSQL / PL-pgSQL. Cada parte (A–E) es de un responsable; los archivos se
agregan **aditivamente** en `scripts/` (NO se renombra ni mueve nada mientras
hay ramas en vuelo — evita conflictos entre los 4 hosts).

## Reparto y estado

| Parte | Qué pide | Responsable | Archivo | Estado |
|---|---|---|---|---|
| **A** | Función (volatilidad) + Procedure + %TYPE/%ROWTYPE | Federico | `scripts/05_procedures.sql` | ✅ Hecho |
| **B** | Transacciones: COMMIT/ROLLBACK + SAVEPOINT + ROLLBACK TO | **Gabriel** | `scripts/07_transacciones.sql` | ✅ Hecho |
| **C** | Auditoría: tabla `audit_logs` + EXCEPTION + GET STACKED DIAGNOSTICS | *(libre)* | `scripts/08_auditoria.sql` | ⬜ Pendiente |
| **D** | Seguridad: SECURITY DEFINER + search_path fijo | **Gabriel** | `scripts/06_seguridad_hardening.sql` | ✅ Hecho |
| **E** | Trigger BEFORE/AFTER con OLD/NEW | **Mariano** | `scripts/09_triggers.sql` | ⬜ Pendiente |

> C queda libre (p. ej. Lautaro). Checklist oficial de la profe trackeado en
> [`checklist.md`](../checklist.md) (raíz del repo).

## Dependencias técnicas (importante para no chocar entre partes)

1. **B vs D — incompatibilidad en la misma rutina.** Una función/procedure con
   cláusula `SET` (search_path, que usa D) **no puede** hacer `COMMIT`/`ROLLBACK`
   (B). Por eso D vive en su propia función administrativa y NO se monta sobre el
   procedure de A/B. Si B quiere control transaccional, su procedure **no** debe
   llevar `SET search_path`.

2. **C es infraestructura compartida.** La tabla `audit_logs` (Parte C) la usan
   también B (registrar fallos de transacción) y E (auditoría automática por
   trigger). Conviene que C se haga/mergee **primero**, o que se acuerde el
   esquema de `audit_logs` antes de que B y E escriban contra ella.

3. **A + D = criterio "tablas privadas, funciones públicas".** D ya demuestra el
   patrón (rol `ferret_operador` sin acceso a tablas, solo EXECUTE sobre la
   función). El mismo patrón se puede aplicar al procedure de A si el equipo quiere.

## Orden sugerido de merge

`A (hecho)` → `C (audit_logs primero)` → `B` y `E` (usan audit_logs) → `D (hecho, independiente)`

## Cómo correr lo que ya está

```bash
psql -d ferret_db -f scripts/05_procedures.sql        # A
psql -d ferret_db -f scripts/06_seguridad_hardening.sql # D
```
