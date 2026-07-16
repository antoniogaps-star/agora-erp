# 08 · Panel Web

Stack: **React 18 + TypeScript**, empaquetado con **Vite**. Es la herramienta de **administración** (online-first, a diferencia del móvil).

## Rol del panel web

- Administración de la empresa: usuarios, roles, configuración, plan.
- Consulta y reportes (etapas posteriores).
- **No** es offline-first: asume conexión; el offline-first vive en el móvil. (Puede añadirse caché resiliente más adelante, pero no es requisito.)

## Stack

| Necesidad | Librería |
|-----------|----------|
| UI | `react`, `react-dom` |
| Tipos | `typescript` |
| Build/dev | `vite` |
| Routing | `react-router-dom` |
| Estado de servidor / caché | `@tanstack/react-query` |
| HTTP + validación | `axios` + `zod` |
| Estado de UI ligero | `zustand` |
| Estilos | (a definir: Tailwind u otra) |

## Estructura (feature-first)

```
web/src/
├── app/              # entrypoint, router, providers globales
├── features/         # auth, users, tenant-settings, …
│   └── <feature>/    # components · hooks · api · types
├── shared/
│   ├── ui/           # componentes reutilizables
│   ├── api/          # cliente axios, interceptores (token, refresh)
│   └── types/        # tipos compartidos (idealmente desde packages/shared)
├── lib/              # queryClient, config
└── styles/
```

## Autenticación en el cliente

- Login → guarda `access_token` (memoria) y `refresh_token` (almacenamiento seguro del navegador).
- Interceptor de `axios`: adjunta el bearer y renueva con `/auth/refresh` ante `401`.
- El `tenant_id` **no** lo maneja el frontend para filtrar datos — el backend lo impone vía token + RLS.

## Contratos compartidos

Los tipos de la API deberían derivarse de `packages/shared` (o del OpenAPI del backend) para evitar divergencia entre web, móvil y servidor.

## Calidad

- `eslint` + `prettier`, `vitest` + Testing Library.
- Ver [11_Pruebas](11_Pruebas.md).

Ver también: [05_API](05_API.md), [07_App_Movil](07_App_Movil.md).
