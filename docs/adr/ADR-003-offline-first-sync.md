# ADR-003 · Offline-first con UUIDv7 y sincronización por deltas

**Estado:** Aceptada · **Fecha:** 2026-07-15

## Contexto

La app móvil debe funcionar sin conexión y sincronizar al recuperar red, sin colisiones de identificadores ni pérdida de borrados.

## Decisión

- **Claves primarias UUIDv7 generadas en el cliente** (ordenables en el tiempo, sin coordinación) — permite crear registros offline sin colisiones. No se usa autoincrement.
- Toda entidad sincronizable lleva `tenant_id`, `updated_at`, `is_deleted` (tombstone) y `version`.
- **Patrón outbox** en el cliente + endpoints `sync/push` y `sync/pull` (deltas por cursor).
- **Resolución de conflictos:** *last-write-wins* por `updated_at` como política base, refinable por entidad (ver [ADR-005](ADR-005-stock-por-movimientos.md) para stock).

## Consecuencias

- Creación y edición siempre disponibles; la UI lee de la base local.
- Los borrados se propagan como tombstones.
- (–) Last-write-wins puede perder actualizaciones concurrentes en ciertos casos → se aborda por entidad cuando aplica ([ADR-005](ADR-005-stock-por-movimientos.md)).

## Alternativas descartadas

- **IDs autoincrementales del servidor:** imposibilitan crear offline sin colisiones.
- **Sincronización de estado completo:** costosa e ineficiente frente a deltas.
