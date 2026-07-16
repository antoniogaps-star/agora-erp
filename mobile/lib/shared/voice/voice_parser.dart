/// Intérpretes de dictado: convierten una frase reconocida en datos estructurados.
///
/// Formatos entendidos (el reconocedor de Android entrega los números como dígitos):
///   Producto: `nombre [precio] [stock]`
///     "café 50 pesos 20 piezas"        → Café, $50.00, stock 20
///     "té verde precio 80.50 stock 30" → Té verde, $80.50, stock 30
///     "galletas"                       → Galletas, $0, stock 0
///   Cliente: `nombre [teléfono dígitos]`
///     "Juan Pérez teléfono 555 123 4567" → Juan Pérez, 5551234567
library;

import 'spanish_numbers.dart';

class ParsedProduct {
  const ParsedProduct({
    required this.name,
    required this.priceCents,
    required this.stock,
  });

  final String name;
  final int priceCents;
  final int stock;
}

class ParsedCustomer {
  const ParsedCustomer({required this.name, this.phone});

  final String name;
  final String? phone;
}

final _numberPattern = RegExp(r'\d+(?:[.,]\d+)?');
final _trailingFiller =
    RegExp(r'\b(precio|cuesta|vale|a|de|en|el|la|con)\s*$', caseSensitive: false);

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

ParsedProduct? parseProductUtterance(String transcript) {
  // "café cincuenta pesos veinte piezas" → "café 50 pesos 20 piezas"
  final text = normalizeSpanishNumbers(transcript.trim()).toLowerCase();
  if (text.isEmpty) return null;

  final numbers = _numberPattern.allMatches(text).toList();
  var namePart = numbers.isEmpty ? text : text.substring(0, numbers.first.start);
  namePart = namePart.replaceAll(_trailingFiller, '').trim();
  if (namePart.isEmpty) return null;

  double price = 0;
  double stock = 0;
  if (numbers.isNotEmpty) {
    price = double.parse(numbers[0].group(0)!.replaceAll(',', '.'));
  }
  if (numbers.length > 1) {
    stock = double.parse(numbers[1].group(0)!.replaceAll(',', '.'));
  }

  return ParsedProduct(
    name: _capitalize(namePart),
    priceCents: (price * 100).round(),
    stock: stock.round(),
  );
}

ParsedCustomer? parseCustomerUtterance(String transcript) {
  final text = normalizeSpanishNumbers(transcript.trim());
  if (text.isEmpty) return null;

  // Un bloque de 7+ dígitos (con espacios o guiones) se toma como teléfono.
  final phoneMatch = RegExp(r'\d[\d\s\-]{5,}\d').firstMatch(text);
  String? phone;
  var namePart = text;
  if (phoneMatch != null) {
    phone = phoneMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
    namePart = text.substring(0, phoneMatch.start);
  }
  namePart = namePart
      .replaceAll(
        RegExp(r'\b(tel[eé]fono|celular|n[uú]mero)\s*$', caseSensitive: false),
        '',
      )
      .trim();
  if (namePart.isEmpty) return null;

  return ParsedCustomer(name: _capitalize(namePart), phone: phone);
}
