import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Pantalla principal: inventario offline-first. Alta de productos y ventas se guardan
/// en la base local (funciona sin conexión) y se suben con el botón de sincronizar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await ref.read(inventoryRepositoryProvider).createProduct(
          name: name,
          priceCents: ((double.tryParse(_price.text) ?? 0) * 100).round(),
          initialStock: int.tryParse(_stock.text) ?? 0,
        );
    _name.clear();
    _price.clear();
    _stock.clear();
    ref.invalidate(productsProvider);
  }

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sync = ref.read(syncServiceProvider);
      await sync.push();
      await sync.pull();
      ref.invalidate(productsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Sincronización completa')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sin conexión: se sincronizará luego')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), tooltip: 'Sincronizar', onPressed: _sync),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Producto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addProduct,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) => rows.isEmpty
                  ? const Center(child: Text('Sin productos todavía'))
                  : ListView(
                      children: [
                        for (final (product, stock) in rows)
                          ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '\$${(product.priceCents / 100).toStringAsFixed(2)} · stock: $stock',
                            ),
                            trailing: FilledButton(
                              onPressed: stock < 1
                                  ? null
                                  : () async {
                                      await ref
                                          .read(inventoryRepositoryProvider)
                                          .sell(product);
                                      ref.invalidate(productsProvider);
                                    },
                              child: const Text('Vender'),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
