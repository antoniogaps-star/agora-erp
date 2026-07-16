import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

/// Se lanza al intentar vender más que el stock local conocido.
class InsufficientStockException implements Exception {
  InsufficientStockException({required this.available, required this.requested});

  final int available;
  final int requested;

  @override
  String toString() => 'Stock insuficiente: hay $available, se pidieron $requested';
}

/// Operaciones de inventario/ventas sobre la base LOCAL (offline-first).
/// Todo se guarda con isDirty=true y se sube después con SyncService.
///
/// El `tenantId` se obtiene mediante una función (normalmente del JWT) para no acoplar
/// el repositorio al almacenamiento seguro y poder probarlo sin plugins de plataforma.
class InventoryRepository {
  InventoryRepository(this._db, this._getTenantId);

  final AppDatabase _db;
  final Future<String> Function() _getTenantId;
  static const _uuid = Uuid();

  Future<void> createProduct({
    required String name,
    required int priceCents,
    int initialStock = 0,
  }) async {
    final tenantId = await _getTenantId();
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
    // Guarda offline: no vender más de lo que el dispositivo cree tener.
    final available = (await _db.stockByProduct())[product.id] ?? 0;
    if (quantity > available) {
      throw InsufficientStockException(available: available, requested: quantity);
    }

    final tenantId = await _getTenantId();
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
