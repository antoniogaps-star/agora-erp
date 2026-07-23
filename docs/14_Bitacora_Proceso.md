# 14 · Bitácora del Proceso (Ágora ERP)

> Documento de trabajo: guarda **todo lo que se ha construido**, cómo funciona,
> cómo se despliega y cómo se prueba. Está escrito en lenguaje simple para poder
> retomar el proyecto en cualquier momento sin depender de la memoria.

Última actualización: 2026-07-22.

---

## 1. Qué es Ágora ERP

Un sistema de **inventario y ventas para negocios pequeños** (abarrotes,
modeloramas, depósitos), pensado para trabajar **desde el celular** (incluso con
voz) y consultar/administrar desde una **computadora** (panel web).

Idea central del flujo:

```
Celular (app) → Voz / captura → Procesamiento → Base de datos → Panel de computadora
```

Es **multi-empresa** (varios negocios usan el mismo sistema, cada uno ve solo sus
datos) y **funciona sin internet** (offline-first): captura local y sincroniza
cuando hay señal.

---

## 2. Cómo está armado (arquitectura)

Es un **monorepo** (todo en un solo repositorio de GitHub):

| Carpeta    | Qué es                | Tecnología                              | Dónde vive |
|------------|-----------------------|-----------------------------------------|------------|
| `backend/` | El servidor / cerebro | FastAPI + PostgreSQL (Python)           | Render     |
| `mobile/`  | La app del celular    | Flutter + Drift (base local cifrada)    | APK en GitHub Releases |
| `web/`     | El panel de computadora| React + TypeScript + Vite              | Vercel     |
| `docs/`    | La documentación      | Markdown                                | GitHub     |

Conceptos clave:

- **Multi-tenant (multi-empresa):** una sola base de datos compartida con un
  `tenant_id` por empresa y seguridad a nivel de fila (RLS) en PostgreSQL. El
  correo es único **por empresa**, no a nivel global (por eso al entrar se
  necesita empresa + correo + contraseña).
- **Offline-first:** la app guarda todo localmente (cifrado con SQLCipher) y
  sincroniza con outbox + tombstones. El stock es la **suma de movimientos**
  (entradas − salidas), ver `docs/adr/ADR-005`.
- **Estado en la app:** Riverpod. La sesión puede ser `none`, `real` o `demo`.

---

## 3. Login y registro (rediseño de entrada)

Se simplificó al máximo para que **nadie se quede afuera por un error al teclear**.

- Se eliminó la palabra confusa "slug". El usuario solo escribe el **nombre de la
  empresa**; la app genera sola el identificador interno (`slugify`: minúsculas,
  sin acentos, con guiones).
- El correo se pasa a minúsculas automáticamente.
- Todos los campos de contraseña tienen **ojito 👁** para verla y evitar errores.

**Comportamiento al abrir la app** (lógica en `mobile/lib/main.dart`, `_AuthGate`):

1. **Primera vez** (equipo sin cuenta guardada): sale directo la pantalla
   **Crear empresa** con **recuadro naranja / letras blancas** (Empresa, Correo,
   Contraseña). — `register_screen.dart`
2. **Ya registrado**: en los siguientes ingresos sale la pantalla **Entrar** con
   **recuadro verde arriba / letras blancas**, que recuerda empresa y correo y
   **solo pide la contraseña**. — `quick_login_screen.dart`
3. **Con sesión activa**: entra directo a la app (Inventario). — `home_screen.dart`

Los datos de la última cuenta se guardan con `saveLastLogin` en `secure_store.dart`
y **no se borran al cerrar sesión** (por eso siempre reaparece la pantalla verde).

---

## 4. Demostración (para enseñar al cliente)

Modo demo **offline, sin login, con datos fijos de ejemplo**, pensado para que el
vendedor le enseñe la app a un cliente. Se entra desde el login con "Ver
demostración". Muestra una franja verde "Prueba gratis · 1 semana" y un botón
"Reiniciar" para volver a enseñarla desde cero.

Archivos: `mobile/lib/core/demo.dart` (semilla de datos), franja en
`home_screen.dart`.

---

## 5. Ventas desde la app

En `mobile/lib/features/sales/`:

- **Vender por presentación:** piezas (1–12), six (1–12), caja (1–999) y
  piezas-por-caja; calcula el total. — `sell_sheet.dart`
- **Ticket:** genera un ticket a nombre de un cliente genérico. — `ticket.dart`,
  `ticket_screen.dart`
- **Enviar por WhatsApp:** usa `url_launcher` (wa.me) y también compartir con
  `share_plus`.
- **Exportar ventas a archivo (Excel/CSV):** genera CSV con BOM y lo comparte. —
  `export_sales.dart` (botón de descarga en la barra superior del Home).

---

## 6. Monetización (planes, pagos y claves)

### Planes
- **Esencial** (1 negocio): $199 lanzamiento / $299 normal al mes · $2,990 anual ·
  $5,990 perpetua.
- **Profesional** (hasta 3 negocios): $399 / $599 · $5,990 anual · $10,990 perpetua.
- **Empresarial** (hasta 6 negocios): $699 / $999 · $9,990 anual · $17,990 perpetua.

Pantalla: `mobile/lib/features/billing/pricing_screen.dart` (con oferta de
lanzamiento y "Prueba gratis 7 días").

### Prueba y pago
- **Prueba gratis de 7 días** (mensaje, no bloqueo duro). Al terminar, se muestran
  los planes.
- **Pago por transferencia y/o efectivo.** Al pagar, el cliente recibe una **clave
  de activación** para desbloquear su plan.

