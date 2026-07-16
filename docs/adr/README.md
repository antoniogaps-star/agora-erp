# Architecture Decision Records (ADR)

Registro de las decisiones arquitectónicas relevantes de Ágora ERP. Cada ADR documenta el **contexto**, la **decisión** y sus **consecuencias**, para que nadie tenga que adivinar por qué algo es como es.

| ADR | Decisión | Estado |
|-----|----------|--------|
| [001](ADR-001-monorepo.md) | Monorepo para las tres apps | Aceptada |
| [002](ADR-002-multitenancy-rls.md) | Multi-tenancy con base compartida + RLS | Aceptada |
| [003](ADR-003-offline-first-sync.md) | Offline-first con UUIDv7 + sync por deltas | Aceptada |
| [004](ADR-004-seguridad-auth.md) | Autenticación JWT + Argon2 + cifrado en reposo | Aceptada |
| [005](ADR-005-stock-por-movimientos.md) | Stock como movimientos (deltas), no valor absoluto | Aceptada |

Formato: cada archivo sigue Contexto → Decisión → Consecuencias → Alternativas descartadas.
