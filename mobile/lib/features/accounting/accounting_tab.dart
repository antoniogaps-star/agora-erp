import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

/// Pestaña de Contabilidad (Caja): registra ingresos y egresos, muestra el saldo y la
/// lista de movimientos. Todo local (offline) y se sincroniza con el panel web.
class AccountingTab extends ConsumerStatefulWidget {
  const AccountingTab({super.key});

  @override
  ConsumerState<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends ConsumerState<AccountingTab> {
  final _concept = TextEditingController();
  final _amount = TextEditingController();
  String _type = 'income';
  bool _saving = false;

  @override
  void dispose() {
    _concept.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final messenger = ScaffoldMessenger.of(context);
    final concept = _concept.text.trim();
    final cents = ((double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0) * 100).round();
    if (concept.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Escribe el concepto')));
      return;
    }
    if (cents <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Escribe un importe válido')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountingRepositoryProvider).addEntry(
            type: _type,
            concept: concept,
            amountCents: cents,
            date: DateTime.now(),
          );
      _concept.clear();
      _amount.clear();
      ref.invalidate(ledgerProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('${_type == 'income' ? 'Ingreso' : 'Egreso'} registrado: ${_money(cents)}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo registrar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ledgerProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No se pudo cargar la contabilidad: $e'),
      )),
      data: (entries) {
        var income = 0, expense = 0;
        for (final e in entries) {
          if (e.entryType == 'income') {
            income += e.amountCents;
          } else {
            expense += e.amountCents;
          }
        }
        final balance = income - expense;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _MoneyCard('Ingresos', _money(income), const Color(0xFF15803D))),
                  const SizedBox(width: 8),
                  Expanded(child: _MoneyCard('Egresos', _money(expense), const Color(0xFFB91C1C))),
                  const SizedBox(width: 8),
                  Expanded(child: _MoneyCard('Saldo', _money(balance),
                      balance >= 0 ? const Color(0xFF2F6DF6) : const Color(0xFFB91C1C))),
                ],
              ),
            ),
            _NewEntryForm(
              type: _type,
              concept: _concept,
              amount: _amount,
              saving: _saving,
              onType: (t) => setState(() => _type = t),
              onRegister: _register,
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Sin movimientos todavía', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: [
                        for (final e in entries)
                          Dismissible(
                            key: ValueKey(e.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(e.concept),
                            onDismissed: (_) async {
                              await ref.read(accountingRepositoryProvider).deleteEntry(e);
                              ref.invalidate(ledgerProvider);
                            },
                            background: Container(
                              color: Colors.red.shade600,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              leading: Icon(
                                e.entryType == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                                color: e.entryType == 'income'
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                              title: Text(e.concept),
                              subtitle: Text(e.occurredOn),
                              trailing: Text(
                                '${e.entryType == 'income' ? '+' : '−'}${_money(e.amountCents)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: e.entryType == 'income'
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(String concept) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Borrar "$concept"?'),
        content: const Text('Se quitará del balance al sincronizar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _NewEntryForm extends StatelessWidget {
  const _NewEntryForm({
    required this.type,
    required this.concept,
    required this.amount,
    required this.saving,
    required this.onType,
    required this.onRegister,
  });
  final String type;
  final TextEditingController concept;
  final TextEditingController amount;
  final bool saving;
  final ValueChanged<String> onType;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'income', label: Text('Ingreso'), icon: Icon(Icons.add)),
              ButtonSegment(value: 'expense', label: Text('Egreso'), icon: Icon(Icons.remove)),
            ],
            selected: {type},
            onSelectionChanged: (s) => onType(s.first),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: concept,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(labelText: 'Importe', prefixText: '\$ '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onRegister,
              icon: const Icon(Icons.save),
              label: Text(saving ? 'Guardando…' : 'Registrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard(this.label, this.amount, this.color);
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(amount,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
