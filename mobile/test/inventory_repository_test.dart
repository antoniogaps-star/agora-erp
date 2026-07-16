import 'package:agora_erp_mobile/data/local/database.dart';
import 'package:agora_erp_mobile/features/inventory/inventory_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = InventoryRepository(db, () async => 't1');
  });
  tearDown(() => db.close());

  test('vender descuenta del stock local', () async {
    await repo.createProduct(name: 'Café', priceCents: 500, initialStock: 3);
    final (product, _) = (await repo.productsWithStock()).first;

    await repo.sell(product); // vende 1
    final (_, stock) = (await repo.productsWithStock()).first;
    expect(stock, 2);
  });

  test('no permite vender más que el stock local (guarda offline)', () async {
    await repo.createProduct(name: 'Té', priceCents: 300, initialStock: 1);
    final (product, _) = (await repo.productsWithStock()).first;

    expect(
      () => repo.sell(product, quantity: 5),
      throwsA(isA<InsufficientStockException>()),
    );
  });
}
