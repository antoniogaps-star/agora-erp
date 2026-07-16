# 09 · Seguridad

La seguridad es requisito de diseño. Este documento es de lectura obligatoria antes de tocar autenticación o datos.

## 1. Aislamiento entre empresas (lo más crítico)

- **Row-Level Security de PostgreSQL** impone que cada tenant solo vea sus filas (ver [04_Base_Datos](04_Base_Datos.md)).
- El `tenant_id` se deriva **exclusivamente del JWT verificado**, nunca de entrada del cliente.
- **Defensa en profundidad:** RLS (base de datos) + validación en la capa de servicio.
- **Guardián:** tests automatizados de aislamiento que fallan si un tenant accede a datos de otro (ver [11_Pruebas](11_Pruebas.md)).

## 2. Autenticación

- **JWT** con dos tokens:
  - *Access token* de vida corta (p. ej. 15 min), en memoria del cliente.
  - *Refresh token* de vida larga, revocable, almacenado con hash en `refresh_tokens`.
- Claims mínimos: `sub` (user_id), `tenant_id`, `role`, `exp`, `iat`.
- Firma con clave secreta fuerte (HS256) o par de claves (RS256) — a decidir en ADR; secreto fuera del repo.
- **Rotación y revocación** de refresh tokens (logout invalida el token).

## 3. Contraseñas

- Hashing con **Argon2id** (no bcrypt/MD5/SHA), con parámetros de costo revisables.
- Política mínima de contraseña validada en el registro.
- Nunca se registran ni se devuelven en logs o respuestas.

## 4. Datos en reposo

- **Servidor:** cifrado a nivel de disco/gestor (según hosting); datos sensibles nunca en logs.
- **Móvil:** base SQLite cifrada con **SQLCipher**; la llave vive en `flutter_secure_storage`. Tokens en almacenamiento seguro del SO.

## 5. Datos en tránsito

- **HTTPS/TLS obligatorio** en todas las comunicaciones. Sin excepción en producción.

## 6. Autorización

- **RBAC** por rol (`owner`/`admin`/`operator`/`viewer`) validado en el backend por endpoint.
- El estado y plan del tenant (`active`, `suspended`, …) se validan por request: un tenant suspendido no opera.

## 7. Gestión de secretos

- Claves JWT, credenciales de base de datos y de terceros: **variables de entorno / gestor de secretos**, nunca en el repositorio.
- `.env.example` documenta las variables sin valores reales.

## 8. Referencia OWASP (Top 10) — cómo lo cubrimos

| Riesgo | Mitigación |
|--------|-----------|
| Broken Access Control | RLS + RBAC + tenant desde token |
| Cryptographic Failures | TLS + Argon2 + SQLCipher |
| Injection | ORM parametrizado (SQLAlchemy), validación Pydantic/Zod |
| Insecure Design | multi-tenancy y sync diseñados antes de codear |
| Security Misconfiguration | config por entorno, secretos externos |
| Identification/Auth Failures | JWT corto + refresh revocable + Argon2 |
| Software/Data Integrity | idempotencia y versiones en sync |
| Security Logging | logging estructurado sin datos sensibles |

## 9. Prácticas prohibidas

- Tomar `tenant_id` de entrada del cliente.
- Crear tablas de negocio sin RLS.
- Guardar secretos o contraseñas en el repositorio.
- Devolver detalles internos en mensajes de error.

Ver también: [04_Base_Datos](04_Base_Datos.md), [06_Backend](06_Backend.md), [11_Pruebas](11_Pruebas.md).