### Claves de activación (backend)
- Tabla `licenses` en la base de datos con códigos aleatorios tipo
  `AGORA-XXXX-XXXX`. Sin RLS.
- El **vendedor** genera claves con la pantalla `admin_keys_screen.dart`, protegida
  con un secreto de administrador.
- El **cliente** canjea su clave en `activation_screen.dart`.
- Endpoints: `GET /billing/status`, `POST /billing/redeem`,
  `POST /billing/admin/keys` (este último exige el header `X-Admin-Secret`).
- Backend: `backend/app/modules/billing/`, migración
  `backend/alembic/versions/0007_licenses_and_plan_expiry.py` (agrega
  `plan_expires_at` a `tenants` + tabla `licenses`).

> ⚠️ **Pendiente de configuración:** para que el vendedor pueda generar claves hay
> que poner la variable de entorno `LICENSE_ADMIN_SECRET` en Render.

---

## 7. Panel de computadora (web)

Reestructurado en **8 secciones** (`web/src/app/AppLayout.tsx` + `router.tsx`):

1. Dashboard general — `/`
2. Inventario — `/inventario`
3. Productos — `/productos`
4. Movimientos — `/movimientos`
5. Reportes — `/reportes`
6. Exportación a Excel — `/exportar` (descarga CSV desde el navegador)
7. Gestión de negocios — `/negocios`
8. Usuarios y permisos — `/usuarios`

El login/registro web usa la misma lógica (nombre → identificador), con
autocompletado desactivado y casilla "Ver contraseña".

### PWA (icono en el celular)
El panel web se puede **instalar como app** ("Agregar a pantalla de inicio"):
`web/public/manifest.webmanifest` + iconos 192/512 + metas en `web/index.html`.

---

## 8. Despliegue (cómo llega a producción)

- **Backend (Render):** al hacer push a `main`, se despliega solo; corre
  `alembic upgrade head && uvicorn ...` (aplica migraciones y levanta el servidor).
- **Web (Vercel):** al hacer push a `main`, se despliega solo.
- **App (APK):** GitHub Actions (`.github/workflows/apk.yml`) compila el APK en
  cada push a `main` que toque `mobile/**` y publica una **Release** con tag
  `apk-N` (N = número de build).
- Descarga de la app: **https://github.com/antoniogaps-star/agora-erp/releases**

Flujo de trabajo usado para publicar (con permiso de escritura):
```
git checkout -B deploy-main origin/main
# editar...
git commit -m "..."
git push origin deploy-main:main
```

Historial reciente de builds del APK:
- **apk-25** — Ventas desde la app (vender por presentación, ticket, WhatsApp, exportar).
- **apk-26** — Monetización en la app (planes, activación, generar claves).
- **apk-27** — Rediseño de entrada (Crear empresa naranja / Entrar verde solo-contraseña).

---

## 9. Cómo probar localmente

- **Backend:** PostgreSQL debe correr como usuario `ubuntu` (no root). Pruebas:
  `pytest` en `backend/` (39 pruebas en verde). Calidad: `ruff` y `mypy`.
- **App:** `flutter analyze` y `flutter test` en `mobile/`.
- **Web:** build de Vite en `web/`.

> Nota: el proxy de red de este entorno bloquea `onrender.com` y `vercel.app`, por
> lo que **no se puede probar contra el servidor en vivo desde aquí**; se prueba
> localmente reproduciendo el flujo.

---

## 10. Pendientes / próximos pasos

- [ ] Poner `LICENSE_ADMIN_SECRET` en Render (para generar claves de activación).
- [ ] Probar en el celular el build **apk-27** (entrada naranja/verde).
- [ ] Probar los builds apk-25 (ventas) y apk-26 (monetización) en dispositivo real.
- [x] Aplicar el bloqueo real al terminar la prueba de 7 días. **Hecho:** al vencer la
      prueba (o el plan de pago) la cuenta entra en **solo-lectura**. Las escrituras
      responden `402 SUBSCRIPTION_EXPIRED`; las lecturas y `billing/*` (para reactivar con
      una clave) siguen abiertas. Reja centralizada en
      `backend/app/modules/billing/deps.py` (`require_active_subscription`), colgada de los
      routers de products/sales/customers/invoices/accounting y de `/sync/push`.

---

## 11. Mapa rápido de archivos clave

| Tema | Archivo |
|------|---------|
| Decidir pantalla al abrir | `mobile/lib/main.dart` (`_AuthGate`) |
| Crear empresa (naranja) | `mobile/lib/features/auth/register_screen.dart` |
| Entrar solo-contraseña (verde) | `mobile/lib/features/auth/quick_login_screen.dart` |
| Login completo (otra empresa) | `mobile/lib/features/auth/login_screen.dart` |
| Mensajes de error amigables | `mobile/lib/features/auth/auth_errors.dart` |
| Generar identificador | `mobile/lib/core/slug.dart` |
| Guardar última cuenta / tokens | `mobile/lib/core/secure_store.dart` |
| Estado de sesión | `mobile/lib/core/providers.dart` |
| Vender / ticket / exportar | `mobile/lib/features/sales/` |
| Planes / activación / claves | `mobile/lib/features/billing/` |
| Demo | `mobile/lib/core/demo.dart` |
| Panel web (8 secciones) | `web/src/app/`, `web/src/features/` |
| Facturación (servidor) | `backend/app/modules/billing/` |
| Migración de licencias | `backend/alembic/versions/0007_licenses_and_plan_expiry.py` |
