# 01 · Visión de Producto

## Problema

Las pequeñas y medianas empresas necesitan gestionar operaciones (ventas, inventario, clientes, finanzas) pero los ERP existentes son:

- **Caros y complejos** — pensados para grandes corporaciones.
- **Dependientes de conexión** — inservibles donde el internet es intermitente (comercios de campo, rutas, zonas rurales, eventos).
- **Monolíticos** — difíciles de adoptar por módulos.

## Visión

> Un ERP que una empresa pueda usar **el primer día, desde el móvil, sin conexión, y crecer con él** — pagando solo por lo que necesita.

Ágora ERP es una plataforma **multiempresa** donde cada negocio opera de forma aislada y segura, con aplicaciones que **funcionan sin internet** y sincronizan cuando la conexión vuelve.

## Propuesta de valor

- **Offline-first real:** el usuario trabaja siempre; la sincronización es transparente.
- **Multiplataforma:** móvil (operación de campo) + web (administración).
- **Multiempresa desde el núcleo:** un solo despliegue sirve a miles de empresas de forma aislada.
- **Preparado para SaaS:** onboarding self-service, planes, facturación por empresa.

## Usuarios objetivo

| Perfil | Plataforma principal | Uso |
|--------|---------------------|-----|
| Dueño / administrador | Web | Configuración, reportes, gestión |
| Vendedor / operador de campo | Móvil | Ventas, inventario, clientes sin conexión |
| Personal administrativo | Web | Facturación, cuentas |

## Principios de producto (no negociables)

1. **Multiempresa** — aislamiento total de datos entre empresas.
2. **Offline-first** — la falta de conexión nunca bloquea la operación.
3. **Seguro** — la seguridad es parte del diseño, no un añadido.
4. **Escalable** — de 1 a miles de empresas sin rediseño.
5. **Preparado para SaaS** — cada empresa es una unidad de negocio independiente.

## Alcance por etapas

- **Etapa 0 — Base (actual):** estructura del proyecto, autenticación, multi-tenancy, esqueleto de sincronización. Sin módulos de negocio.
- **Etapa 1 — MVP:** ver [10_MVP](10_MVP.md).
- **Etapas siguientes:** módulos avanzados (inventario completo, facturación, reportes, contabilidad), definidos cuando el MVP esté validado.

Ver también: [02_Modelo_Negocio](02_Modelo_Negocio.md), [03_Especificacion_Funcional](03_Especificacion_Funcional.md).
