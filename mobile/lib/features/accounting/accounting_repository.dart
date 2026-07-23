import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

/// Contabilidad sobre la base LOCAL (offline-first). Cada asiento se guarda con
/// isDirty=true y se sube después con SyncService (entidad 'ledger_entry',
/// last-write-wins en el servidor). Aparece también en el panel web.
class AccountingRepository {
  AccountingRepository(this._db, this._getTenantId);

  final AppDatabase _db;
  final Future<String> Function() _getTenantId;
  static const _uuid = Uuid();

  Future<List<LedgerEntry>> list() => _db.activeLedger();

  /// Registra un ingreso o egreso. `type` es 'income' o 'expense'.
  Future<void> addEntry({
    required String type,
    required String concept,
    required int amountCents,
    required DateTime date,
  }) async {
    final tenantId = await _getTenantId();
    await _db.into(_db.ledgerEntries).insert(
          LedgerEntriesCompanion.insert(
            id: _uuid.v7(),
            tenantId: tenantId,
            entryType: type,
            concept: concept,
            amountCents: amountCents,
            occurredOn: _isoDate(date),
          ),
        );
  }

  /// Borrado lógico (tombstone): se marca eliminado y queda pendiente de subir.
  Future<void> deleteEntry(LedgerEntry e) async {
    await (_db.update(_db.ledgerEntries)..where((t) => t.id.equals(e.id))).write(
      LedgerEntriesCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        version: Value(e.version + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
