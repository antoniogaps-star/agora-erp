import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/local/database.dart';

/// Tenant ficticio para el modo demostración. Todo lo sembrado y borrado por el
/// [DemoSeeder] queda acotado a este tenant, para NO tocar jamás datos reales que
/// el dispositivo pudiera tener de una empresa de verdad.
const String kDemoTenantId = 'demo-local-tenant';

/// Un producto de ejemplo con su stock inicial (en piezas).
class _DemoProduct {
  const _DemoProduct(this.name, this.priceCents, this.stock);
  final String name;
  final int priceCents;
  final int stock;
}

/// Carga (y reinicia) la base LOCAL con datos fijos de demostración, sin necesidad
/// de servidor ni conexión. Sirve para enseñarle la app a un cliente: siempre se ve
/// igual y funciona aunque no haya señal.
///
/// Todo se guarda con `isDirty: false` para que NUNCA entre en la cola de subida:
/// el modo demo no sincroniza con el servidor.
class DemoSeeder {
  DemoSeeder(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // Catálogo tipo tiendita de abarrotes.
  static const _products = <_DemoProduct>[
    _DemoProduct('Coca-Cola 600ml', 1800, 24),
    _DemoProduct('Sabritas Original', 1700, 30),
    _DemoProduct('Agua Ciel 1L', 1200, 40),
    _DemoProduct('Pan Bimbo grande', 4200, 15),
    _DemoProduct('Leche Lala 1L', 2600, 18),
    _DemoProduct('Galletas Marías', 1500, 25),
    _DemoProduct('Jabón Zote', 2200, 12),
    _DemoProduct('Café soluble 50g', 4800, 10),
    _DemoProduct('Arroz 1kg', 2800, 22),
    _DemoProduct('Aceite 1L', 3500, 14),
  ];

  static const _customers = <(String, String)>[
    ('María González', '55 1234 5678'),
    ('Tienda Don Chuy', '55 8765 4321'),
    ('Abarrotes La Esquina', '55 2468 1357'),
    ('José Martínez', '55 9753 8642'),
  ];

  /// Borra los datos de demo y vuelve a sembrarlos limpios. Cada demostración
  /// empieza igual, sin importar lo que el cliente haya tocado antes.
  Future<void> reset() async {
    await wipe();
    await _seed();
  }

  /// Elimina físicamente TODO lo etiquetado con el tenant de demo. No toca datos
  /// de ningún otro tenant (empresa real).
  Future<void> wipe() async {
    await _db.transaction(() async {
      await (_db.delete(_db.sales)
            ..where((t) => t.tenantId.equals(kDemoTenantId)))
          .go();
      await (_db.delete(_db.stockMovements)
            ..where((t) => t.tenantId.equals(kDemoTenantId)))
          .go();
      await (_db.delete(_db.products)
            ..where((t) => t.tenantId.equals(kDemoTenantId)))
          .go();
      await (_db.delete(_db.customers)
            ..where((t) => t.tenantId.equals(kDemoTenantId)))
          .go();
    });
  }

  Future<void> _seed() async {
    await _db.transaction(() async {
      final ids = <String>[];
      for (final p in _products) {
        final id = _uuid.v7();
        ids.add(id);
        await _db.into(_db.products).insert(
              ProductsCompanion.insert(
                id: id,
                tenantId: kDemoTenantId,
                name: p.name,
                priceCents: Value(p.priceCents),
                isDirty: const Value(false),
              ),
            );
        await _addMovement(id, p.stock, 'initial');
      }

      for (final (name, phone) in _customers) {
        await _db.into(_db.customers).insert(
              CustomersCompanion.insert(
                id: _uuid.v7(),
                tenantId: kDemoTenantId,
                name: name,
                phone: Value(phone),
                isDirty: const Value(false),
              ),
            );
      }

      // Algunas ventas de ejemplo para que la demo se vea "usada".
      await _sale(ids[0], _products[0], 2); // 2 Coca-Cola
      await _sale(ids[3], _products[3], 1); // 1 Pan Bimbo
      await _sale(ids[2], _products[2], 3); // 3 Agua Ciel
    });
  }

  Future<void> _sale(String productId, _DemoProduct p, int qty) async {
    await _db.into(_db.sales).insert(
          SalesCompanion.insert(
            id: _uuid.v7(),
            tenantId: kDemoTenantId,
            productId: productId,
            quantity: qty,
            unitPriceCents: p.priceCents,
            totalCents: p.priceCents * qty,
            isDirty: const Value(false),
          ),
        );
    await _addMovement(productId, -qty, 'sale');
  }

  Future<void> _addMovement(String productId, int delta, String reason) {
    return _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            id: _uuid.v7(),
            tenantId: kDemoTenantId,
            productId: productId,
            delta: delta,
            reason: reason,
            isDirty: const Value(false),
          ),
        );
  }
}
