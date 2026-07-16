# ADR-001 · Monorepo para las tres aplicaciones

**Estado:** Aceptada · **Fecha:** 2026-07-15

## Contexto

Ágora ERP tiene tres aplicaciones (backend, web, móvil) que comparten contratos: modelo de datos, esquema de sincronización y tipos de la API. Estos contratos deben mantenerse alineados o el sistema se rompe de forma sutil.

## Decisión

Un único repositorio (**monorepo**) con `backend/`, `web/`, `mobile/`, `packages/shared/` e `infra/`. Las apps se mantienen **autónomas** (cada una con su propio toolchain); no se adopta un build system global (tipo Nx/Turborepo) en la etapa base.

## Consecuencias

- Un cambio de contrato se propaga en un solo commit; `packages/shared` es la fuente única de verdad.
- Revisión de código y CI unificados.
- (–) El repositorio crece; se mitiga con estructura clara y CI por app.
- Si en el futuro se justifica, se puede introducir un orquestador de monorepo sin reestructurar.

## Alternativas descartadas

- **Multi-repo:** contratos duplicados y desincronización entre apps; más fricción para cambios transversales.
