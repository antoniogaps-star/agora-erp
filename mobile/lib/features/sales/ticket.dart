/// Datos de un ticket de venta (de un producto, en sus presentaciones).
class SaleTicket {
  SaleTicket({
    required this.business,
    required this.customer,
    required this.productName,
    required this.piezas,
    required this.six,
    required this.cajas,
    required this.cajaSize,
    required this.totalPieces,
    required this.unitPriceCents,
    required this.totalCents,
    required this.date,
  });

  final String business;
  final String customer;
  final String productName;
  final int piezas;
  final int six;
  final int cajas;
  final int cajaSize;
  final int totalPieces;
  final int unitPriceCents;
  final int totalCents;
  final DateTime date;

  static String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  String _fecha() {
    final d = date;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Desglose legible de la presentación (ej. "2 cajas (24) + 1 six + 3 piezas").
  String presentacion() {
    final partes = <String>[];
    if (cajas > 0) partes.add('$cajas caja${cajas == 1 ? '' : 's'} ($cajaSize)');
    if (six > 0) partes.add('$six six');
    if (piezas > 0) partes.add('$piezas pieza${piezas == 1 ? '' : 's'}');
    return partes.isEmpty ? '$totalPieces piezas' : partes.join(' + ');
  }

  /// Texto del ticket, listo para WhatsApp o para compartir.
  String text() {
    final b = StringBuffer();
    b.writeln('🧾 *${business.isEmpty ? 'Ágora ERP' : business}*');
    b.writeln('Ticket de venta · ${_fecha()}');
    b.writeln('Cliente: $customer');
    b.writeln('--------------------------------');
    b.writeln(productName);
    b.writeln('  ${presentacion()} = $totalPieces piezas');
    b.writeln('  ${money(unitPriceCents)} c/u');
    b.writeln('--------------------------------');
    b.writeln('*TOTAL: ${money(totalCents)}*');
    b.writeln('');
    b.writeln('Gracias por su compra 🙌');
    return b.toString();
  }
}
