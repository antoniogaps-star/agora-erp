import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../../shared/voice/voice_parser.dart';

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
/// Resultado de interpretar un dictado: nombre + piezas + una nota del cálculo.
class VoiceProduct {
  const VoiceProduct(this.name, this.pieces, {this.note});
  final String name;
  final int pieces;
  final String? note;
}

class InventoryRepository {
  InventoryRepository(this._db, this._getTenantId, this._dio);

  final AppDatabase _db;
  final Future<String> Function() _getTenantId;
  final Dio _dio;
  static const _uuid = Uuid();

  /// Interpreta un dictado. Intenta la IA del servidor (entiende nombres reales);
  /// si no hay internet o IA, usa las reglas locales de respaldo.
  Future<VoiceProduct?> interpretVoice(String transcript) async {
    try {
      final resp = await _dio.post(
        '/products/voice-parse',
        data: {'transcript': transcript},
      );
      final name = (resp.data['name'] as String? ?? '').trim();
      if (name.isEmpty) return null;
      return VoiceProduct(name, resp.data['pieces'] as int? ?? 0,
          note: resp.data['note'] as String?);
    } catch (_) {
      final parsed = parseProductUtterance(transcript);
      if (parsed == null || parsed.packSizeMissing) return null;
      return VoiceProduct(parsed.name, parsed.pieces);
    }
  }

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

  /// Borrado lógico (tombstone): se marca eliminado y queda pendiente de subir; al
  /// sincronizar desaparece también en el servidor y demás dispositivos.
  Future<void> deleteProduct(Product product) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(product.id))).write(
      ProductsCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        version: Value(product.version + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
