import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/local/database.dart';
import 'ticket.dart';

/// Abre la ventana para vender un producto por presentaciones. Devuelve el ticket
/// si la venta se concreta, o null si se cancela.
Future<SaleTicket?> showSellSheet(
  BuildContext context,
  Product product,
  int stock,
  String business,
) {
  return showModalBottomSheet<SaleTicket>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _SellSheet(product: product, stock: stock, business: business),
    ),
  );
}

class _SellSheet extends ConsumerStatefulWidget {
  const _SellSheet({required this.product, required this.stock, required this.business});
  final Product product;
  final int stock;
  final String business;

  @override
  ConsumerState<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends ConsumerState<_SellSheet> {
  late final TextEditingController _precio = TextEditingController(
    text: widget.product.priceCents > 0
        ? (widget.product.priceCents / 100).toStringAsFixed(2)
        : '',
  );
  final _cajaSize = TextEditingController(text: '24');
  final _cliente = TextEditingController(text: 'Cliente');
  int _piezas = 0;
  int _six = 0;
  int _cajas = 0;
  String? _error;

  @override
  void dispose() {
    _precio.dispose();
    _cajaSize.dispose();
    _cliente.dispose();
    super.dispose();
  }

  int get _cajaSizeVal => int.tryParse(_cajaSize.text.trim()) ?? 0;
  int get _totalPieces => _piezas + _six * 6 + _cajas * _cajaSizeVal;
  int get _priceCents => ((double.tryParse(_precio.text.trim().replaceAll(',', '.')) ?? 0) * 100).round();
  int get _totalCents => _priceCents * _totalPieces;

  Future<void> _vender() async {
    if (_priceCents <= 0) {
      setState(() => _error = 'Escribe el precio por pieza.');
      return;
    }
    if (_totalPieces <= 0) {
      setState(() => _error = 'Indica cuánto vas a vender.');
      return;
    }
    if (_totalPieces > widget.stock) {
      setState(() => _error = 'No hay suficiente: tienes ${widget.stock} piezas.');
      return;
    }
    final repo = ref.read(inventoryRepositoryProvider);
    try {
      if (_priceCents != widget.product.priceCents) {
        await repo.updateProductPrice(widget.product, _priceCents);
      }
      await repo.sell(widget.product, quantity: _totalPieces, unitPriceCents: _priceCents);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      final ticket = SaleTicket(
        business: widget.business,
        customer: _cliente.text.trim().isEmpty ? 'Cliente' : _cliente.text.trim(),
        productName: widget.product.name,
        piezas: _piezas,
        six: _six,
        cajas: _cajas,
        cajaSize: _cajaSizeVal,
        totalPieces: _totalPieces,
        unitPriceCents: _priceCents,
        totalCents: _totalCents,
        date: DateTime.now(),
      );
      Navigator.of(context).pop(ticket);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo vender: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vender ${widget.product.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Disponible: ${widget.stock} piezas', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Precio por pieza',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 12),
          _Stepper(label: 'Piezas', value: _piezas, max: 12, onChanged: (v) => setState(() => _piezas = v)),
          _Stepper(label: 'Six (6 pzs)', value: _six, max: 12, onChanged: (v) => setState(() => _six = v)),
          _Stepper(label: 'Cajas', value: _cajas, max: 999, onChanged: (v) => setState(() => _cajas = v)),
          if (_cajas > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: SizedBox(
                width: 180,
                child: TextField(
                  controller: _cajaSize,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Piezas por caja'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _cliente,
            decoration: const InputDecoration(labelText: 'Cliente (para el ticket)'),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total: $_totalPieces piezas',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('A cobrar: ${SaleTicket.money(_totalCents)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _vender,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Vender y hacer ticket'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
