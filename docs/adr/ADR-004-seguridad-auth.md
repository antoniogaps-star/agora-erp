# ADR-004 · Autenticación JWT, Argon2 y cifrado en reposo

**Estado:** Aceptada · **Fecha:** 2026-07-15

## Contexto

El sistema maneja datos empresariales sensibles en servidor y en dispositivos móviles que pueden perderse o robarse. La seguridad es requisito de diseño.

## Decisión

- **JWT** con *access token* de vida corta (memoria del cliente) y *refresh token* de vida larga, revocable (hash almacenado en `refresh_tokens`). Claims: `sub`, `tenant_id`, `role`, `exp`, `iat`.
- **Argon2id** para el hash de contraseñas.
- **TLS/HTTPS** obligatorio en tránsito.
- **Cifrado en reposo en el móvil:** SQLite con SQLCipher; llave en `flutter_secure_storage`; tokens en almacenamiento seguro del SO.
- Secretos (clave JWT, credenciales DB) fuera del repositorio, vía variables de entorno / gestor de secretos.

## Consecuencias

- Robo de un token de acceso tiene ventana corta; el refresh se puede revocar.
- Pérdida de dispositivo no expone los datos locales (cifrados).
- (–) Complejidad de gestión de claves y rotación → documentada en [09_Seguridad](../09_Seguridad.md).

## Alternativas descartadas

- **Sesiones con estado en servidor:** peor encaje con clientes offline y múltiples plataformas.
- **bcrypt/PBKDF2:** Argon2id ofrece mejor resistencia a hardware moderno.
