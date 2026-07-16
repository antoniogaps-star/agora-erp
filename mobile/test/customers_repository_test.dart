import 'package:agora_erp_mobile/data/local/database.dart';
import 'package:agora_erp_mobile/features/customers/customers_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CustomersRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CustomersRepository(db, () async => 't1');
  });
  tearDown(() => db.close());

  test('crear cliente lo guarda local y entra en la cola outbox', () async {
    await repo.createCustomer(name: 'Juan Pérez', phone: '555-1234');

    final customers = await repo.listCustomers();
    expect(customers.single.name, 'Juan Pérez');

    // Pendiente de sincronizar hasta que el push lo marque.
    expect((await db.dirtyCustomers()).length, 1);
    await db.markCustomerSynced(customers.single.id);
    expect((await db.dirtyCustomers()).isEmpty, true);
  });
}
