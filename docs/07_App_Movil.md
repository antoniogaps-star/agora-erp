# 07 · App Móvil

Framework: **Flutter 3.x** · Base local: **SQLite** (vía Drift) · Es la app **offline-first** por excelencia.

## Principios

- **La app funciona 100% sin conexión.** La red es un lujo, no un requisito.
- **La UI lee siempre de la base local**, nunca directo de la red. La red solo alimenta la base local vía sincronización.
- **Cifrado en reposo** de los datos sensibles del dispositivo.

## Stack

| Necesidad | Librería |
|-----------|----------|
| Base local tipada | `drift` (+ `sqlite3_flutter_libs`, con SQLCipher) |
| Estado / DI | `riverpod` |
| Modelos inmutables | `freezed` + `json_serializable` |
| HTTP | `dio` |
| Llaves seguras | `flutter_secure_storage` |
| IDs | `uuid` (UUIDv7) |

## Estructura

```
mobile/lib/
├── core/            # config, DI, theme, red, resultado/errores
├── features/        # feature-first (auth, customers, …)
│   └── <feature>/   # presentation · application · data
├── data/
│   ├── local/       # esquema Drift, DAOs (espejo del modelo de datos)
│   ├── remote/      # cliente API (dio)
│   └── sync/        # outbox + motor de sincronización
└── shared/
```

## Modelo local

Cada tabla sincronizable en SQLite replica las columnas estándar del [04_Base_Datos](04_Base_Datos.md): `id (uuid7)`, `tenant_id`, `updated_at`, `is_deleted`, `version`, más un flag local `is_dirty` (pendiente de subir).

## Motor de sincronización

### Escritura local (siempre disponible)
1. El usuario crea/edita un registro → se genera UUIDv7 en el dispositivo.
2. Se guarda en SQLite con `is_dirty = true`, `version += 1`, `updated_at = now`.
3. La UI se actualiza al instante (no espera red).

### Patrón Outbox
Los cambios `is_dirty` forman la cola de salida. Un servicio de sincronización, cuando hay conexión:

- **PUSH:** envía los cambios pendientes a `POST /sync/push`. Los aceptados se marcan `is_dirty = false`.
- **PULL:** pide `GET /sync/pull?since=<cursor>` y aplica los cambios remotos (incluidos tombstones) a la base local.

### Conflictos
- Política base: **last-write-wins** por `updated_at`.
- Si el servidor responde `conflict`, el cliente reconcilia con la versión del servidor según la política de esa entidad.
- Los **tombstones** (`is_deleted = true`) se propagan como cualquier otro cambio — así un borrado hecho en un dispositivo llega a los demás.

> En la etapa base solo se construye el **andamiaje** (outbox + endpoints + esquema con campos de sync). La lógica fina de conflictos por entidad es etapa posterior.

## Seguridad en el dispositivo

- Base SQLite **cifrada** (SQLCipher); la llave se guarda en `flutter_secure_storage`.
- Tokens JWT en almacenamiento seguro, nunca en texto plano.
- Ver [09_Seguridad](09_Seguridad.md).

Ver también: [05_API](05_API.md), [08_Panel_Web](08_Panel_Web.md).
