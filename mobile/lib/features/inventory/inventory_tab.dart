import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/voice/voice_capture_button.dart';
import '../../shared/voice/voice_parser.dart';
import 'inventory_repository.dart';

/// Pestaña de inventario: producto + piezas (en sus presentaciones de llegada).
/// El precio no se maneja aquí; pertenece a la venta.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  final _name = TextEditingController();
  final _pieces = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pieces.dispose();
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
    final pieces = int.tryParse(_pieces.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    try {
      await ref.read(inventoryRepositoryProvider).createProduct(
            name: name,
            priceCents: 0,
            initialStock: pieces,
          );
      _name.clear();
      _pieces.clear();
      ref.invalidate(productsProvider);
      messenger.showSnackBar(SnackBar(content: Text('Agregado: $name · $pieces piezas')));
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
    if (parsed.packSizeMissing) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Di el tamaño: "${parsed.name} 5 ${parsed.presentation} de 24"',
        ),
      ));
      return;
    }
    try {
      await ref.read(inventoryRepositoryProvider).createProduct(
            name: parsed.name,
            priceCents: 0,
            initialStock: parsed.pieces,
          );
      ref.invalidate(productsProvider);
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Agregado: ${parsed.name} · ${parsed.pieces} piezas'),
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
                  controller: _pieces,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Piezas'),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: _addProduct),
            ],
          ),
        ),
        VoiceCaptureButton(
          idleLabel: 'Dictar inventario ("coca cola 5 cajas de 24")',
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
                          subtitle: Text('$stock piezas'),
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
