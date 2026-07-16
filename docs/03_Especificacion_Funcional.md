# 03 · Especificación Funcional

## Módulos

El ERP se organiza en módulos activables por plan. En **negrita**, los del núcleo (siempre presentes).

| Módulo | Estado | Descripción |
|--------|--------|-------------|
| **Autenticación** | Núcleo | Registro, login, sesiones, recuperación |
| **Empresas (Tenants)** | Núcleo | Alta de empresa, configuración, plan |
| **Usuarios y Roles** | Núcleo | Gestión de usuarios dentro de la empresa, permisos |
| **Sincronización** | Núcleo | Motor offline/online (transversal) |
| Clientes | MVP | Directorio de clientes |
| Productos / Inventario | MVP | Catálogo y existencias |
| Ventas | MVP | Registro de ventas / pedidos |
| Facturación | Avanzado | Documentos fiscales |
| Reportes | Avanzado | Analítica |
| Contabilidad | Avanzado | Libros y finanzas |

> Los módulos **Avanzado** NO se construyen en la etapa base ni en el MVP. Se listan para dimensionar la arquitectura.

## Roles y permisos (dentro de una empresa)

| Rol | Capacidades |
|-----|-------------|
| **Owner** | Todo, incluida configuración de la empresa y facturación |
| **Admin** | Gestión de usuarios y datos operativos, sin facturación |
| **Operador** | Operación diaria (ventas, inventario, clientes) |
| **Solo lectura** | Consulta |

- Los permisos son **por tenant**: un usuario pertenece a una empresa y tiene un rol dentro de ella.
- El modelo de permisos arranca como **rol → conjunto de capacidades** (RBAC simple). Permisos finos por recurso son evolución posterior.

## Casos de uso del núcleo (etapa base + MVP)

### CU-01 · Registrar empresa (onboarding)
Un nuevo cliente se registra → se crea el tenant + usuario Owner + configuración por defecto. Estado inicial: `trial`.

### CU-02 · Iniciar sesión
Usuario autentica con email + contraseña → recibe JWT con `tenant_id`, `user_id`, `rol`.

### CU-03 · Gestionar usuarios de la empresa
Owner/Admin invita, edita o desactiva usuarios **de su propia empresa** (aislamiento garantizado por RLS).

### CU-04 · Operar sin conexión (MVP)
El operador crea/edita registros (ej. clientes, ventas) en el móvil sin internet. Los cambios se guardan localmente y entran en la cola de sincronización.

### CU-05 · Sincronizar
Al recuperar conexión, el dispositivo envía sus cambios (`push`) y recibe los del servidor (`pull`). Conflictos resueltos por *last-write-wins* con marca temporal.

## Reglas transversales

- Todo registro de negocio pertenece a **exactamente un tenant**.
- Ningún usuario puede ver ni modificar datos de otra empresa — garantía a nivel de base de datos.
- Todo registro sincronizable es **borrado lógico** (nunca físico desde el cliente), para poder propagar borrados.

Ver también: [04_Base_Datos](04_Base_Datos.md), [05_API](05_API.md), [10_MVP](10_MVP.md).
