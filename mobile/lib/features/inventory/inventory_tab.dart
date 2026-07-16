import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/voice/voice_capture_button.dart';
import '../../shared/voice/voice_parser.dart';
import 'inventory_repository.dart';

/// Pestaña de inventario: alta de productos y ventas, sobre la base local.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
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
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del producto')),
      );
      return;
    }
    // El precio dictado puede traer coma decimal o texto ("50 pesos"): se limpia.
    final priceText = _price.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    final stockText = _stock.text.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      await ref.read(inventoryRepositoryProvider).createProduct(
            name: name,
            priceCents: ((double.tryParse(priceText) ?? 0) * 100).round(),
            initialStock: int.tryParse(stockText) ?? 0,
          );
      _name.clear();
      _price.clear();
      _stock.clear();
      ref.invalidate(productsProvider);
      messenger.showSnackBar(SnackBar(content: Text('Producto "$name" agregado')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo agregar: $error')));
    }
  }

  Future<void> _onVoiceUtterance(String transcript) async {
    final messenger = ScaffoldMessenger.of(context);
    final parsed = parseProductUtterance(transcript);
    if (parsed == null) {
      messenger.showSnackBar(SnackBar(content: Text('No entendí: "$transcript"')));
      return;
    }
    try {
      await ref.read(inventoryRepositoryProvider).createProduct(
            name: parsed.name,
            priceCents: parsed.priceCents,
            initialStock: parsed.stock,
          );
      ref.invalidate(productsProvider);
      final price = (parsed.priceCents / 100).toStringAsFixed(2);
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Agregado: ${parsed.name} — \$$price · stock ${parsed.stock}'),
      ));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo agregar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addProduct(),
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
              IconButton(icon: const Icon(Icons.add_circle), onPressed: _addProduct),
            ],
          ),
        ),
        VoiceCaptureButton(
          idleLabel: 'Dictar productos ("café 50 pesos 20 piezas")',
          onUtterance: _onVoiceUtterance,
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
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      await ref
                                          .read(inventoryRepositoryProvider)
                                          .sell(product);
                                      ref.invalidate(productsProvider);
                                    } on InsufficientStockException {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Stock insuficiente'),
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Vender'),
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
