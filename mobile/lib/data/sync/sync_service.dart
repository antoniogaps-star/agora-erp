import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';

/// El servidor rechazó la subida (HTTP 402) porque la prueba gratis o el plan de pago
/// venció. Los cambios locales quedan intactos (siguen `isDirty`) y se subirán en cuanto
/// se reactive la cuenta con una clave. La UI la distingue de un fallo de red para mostrar
/// "renueva tu plan" en vez de "sin conexión".
class SubscriptionExpiredException implements Exception {
  const SubscriptionExpiredException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Motor de sincronización (patrón outbox). Sube los cambios locales pendientes de las
/// tres entidades y aplica los del servidor. Ver docs/07_App_Movil.md y ADR-005.
class SyncService {
  SyncService(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  Future<void> push() async {
    final products = await _db.dirtyProducts();
    final movements = await _db.dirtyMovements();
    final sales = await _db.dirtySales();
    final customers = await _db.dirtyCustomers();
    final ledger = await _db.dirtyLedger();

    final changes = <Map<String, dynamic>>[
      for (final p in products)
        {
          'entity': 'product',
          'id': p.id,
          'op': p.isDeleted ? 'delete' : 'upsert',
          'version': p.version,
          'updated_at': p.updatedAt.toUtc().toIso8601String(),
          'data': {'name': p.name, 'price_cents': p.priceCents},
        },
      for (final m in movements)
        {
          'entity': 'stock_movement',
          'id': m.id,
          'op': 'upsert',
          'version': m.version,
          'updated_at': m.updatedAt.toUtc().toIso8601String(),
          'data': {'product_id': m.productId, 'delta': m.delta, 'reason': m.reason},
        },
      for (final s in sales)
        {
          'entity': 'sale',
          'id': s.id,
          'op': 'upsert',
          'version': s.version,
          'updated_at': s.updatedAt.toUtc().toIso8601String(),
          'data': {
            'product_id': s.productId,
            'quantity': s.quantity,
            'unit_price_cents': s.unitPriceCents,
            'total_cents': s.totalCents,
          },
        },
      for (final c in customers)
        {
          'entity': 'customer',
          'id': c.id,
          'op': c.isDeleted ? 'delete' : 'upsert',
          'version': c.version,
          'updated_at': c.updatedAt.toUtc().toIso8601String(),
          'data': {'name': c.name, 'email': c.email, 'phone': c.phone},
        },
      for (final e in ledger)
        {
          'entity': 'ledger_entry',
          'id': e.id,
          'op': e.isDeleted ? 'delete' : 'upsert',
          'version': e.version,
          'updated_at': e.updatedAt.toUtc().toIso8601String(),
          'data': {
            'entry_type': e.entryType,
            'concept': e.concept,
            'amount_cents': e.amountCents,
            'occurred_on': e.occurredOn,
          },
        },
    ];

    if (changes.isEmpty) return;

    final Response<dynamic> response;
    try {
      response = await _dio.post('/sync/push', data: {'changes': changes});
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        final data = e.response?.data;
        final msg = data is Map
            ? (data['error'] is Map ? data['error']['message'] as String? : null)
            : null;
        throw SubscriptionExpiredException(
          msg ?? 'Tu prueba o plan venció. Renueva para volver a sincronizar.',
        );
      }
      rethrow;
    }
    final results = (response.data['results'] as List).cast<Map<String, dynamic>>();

    for (final r in results) {
      if (r['status'] != 'applied') continue;
      final id = r['id'] as String;
      switch (r['entity']) {
        case 'product':
          await _db.markProductSynced(id);
        case 'stock_movement':
          await _db.markMovementSynced(id);
        case 'sale':
          await _db.markSaleSynced(id);
        case 'customer':
          await _db.markCustomerSynced(id);
        case 'ledger_entry':
          await _db.markLedgerSynced(id);
      }
    }
  }

  Future<void> pull() async {
    final response = await _dio.get('/sync/pull');
    final changes = (response.data['changes'] as List).cast<Map<String, dynamic>>();
    for (final change in changes) {
      await _applyRemote(change);
    }
  }

  Future<void> _applyRemote(Map<String, dynamic> change) async {
    final id = change['id'] as String;
    final data = (change['data'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (change['entity']) {
      case 'product':
        await _db.into(_db.products).insertOnConflictUpdate(
              ProductsCompanion.insert(
                id: id,
                tenantId: change['tenant_id'] as String? ?? '',
                name: data['name'] as String? ?? '',
                priceCents: Value(data['price_cents'] as int? ?? 0),
                isDeleted: Value(change['op'] == 'delete'),
                isDirty: const Value(false),
              ),
            );
      case 'stock_movement':
        await _db.into(_db.stockMovements).insertOnConflictUpdate(
              StockMovementsCompanion.insert(
                id: id,
                tenantId: change['tenant_id'] as String? ?? '',
                productId: data['product_id'] as String,
                delta: data['delta'] as int,
                reason: data['reason'] as String,
                isDirty: const Value(false),
              ),
            );
      case 'sale':
        await _db.into(_db.sales).insertOnConflictUpdate(
              SalesCompanion.insert(
                id: id,
                tenantId: change['tenant_id'] as String? ?? '',
                productId: data['product_id'] as String,
                quantity: data['quantity'] as int,
                unitPriceCents: data['unit_price_cents'] as int,
                totalCents: data['total_cents'] as int,
                isDirty: const Value(false),
              ),
            );
      case 'customer':
        await _db.into(_db.customers).insertOnConflictUpdate(
              CustomersCompanion.insert(
                id: id,
                tenantId: change['tenant_id'] as String? ?? '',
                name: data['name'] as String? ?? '',
                email: Value(data['email'] as String?),
                phone: Value(data['phone'] as String?),
                isDeleted: Value(change['op'] == 'delete'),
                isDirty: const Value(false),
              ),
            );
      case 'ledger_entry':
        await _db.into(_db.ledgerEntries).insertOnConflictUpdate(
              LedgerEntriesCompanion.insert(
                id: id,
                tenantId: change['tenant_id'] as String? ?? '',
                entryType: data['entry_type'] as String? ?? 'income',
                concept: data['concept'] as String? ?? '',
                amountCents: data['amount_cents'] as int? ?? 0,
                occurredOn: data['occurred_on'] as String? ?? '',
                isDeleted: Value(change['op'] == 'delete'),
                isDirty: const Value(false),
              ),
            );
    }
  }
}
