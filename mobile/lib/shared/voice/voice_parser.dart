/// Intérpretes de dictado: convierten una frase reconocida en datos estructurados.
///
/// INVENTARIO (solo producto + piezas, en sus presentaciones de llegada):
///   "coca cola 5 cajas de 24"   → Coca cola, 120 piezas
///   "cerveza 3 six"             → Cerveza, 18 piezas   (six = 6)
///   "galletas 2 docenas"        → Galletas, 24 piezas  (docena = 12)
///   "agua 50 piezas"            → Agua, 50 piezas
///   "cigarros 10 paquetes de 20"→ Cigarros, 200 piezas
///   "jugo"                      → Jugo, 0 piezas (solo registra el producto)
/// El precio NO se captura aquí; pertenece a la función de venta.
///
/// CLIENTE:
///   "Juan Pérez teléfono 555 123 4567" → Juan Pérez, 5551234567
library;

import 'spanish_numbers.dart';

class ParsedProduct {
  const ParsedProduct({
    required this.name,
    required this.pieces,
    this.packSizeMissing = false,
    this.presentation,
  });

  final String name;
  final int pieces;

  /// true si dictó "caja/paquete" sin decir "de N" — la UI debe pedir el tamaño.
  final bool packSizeMissing;
  final String? presentation;
}

class ParsedCustomer {
  const ParsedCustomer({required this.name, this.phone});

  final String name;
  final String? phone;
}

// Presentaciones de tamaño FIJO.
const _fixedPacks = {
  'pieza': 1, 'piezas': 1, 'unidad': 1, 'unidades': 1, 'pza': 1, 'pzas': 1,
  'par': 2, 'pares': 2, 'six': 6, 'sixpack': 6, 'docena': 12, 'docenas': 12,
};

// Presentaciones cuyo tamaño hay que decir ("de N").
const _variablePacks = {'caja', 'cajas', 'paquete', 'paquetes', 'bulto', 'bultos'};

final _isDigits = RegExp(r'^\d+$');

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

int? _asInt(String token) => _isDigits.hasMatch(token) ? int.parse(token) : null;

ParsedProduct? parseProductUtterance(String transcript) {
  // "cinco cajas de veinticuatro" → "5 cajas de 24"; "media docena" → "6 piezas".
  var work = normalizeSpanishNumbers(transcript.trim());
  work = work.replaceAll(RegExp('media docena', caseSensitive: false), '6 piezas');
  if (work.isEmpty) return null;

  final orig = work.split(RegExp(r'\s+'));
  final lower = orig.map((w) => w.toLowerCase()).toList();

  int? presIdx;
  for (var i = 0; i < lower.length; i++) {
    if (_fixedPacks.containsKey(lower[i]) || _variablePacks.contains(lower[i])) {
      presIdx = i;
      break;
    }
  }

  int pieces;
  int nameBoundary;

  if (presIdx != null) {
    final pres = lower[presIdx];
    // Cantidad = número inmediatamente antes de la presentación (o 1).
    final qtyBefore = presIdx > 0 ? _asInt(lower[presIdx - 1]) : null;
    final qty = qtyBefore ?? 1;
    nameBoundary = qtyBefore != null ? presIdx - 1 : presIdx;

    int multiplier;
    if (_fixedPacks.containsKey(pres)) {
      multiplier = _fixedPacks[pres]!;
    } else {
      // Variable: buscar "de <número>" justo después.
      final hasSize = presIdx + 2 < lower.length &&
          lower[presIdx + 1] == 'de' &&
          _asInt(lower[presIdx + 2]) != null;
      if (!hasSize) {
        final name = _capitalize(orig.sublist(0, nameBoundary).join(' ').trim());
        if (name.isEmpty) return null;
        return ParsedProduct(name: name, pieces: 0, packSizeMissing: true, presentation: pres);
      }
      multiplier = _asInt(lower[presIdx + 2])!;
    }
    pieces = qty * multiplier;
  } else {
    // Sin presentación: un número suelto = piezas.
    final numIdx = lower.indexWhere((t) => _asInt(t) != null);
    if (numIdx == -1) {
      pieces = 0;
      nameBoundary = orig.length;
    } else {
      pieces = _asInt(lower[numIdx])!;
      nameBoundary = numIdx;
    }
  }

  final name = _capitalize(orig.sublist(0, nameBoundary).join(' ').trim());
  if (name.isEmpty) return null;
  return ParsedProduct(name: name, pieces: pieces);
}

ParsedCustomer? parseCustomerUtterance(String transcript) {
  final text = normalizeSpanishNumbers(transcript.trim());
  if (text.isEmpty) return null;

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
