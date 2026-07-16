/// Convierte números dictados en español ("cincuenta", "ciento veinte", "dos mil")
/// a dígitos, porque el reconocedor de voz a veces entrega las cifras como palabras.
library;

const _units = {
  'cero': 0, 'un': 1, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
  'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
  'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
  'dieciseis': 16, 'dieciséis': 16, 'diecisiete': 17, 'dieciocho': 18,
  'diecinueve': 19, 'veinte': 20, 'veintiuno': 21, 'veintiún': 21,
  'veintiuna': 21, 'veintidos': 22, 'veintidós': 22, 'veintitres': 23,
  'veintitrés': 23, 'veinticuatro': 24, 'veinticinco': 25, 'veintiseis': 26,
  'veintiséis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
};

const _tens = {
  'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60,
  'setenta': 70, 'ochenta': 80, 'noventa': 90,
};

const _hundreds = {
  'cien': 100, 'ciento': 100, 'doscientos': 200, 'doscientas': 200,
  'trescientos': 300, 'trescientas': 300, 'cuatrocientos': 400,
  'cuatrocientas': 400, 'quinientos': 500, 'quinientas': 500,
  'seiscientos': 600, 'seiscientas': 600, 'setecientos': 700,
  'setecientas': 700, 'ochocientos': 800, 'ochocientas': 800,
  'novecientos': 900, 'novecientas': 900,
};

/// Palabras que NO son números pero pueden aparecer entre ellos ("y") o alrededor.
const _skip = {'y', 'con'};

/// Recorre las palabras del texto y sustituye las secuencias numéricas en español por
/// su valor en dígitos, dejando intacto el resto. Devuelve el texto normalizado.
String normalizeSpanishNumbers(String text) {
  final original = text.split(RegExp(r'\s+'));
  // Se compara en minúsculas, pero las palabras NO numéricas conservan su forma
  // original (para no arruinar nombres propios como "Juan Pérez").
  final lower = original.map((w) => w.toLowerCase()).toList();
  final output = <String>[];

  int i = 0;
  while (i < original.length) {
    final (value, consumed) = _consumeNumber(lower, i);
    if (consumed > 0) {
      output.add(value.toString());
      i += consumed;
    } else {
      output.add(original[i]);
      i++;
    }
  }
  return output.join(' ');
}

/// Intenta leer un número desde la posición [start]. Devuelve (valor, palabras usadas).
/// (0 palabras usadas = no había número aquí).
(int, int) _consumeNumber(List<String> words, int start) {
  int total = 0;
  int current = 0;
  int consumed = 0;
  bool sawAny = false;

  int i = start;
  while (i < words.length) {
    final w = words[i];

    if (w == 'mil') {
      current = current == 0 ? 1 : current;
      total += current * 1000;
      current = 0;
      sawAny = true;
      consumed = i - start + 1;
      i++;
      continue;
    }
    if (_hundreds.containsKey(w)) {
      current += _hundreds[w]!;
      sawAny = true;
      consumed = i - start + 1;
      i++;
      continue;
    }
    if (_tens.containsKey(w)) {
      current += _tens[w]!;
      sawAny = true;
      consumed = i - start + 1;
      i++;
      continue;
    }
    if (_units.containsKey(w)) {
      current += _units[w]!;
      sawAny = true;
      consumed = i - start + 1;
      i++;
      continue;
    }
    // "y" solo cuenta como parte del número si ya venimos leyendo uno (treinta y cinco).
    if (_skip.contains(w) && sawAny) {
      i++;
      continue;
    }
    break;
  }

  if (!sawAny) return (0, 0);
  return (total + current, consumed);
}
