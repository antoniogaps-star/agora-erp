import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import '../../core/secure_store.dart';

part 'database.g.dart';

/// Columnas de sincronización comunes (ver docs/04_Base_Datos.md):
/// tombstone, versión, timestamp y el flag local isDirty (cola outbox).
mixin _SyncColumns on Table {
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
}

/// Catálogo. Se sincroniza con last-write-wins.
class Products extends Table with _SyncColumns {
  TextColumn get id => text()(); // UUIDv7 de cliente
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Movimiento de inventario (append-only). El stock es SUM(delta) — ADR-005.
class StockMovements extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get productId => text()();
  IntColumn get delta => integer()();
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Venta (registro inmutable).
class Sales extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get totalCents => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products, StockMovements, Sales])
class AppDatabase extends _$AppDatabase {
  /// Constructor genérico. Sin executor usa una base en memoria (útil en tests).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? NativeDatabase.memory());

  /// Base de producción: fichero cifrado con SQLCipher usando la llave del almacén seguro.
  AppDatabase.encrypted(SecureStore store) : super(_openEncrypted(store));

  @override
  int get schemaVersion => 1;

  // ── Consultas de inventario ────────────────────────────────
  Future<List<Product>> activeProducts() => (select(products)
        ..where((p) => p.isDeleted.equals(false))
        ..orderBy([(p) => OrderingTerm(expression: p.name)]))
      .get();

  /// Stock local por producto = suma de los deltas de sus movimientos.
  Future<Map<String, int>> stockByProduct() async {
    final sum = stockMovements.delta.sum();
    final query = selectOnly(stockMovements)
      ..addColumns([stockMovements.productId, sum])
      ..where(stockMovements.isDeleted.equals(false))
      ..groupBy([stockMovements.productId]);
    final rows = await query.get();
    return {
      for (final r in rows) r.read(stockMovements.productId)!: r.read(sum) ?? 0,
    };
  }

  // ── Cola outbox (registros pendientes de subir) ────────────
  Future<List<Product>> dirtyProducts() =>
      (select(products)..where((p) => p.isDirty.equals(true))).get();
  Future<List<StockMovement>> dirtyMovements() =>
      (select(stockMovements)..where((m) => m.isDirty.equals(true))).get();
  Future<List<Sale>> dirtySales() =>
      (select(sales)..where((s) => s.isDirty.equals(true))).get();

  Future<void> markProductSynced(String id) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(isDirty: Value(false)));
  Future<void> markMovementSynced(String id) =>
      (update(stockMovements)..where((m) => m.id.equals(id)))
          .write(const StockMovementsCompanion(isDirty: Value(false)));
  Future<void> markSaleSynced(String id) =>
      (update(sales)..where((s) => s.id.equals(id)))
          .write(const SalesCompanion(isDirty: Value(false)));
}

/// Abre la base local CIFRADA con SQLCipher (ADR-004). La llave se aplica con
/// `PRAGMA key` antes de cualquier otra sentencia, en el isolate de background.
QueryExecutor _openEncrypted(SecureStore store) {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final key = await store.databaseKey();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/agora.sqlite');

    return NativeDatabase.createInBackground(
      file,
      isolateSetup: () async {
        if (Platform.isAndroid) {
          open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        }
      },
      setup: (db) {
        // Confirma que el binario es SQLCipher (si no, la base NO estaría cifrada).
        final cipher = db.select('PRAGMA cipher_version;');
        if (cipher.isEmpty) {
          throw StateError('SQLCipher no disponible: la base no quedaría cifrada');
        }
        final escaped = key.replaceAll("'", "''");
        db.execute("PRAGMA key = '$escaped';");
      },
    );
  });
}
