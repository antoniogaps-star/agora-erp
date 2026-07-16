import 'package:agora_erp_mobile/shared/voice/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseProductUtterance', () {
    test('cajas con tamaño → multiplica a piezas', () {
      final p = parseProductUtterance('coca cola 5 cajas de 24')!;
      expect(p.name, 'Coca cola');
      expect(p.pieces, 120);
    });

    test('six (tamaño fijo 6)', () {
      final p = parseProductUtterance('cerveza 3 six')!;
      expect(p.name, 'Cerveza');
      expect(p.pieces, 18);
    });

    test('docenas (tamaño fijo 12)', () {
      final p = parseProductUtterance('galletas 2 docenas')!;
      expect(p.name, 'Galletas');
      expect(p.pieces, 24);
    });

    test('piezas directas', () {
      final p = parseProductUtterance('agua 50 piezas')!;
      expect(p.name, 'Agua');
      expect(p.pieces, 50);
    });

    test('paquetes con tamaño', () {
      final p = parseProductUtterance('cigarros 10 paquetes de 20')!;
      expect(p.name, 'Cigarros');
      expect(p.pieces, 200);
    });

    test('números dictados en palabras', () {
      final p = parseProductUtterance('coca cola cinco cajas de veinticuatro')!;
      expect(p.name, 'Coca cola');
      expect(p.pieces, 120);
    });

    test('número suelto = piezas', () {
      final p = parseProductUtterance('sabritas 40')!;
      expect(p.name, 'Sabritas');
      expect(p.pieces, 40);
    });

    test('solo nombre → 0 piezas', () {
      final p = parseProductUtterance('jugo')!;
      expect(p.name, 'Jugo');
      expect(p.pieces, 0);
    });

    test('media docena', () {
      final p = parseProductUtterance('pan media docena')!;
      expect(p.name, 'Pan');
      expect(p.pieces, 6);
    });

    test('presentación sin six/docena → un solo empaque', () {
      final p = parseProductUtterance('cerveza six')!;
      expect(p.name, 'Cerveza');
      expect(p.pieces, 6);
    });

    test('caja sin "de N" → pide el tamaño', () {
      final p = parseProductUtterance('coca cola 5 cajas')!;
      expect(p.name, 'Coca cola');
      expect(p.packSizeMissing, isTrue);
      expect(p.presentation, 'cajas');
    });

    test('vacío → null', () {
      expect(parseProductUtterance(''), isNull);
    });
  });

  group('parseCustomerUtterance', () {
    test('nombre + teléfono', () {
      final c = parseCustomerUtterance('Juan Pérez teléfono 555 123 4567')!;
      expect(c.name, 'Juan Pérez');
      expect(c.phone, '5551234567');
    });

    test('solo nombre', () {
      final c = parseCustomerUtterance('maría lópez')!;
      expect(c.name, 'María lópez');
      expect(c.phone, isNull);
    });

    test('vacío → null', () {
      expect(parseCustomerUtterance(''), isNull);
    });
  });
}
