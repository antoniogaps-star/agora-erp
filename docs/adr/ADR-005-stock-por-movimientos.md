# ADR-005 · Stock como movimientos (deltas), no como valor absoluto

**Estado:** Aceptada · **Fecha:** 2026-07-15

## Contexto

El MVP incluye Ventas e Inventario con operación **offline**. Si dos dispositivos venden el mismo producto sin conexión y el stock se sincroniza como un número absoluto, un *last-write-wins* **perdería una de las ventas**: ambos escribirían "9" partiendo de 10, cuando el resultado correcto es 8.

## Decisión

El stock **no se almacena ni se sincroniza como un valor absoluto que se sobrescribe**, sino como **movimientos de inventario append-only** (tabla `stock_movements`). Cada venta o ajuste genera un movimiento con su propio UUIDv7 y una cantidad delta (`-N`, `+N`). El **stock actual es la suma de los movimientos** de un producto (proyección), no un campo mutable.

- Las **ventas son registros inmutables** → nunca entran en conflicto entre sí.
- El servidor **acumula** los movimientos recibidos en el `push`; no reemplaza totales.
- Solo el **catálogo de productos** (nombre, precio, atributos) usa *last-write-wins* estándar.

## Consecuencias

- Dos ventas concurrentes offline del mismo producto se **acumulan correctamente** al sincronizar (criterio de aceptación del MVP).
- (–) El "stock actual" requiere agregación; se optimiza con proyecciones/materialización si el volumen lo exige.
- (–) Ajustes manuales de inventario también deben modelarse como movimientos, no como edición del total.

## Alternativas descartadas

- **Stock como campo absoluto con last-write-wins:** pierde ventas concurrentes. Inaceptable para un ERP.
- **Bloqueo/reserva de stock online:** rompe el requisito offline-first.
