# 10 · MVP

Define el **producto mínimo viable** tras la etapa base. Es la brújula del alcance: si algo no está aquí, no se construye todavía.

## Objetivo del MVP

> Una empresa puede registrarse, sus usuarios pueden iniciar sesión, y un operador puede **gestionar su inventario y registrar ventas desde el móvil sin conexión**, viendo esos datos sincronizados en el panel web.

Esto valida las tres apuestas del producto de una vez: **multiempresa**, **offline-first** y **multiplataforma** — y con el caso de uso más realista de un ERP de campo: vender y descontar stock.

## Alcance del MVP

### Incluido
- **Onboarding:** registro de empresa + usuario Owner.
- **Autenticación:** login/refresh/logout con JWT en las tres plataformas.
- **Gestión de usuarios** de la empresa (Owner/Admin) con RBAC básico.
- **Módulo Inventario:** catálogo de productos + existencias (CRUD).
- **Módulo Ventas:** registro de ventas que descuentan stock del inventario.
- **Offline-first en móvil** para Inventario y Ventas: operar sin conexión.
- **Sincronización funcional:** push/pull con tombstones y la política de conflictos descrita abajo.
- **Panel web** que muestra y administra productos, existencias y ventas (online).
- **Aislamiento multi-tenant** verificado por tests.

### Explícitamente FUERA del MVP
- Clientes como módulo (puede añadirse trivialmente después; no es lo que valida el MVP).
- Facturación fiscal, Reportes, Contabilidad.
- Integración de pagos / pasarela de facturación.
- Permisos finos por recurso (más allá de RBAC por rol).
- Multi-idioma, temas, personalización.

## Nota técnica: conflictos de stock (decisión importante)

Elegir Ventas/Inventario como primer módulo **sube el listón de la sincronización**, y hay que decidirlo explícitamente:

- **El catálogo de productos** (nombre, precio, datos del producto) se sincroniza con *last-write-wins* estándar, igual que cualquier entidad.
- **Las existencias (stock) NO admiten last-write-wins.** Si dos dispositivos venden el mismo producto offline, sobrescribir la cantidad haría **perder una de las ventas**. Un stock final de 8 tras dos ventas de 1 desde 10 sería incorrecto si cada dispositivo escribe "9".

**Decisión para el MVP:** el stock **no se sincroniza como un valor absoluto, sino como movimientos (deltas)**. Cada venta genera un movimiento de inventario `-N` con su propio UUIDv7; el servidor **suma los movimientos**, no reemplaza el total. Así dos ventas offline concurrentes se acumulan correctamente al sincronizar.

- Esto se modela con una tabla `stock_movements` (append-only) además de `products`.
- El "stock actual" es una proyección de la suma de movimientos, no un campo que se sobrescribe.
- Consecuencia: las **ventas nunca entran en conflicto entre sí** (cada una es un registro nuevo e inmutable); solo el catálogo usa last-write-wins.

> Esta es la razón de fondo por la que este módulo valida mejor el offline-first que Clientes: obliga a resolver el caso difícil desde el MVP. Se registrará como ADR.

## Etapa 0 — Base (previa al MVP, la actual)

Andamiaje sin módulos de negocio:
1. Estructura del monorepo + documentación (`/docs`).
2. Backend arranca + `/health` + Postgres en Docker.
3. Modelos `tenants`/`users` + primera migración + RLS + policies.
4. Autenticación mínima (register/login) con JWT y Argon2.
5. **Test de aislamiento de tenants** (guardián).
6. Web base (Vite+TS) con login.
7. Móvil base (Flutter+Drift) con login y esquema local con campos de sync.
8. Esqueleto de endpoints `sync/push` y `sync/pull` + outbox local (sin lógica de conflictos).
9. CI (lint + test por app).

## Criterios de aceptación del MVP

- [ ] Dos empresas distintas no pueden ver datos la una de la otra (test verde).
- [ ] Un operador da de alta un producto y registra ventas en el móvil en modo avión; al reconectar, producto y ventas aparecen en el panel web de su empresa.
- [ ] **Dos dispositivos venden el mismo producto sin conexión; tras sincronizar, el stock refleja AMBAS ventas** (se suman los movimientos, no se pierde ninguna).
- [ ] Un producto borrado en un dispositivo desaparece en los demás tras sincronizar (tombstone).
- [ ] Login/refresh/logout funcionan en web y móvil.
- [ ] Contraseñas hasheadas con Argon2; comunicación sobre HTTPS.

## Métrica de éxito

El MVP se considera validado cuando un negocio piloto opera una jornada real de campo **sin conexión estable** —vendiendo y moviendo inventario— y al reconectar sus datos quedan **íntegros (sin ventas ni stock perdidos), aislados y consistentes** en todas las plataformas.

Ver también: [03_Especificacion_Funcional](03_Especificacion_Funcional.md), [04_Base_Datos](04_Base_Datos.md), [11_Pruebas](11_Pruebas.md).
