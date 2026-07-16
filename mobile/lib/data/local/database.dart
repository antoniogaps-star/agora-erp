import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Tabla de productos en la base local. Replica las columnas estándar de
/// sincronización del backend (ver docs/04_Base_Datos.md y docs/07_App_Movil.md):
/// id (UUIDv7 de cliente), tenantId, isDeleted (tombstone), version, updatedAt.
/// Más un flag LOCAL `isDirty`: marca los registros pendientes de subir (outbox).
class Products extends Table {
  TextColumn get id => text()(); // UUIDv7 generado en el dispositivo
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().withDefault(const Constant(0))();

  // Columnas de sincronización
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  /// Todos los registros pendientes de subir (la cola outbox). Lo consumirá el
  /// motor de sincronización en el hito 8.
  Future<List<Product>> pendingChanges() =>
      (select(products)..where((p) => p.isDirty.equals(true))).get();
}

QueryExecutor _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/agora.sqlite');
    // TODO(seguridad): envolver con SQLCipher (cifrado en reposo) — ADR-004.
    return NativeDatabase.createInBackground(file);
  });
}
