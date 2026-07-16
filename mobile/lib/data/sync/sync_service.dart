import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';

/// Motor de sincronización (ESQUELETO). Implementa la mecánica del patrón outbox:
/// subir los cambios locales pendientes y aplicar los del servidor. La resolución
/// de conflictos por entidad se añade con el motor real (ver docs/07_App_Movil.md).
class SyncService {
  SyncService(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  /// PUSH: envía la cola outbox (registros isDirty) y limpia el flag en los aceptados.
  Future<void> push() async {
    final pending = await _db.pendingChanges();
    if (pending.isEmpty) return;

    final changes = pending
        .map((p) => <String, dynamic>{
              'entity': 'product',
              'id': p.id,
              'op': p.isDeleted ? 'delete' : 'upsert',
              'version': p.version,
              'updated_at': p.updatedAt.toUtc().toIso8601String(),
              'data': {'name': p.name, 'price_cents': p.priceCents},
            })
        .toList();

    final response = await _dio.post('/sync/push', data: {'changes': changes});
    final results = (response.data['results'] as List).cast<Map<String, dynamic>>();

    for (final result in results) {
      if (result['status'] == 'applied') {
        await (_db.update(_db.products)
              ..where((t) => t.id.equals(result['id'] as String)))
            .write(const ProductsCompanion(isDirty: Value(false)));
      }
    }
  }

  /// PULL: descarga los cambios del servidor (deltas) y los aplica a la base local.
  Future<void> pull() async {
    final response = await _dio.get('/sync/pull');
    final changes = (response.data['changes'] as List).cast<Map<String, dynamic>>();
    for (final change in changes) {
      await _applyRemote(change);
    }
  }

  Future<void> _applyRemote(Map<String, dynamic> change) async {
    if (change['entity'] != 'product') return;
    final id = change['id'] as String;

    if (change['op'] == 'delete') {
      await (_db.delete(_db.products)..where((t) => t.id.equals(id))).go();
      return;
    }

    final data = change['data'] as Map<String, dynamic>;
    await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: id,
            tenantId: change['tenant_id'] as String? ?? '',
            name: data['name'] as String,
            priceCents: Value(data['price_cents'] as int? ?? 0),
            isDirty: const Value(false),
          ),
        );
  }
}
