import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

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
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final phone = _phone.text.trim();
    await ref.read(customersRepositoryProvider).createCustomer(
          name: name,
          phone: phone.isEmpty ? null : phone,
        );
    _name.clear();
    _phone.clear();
    ref.invalidate(customersProvider);
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
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(customer.name),
                          subtitle: customer.phone == null
                              ? null
                              : Text(customer.phone!),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
