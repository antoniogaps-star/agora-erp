import 'package:agora_erp_mobile/core/demo.dart';
import 'package:agora_erp_mobile/data/local/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DemoSeeder seeder;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    seeder = DemoSeeder(db);
  });
  tearDown(() => db.close());

  test('reset carga productos, clientes y stock de ejemplo', () async {
    await seeder.reset();

    expect((await db.activeProducts()).length, 10);
    expect((await db.activeCustomers()).length, 4);

    // El stock refleja las ventas de ejemplo (suma de movimientos, ADR-005).
    final stock = await db.stockByProduct();
    final byName = {for (final p in await db.activeProducts()) p.name: stock[p.id] ?? 0};
    expect(byName['Coca-Cola 600ml'], 24 - 2);
    expect(byName['Agua Ciel 1L'], 40 - 3);
    expect(byName['Pan Bimbo grande'], 15 - 1);
  });

  test('los datos de demo nunca entran en la cola de subida (isDirty=false)', () async {
    await seeder.reset();

    expect((await db.dirtyProducts()).isEmpty, true);
    expect((await db.dirtyMovements()).isEmpty, true);
    expect((await db.dirtySales()).isEmpty, true);
    expect((await db.dirtyCustomers()).isEmpty, true);
  });

  test('reset es idempotente: no duplica los datos', () async {
    await seeder.reset();
    await seeder.reset();
    expect((await db.activeProducts()).length, 10);
    expect((await db.activeCustomers()).length, 4);
  });

  test('wipe borra la demo pero respeta los datos de una empresa real', () async {
    // Dato de una empresa real (otro tenant) en el mismo dispositivo.
    await db.into(db.products).insert(
          ProductsCompanion.insert(id: 'real-1', tenantId: 'empresa-real', name: 'Producto real'),
        );

    await seeder.reset();
    await seeder.wipe();

    final remaining = await db.activeProducts();
    expect(remaining.length, 1);
    expect(remaining.single.id, 'real-1');
  });
}
