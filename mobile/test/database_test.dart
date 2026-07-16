import 'package:agora_erp_mobile/data/local/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('el stock es la suma de movimientos; dos ventas restan ambas (ADR-005)', () async {
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: 'p1', tenantId: 't1', name: 'Café', priceCents: const Value(500),
          ),
        );
    // Stock inicial +10 y dos ventas de -1 (como dos dispositivos offline).
    for (final (id, delta, reason) in [('m0', 10, 'initial'), ('m1', -1, 'sale'), ('m2', -1, 'sale')]) {
      await db.into(db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: id, tenantId: 't1', productId: 'p1', delta: delta, reason: reason,
            ),
          );
    }
    final stock = await db.stockByProduct();
    expect(stock['p1'], 8);
  });

  test('la cola outbox refleja lo pendiente de subir', () async {
    await db.into(db.products).insert(
          ProductsCompanion.insert(id: 'p1', tenantId: 't1', name: 'X'),
        );
    expect((await db.dirtyProducts()).length, 1);
    await db.markProductSynced('p1');
    expect((await db.dirtyProducts()).isEmpty, true);
  });
}
