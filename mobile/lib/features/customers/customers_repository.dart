import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

/// Clientes sobre la base LOCAL (offline-first). Se guardan con isDirty=true y
/// se suben con SyncService (entidad 'customer', last-write-wins en el servidor).
class CustomersRepository {
  CustomersRepository(this._db, this._getTenantId);

  final AppDatabase _db;
  final Future<String> Function() _getTenantId;
  static const _uuid = Uuid();

  Future<void> createCustomer({
    required String name,
    String? email,
    String? phone,
  }) async {
    final tenantId = await _getTenantId();
    await _db.into(_db.customers).insert(
          CustomersCompanion.insert(
            id: _uuid.v7(),
            tenantId: tenantId,
            name: name,
            email: Value(email),
            phone: Value(phone),
          ),
        );
  }

  Future<List<Customer>> listCustomers() => _db.activeCustomers();

  Future<void> deleteCustomer(Customer customer) async {
    await (_db.update(_db.customers)..where((c) => c.id.equals(customer.id))).write(
      CustomersCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        version: Value(customer.version + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
