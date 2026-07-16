import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/voice/voice_capture_button.dart';
import '../../shared/voice/voice_parser.dart';

/// Pestaña de clientes: alta y listado sobre la base local (offline-first).
class CustomersTab extends ConsumerStatefulWidget {
  const CustomersTab({super.key});

  @override
  ConsumerState<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<CustomersTab> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del cliente')),
      );
      return;
    }
    final phone = _phone.text.trim();
    try {
      await ref.read(customersRepositoryProvider).createCustomer(
            name: name,
            phone: phone.isEmpty ? null : phone,
          );
      _name.clear();
      _phone.clear();
      ref.invalidate(customersProvider);
      messenger.showSnackBar(SnackBar(content: Text('Cliente "$name" agregado')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo agregar: $error')));
    }
  }

  Future<void> _onVoiceUtterance(String transcript) async {
    final messenger = ScaffoldMessenger.of(context);
    final parsed = parseCustomerUtterance(transcript);
    if (parsed == null) {
      messenger.showSnackBar(SnackBar(content: Text('No entendí: "$transcript"')));
      return;
    }
    try {
      await ref.read(customersRepositoryProvider).createCustomer(
            name: parsed.name,
            phone: parsed.phone,
          );
      ref.invalidate(customersProvider);
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Agregado: ${parsed.name}'
            '${parsed.phone == null ? '' : ' · tel ${parsed.phone}'}'),
      ));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo agregar: $error')));
    }
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustomer(),
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
              ),
              IconButton(icon: const Icon(Icons.person_add), onPressed: _addCustomer),
            ],
          ),
        ),
        VoiceCaptureButton(
          idleLabel: 'Dictar clientes ("Juan Pérez teléfono 5551234567")',
          onUtterance: _onVoiceUtterance,
        ),
        const Divider(height: 1),
        Expanded(
          child: customers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('Sin clientes todavía'))
                : ListView(
                    children: [
                      for (final customer in rows)
                        Dismissible(
                          key: ValueKey(customer.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(customer.name),
                          onDismissed: (_) async {
                            await ref
                                .read(customersRepositoryProvider)
                                .deleteCustomer(customer);
                            ref.invalidate(customersProvider);
                          },
                          background: Container(
                            color: Colors.red.shade600,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(customer.name),
                            subtitle: customer.phone == null
                                ? null
                                : Text(customer.phone!),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
