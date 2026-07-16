import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../auth/auth_repository.dart';

/// Operaciones de inventario/ventas sobre la base LOCAL (offline-first).
/// Todo se guarda con isDirty=true y se sube después con SyncService.
class InventoryRepository {
  InventoryRepository(this._db, this._auth);

  final AppDatabase _db;
  final AuthRepository _auth;
  static const _uuid = Uuid();

  Future<void> createProduct({
    required String name,
    required int priceCents,
    int initialStock = 0,
  }) async {
    final tenantId = await _auth.currentTenantId();
    final productId = _uuid.v7();
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: productId,
            tenantId: tenantId,
            name: name,
            priceCents: Value(priceCents),
          ),
        );
    if (initialStock > 0) {
      await _addMovement(tenantId, productId, initialStock, 'initial');
    }
  }

  Future<void> sell(Product product, {int quantity = 1}) async {
    final tenantId = await _auth.currentTenantId();
    await _db.into(_db.sales).insert(
          SalesCompanion.insert(
            id: _uuid.v7(),
            tenantId: tenantId,
            productId: product.id,
            quantity: quantity,
            unitPriceCents: product.priceCents,
            totalCents: product.priceCents * quantity,
          ),
        );
    await _addMovement(tenantId, product.id, -quantity, 'sale');
  }

  Future<List<(Product, int)>> productsWithStock() async {
    final products = await _db.activeProducts();
    final stock = await _db.stockByProduct();
    return [for (final p in products) (p, stock[p.id] ?? 0)];
  }

  Future<void> _addMovement(
    String tenantId,
    String productId,
    int delta,
    String reason,
  ) {
    return _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            id: _uuid.v7(),
            tenantId: tenantId,
            productId: productId,
            delta: delta,
            reason: reason,
          ),
        );
  }
}
