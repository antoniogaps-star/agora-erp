# Ágora ERP — Documentación del Proyecto

> ERP **multiempresa**, **offline-first**, **seguro**, **escalable** y **preparado para SaaS**.
> Stack: FastAPI + PostgreSQL · Flutter + SQLite · React + TypeScript.

Esta carpeta es la **fuente única de verdad** del proyecto. Ningún código se escribe sin que la decisión esté reflejada aquí primero.

## Índice

| # | Documento | Contenido |
|---|-----------|-----------|
| 01 | [Visión de Producto](01_Vision_Producto.md) | Problema, visión, propuesta de valor, principios, alcance |
| 02 | [Modelo de Negocio](02_Modelo_Negocio.md) | SaaS, planes, monetización, unidad de facturación |
| 03 | [Especificación Funcional](03_Especificacion_Funcional.md) | Módulos, roles, casos de uso, permisos |
| 04 | [Base de Datos](04_Base_Datos.md) | Modelo de datos, multi-tenancy + RLS, campos de sincronización |
| 05 | [API](05_API.md) | Convenciones REST, auth, versionado, protocolo de sync |
| 06 | [Backend](06_Backend.md) | Arquitectura FastAPI, capas, módulos, migraciones |
| 07 | [App Móvil](07_App_Movil.md) | Flutter, offline-first, motor de sincronización, cifrado |
| 08 | [Panel Web](08_Panel_Web.md) | React + TS, arquitectura feature-first, estado |
| 09 | [Seguridad](09_Seguridad.md) | Autenticación, aislamiento, cifrado, secretos, OWASP |
| 10 | [MVP](10_MVP.md) | Alcance mínimo, hitos, criterios de aceptación |
| 11 | [Pruebas](11_Pruebas.md) | Estrategia de testing, aislamiento de tenants, CI |

## Decisiones arquitectónicas de fondo (resumen)

1. **Monorepo** — contratos compartidos entre las tres apps en un solo sitio.
2. **Multi-tenancy = base compartida + `tenant_id` + Row-Level Security de PostgreSQL** — una sola migración, aislamiento impuesto por la base de datos.
3. **Offline-first = UUIDv7 en cliente + tombstones + outbox + sync por deltas**, con *last-write-wins* por defecto.
4. **Seguridad = JWT (access/refresh) + Argon2 + RLS + cifrado en reposo en el dispositivo.**

Cada decisión relevante se registra como ADR en `docs/adr/`.
