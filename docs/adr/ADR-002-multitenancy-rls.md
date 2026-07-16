# ADR-002 · Multi-tenancy con base compartida + Row-Level Security

**Estado:** Aceptada · **Fecha:** 2026-07-15

## Contexto

El producto es multiempresa y SaaS: un solo despliegue debe servir a muchas empresas con **aislamiento total** de datos, a costo operativo razonable y escalando a miles de tenants.

## Decisión

**Base de datos compartida**, con `tenant_id` en cada tabla de negocio, y aislamiento impuesto por **Row-Level Security (RLS) de PostgreSQL**. El backend fija `SET LOCAL app.current_tenant = <tenant_id del JWT>` por request; las *policies* RLS filtran automáticamente toda consulta. El `tenant_id` se deriva **solo** del JWT verificado, nunca de entrada del cliente.

## Consecuencias

- Una sola migración sirve a todos los tenants.
- El aislamiento **no depende** de que el código recuerde filtrar: lo fuerza la base de datos (defensa en profundidad junto a la capa de servicio).
- (–) Un error en una *policy* es grave → se exige un test de aislamiento bloqueante (ver [ADR asociado en 11_Pruebas](../11_Pruebas.md)).
- Permite migrar un tenant concreto a base dedicada más adelante gracias a la capa de repositorios.

## Alternativas descartadas

- **DB por tenant:** aislamiento máximo pero migraciones y costo insostenibles a escala SaaS.
- **Schema por tenant:** complica migraciones y el motor de sincronización.
