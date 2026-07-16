# 02 · Modelo de Negocio

## Modelo: SaaS multi-tenant por suscripción

Cada **empresa (tenant)** es la unidad de negocio y de facturación. Un solo despliegue de la plataforma sirve a todas.

### Unidad de facturación

Se factura **por empresa**, con dos variables combinables:

- **Plan** (tier de funcionalidades).
- **Consumo** (número de usuarios activos y/o volumen de datos), como palanca de crecimiento.

### Planes (propuesta inicial)

| Plan | Público | Usuarios | Módulos | Sync offline |
|------|---------|----------|---------|--------------|
| **Free / Trial** | Prueba | 1–2 | Núcleo | Sí |
| **Pyme** | Negocio pequeño | Hasta 10 | Núcleo + ventas + inventario | Sí |
| **Business** | Empresa mediana | Hasta 50 | Todos + reportes | Sí |
| **Enterprise** | Grande | Ilimitado / negociado | Todos + soporte + opción de aislamiento reforzado | Sí |

> El **plan** determina qué módulos y límites tiene el tenant. Esto se modela como *feature flags* por tenant en la base de datos (ver [04_Base_Datos](04_Base_Datos.md)), **no** se hardcodea.

### Ciclo de vida de un tenant

```
Registro (self-service) → Trial → Suscripción activa → (Suspensión por impago) → Cancelación → Retención/borrado de datos
```

- **Onboarding self-service:** el registro crea el tenant, su primer usuario administrador y su configuración por defecto.
- **Suspensión:** el acceso se corta pero los datos se conservan durante un periodo de gracia.
- **Cancelación:** exportación de datos disponible; borrado según política de retención.

### Implicaciones técnicas del modelo

- El **estado del tenant** (`trial`, `active`, `suspended`, `cancelled`) y su **plan** viven en la tabla `tenants` y condicionan el acceso — se validan en cada request.
- La facturación se integrará con una pasarela externa (Stripe u equivalente) en etapa posterior; el diseño de datos ya la contempla, la integración **no** es parte del MVP.
- El aislamiento por RLS (ver [09_Seguridad](09_Seguridad.md)) es lo que hace viable el modelo multi-tenant económico.

Ver también: [01_Vision_Producto](01_Vision_Producto.md), [10_MVP](10_MVP.md).
