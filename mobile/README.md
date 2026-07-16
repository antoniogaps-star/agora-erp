# Ágora ERP — App Móvil

Flutter + SQLite (Drift). Aplicación **offline-first**: funciona sin conexión y sincroniza al recuperar red.

## Requisitos

- Flutter 3.x (Dart >= 3.5)

## Puesta en marcha

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera Drift/Freezed
flutter run
```

## Estructura

```
lib/
├── core/          # config, DI, theme, red
├── features/      # feature-first (auth, inventory, sales, …)
├── data/
│   ├── local/     # esquema Drift/SQLite (con campos de sync)
│   ├── remote/    # cliente API (dio)
│   └── sync/      # outbox + motor de sincronización
└── shared/
```

## Comandos

```bash
flutter analyze
flutter test
```

Ver [`docs/07_App_Movil.md`](../docs/07_App_Movil.md).
