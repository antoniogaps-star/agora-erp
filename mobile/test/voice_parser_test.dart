import 'package:agora_erp_mobile/shared/voice/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseProductUtterance', () {
    test('nombre + precio + stock', () {
      final p = parseProductUtterance('café 50 pesos 20 piezas')!;
      expect(p.name, 'Café');
      expect(p.priceCents, 5000);
      expect(p.stock, 20);
    });

    test('con palabras "precio" y "stock" y decimales', () {
      final p = parseProductUtterance('té verde precio 80.50 stock 30')!;
      expect(p.name, 'Té verde');
      expect(p.priceCents, 8050);
      expect(p.stock, 30);
    });

    test('decimal con coma (dictado en español)', () {
      final p = parseProductUtterance('galletas 25,50 12')!;
      expect(p.name, 'Galletas');
      expect(p.priceCents, 2550);
      expect(p.stock, 12);
    });

    test('solo nombre', () {
      final p = parseProductUtterance('galletas')!;
      expect(p.name, 'Galletas');
      expect(p.priceCents, 0);
      expect(p.stock, 0);
    });

    test('vacío o solo números → null', () {
      expect(parseProductUtterance(''), isNull);
      expect(parseProductUtterance('50 20'), isNull);
    });

    test('números dictados en PALABRAS (el caso real de Toño)', () {
      final p = parseProductUtterance('café cincuenta pesos veinte piezas')!;
      expect(p.name, 'Café');
      expect(p.priceCents, 5000);
      expect(p.stock, 20);
    });

    test('números compuestos en palabras', () {
      final p = parseProductUtterance('galletas ciento veinte pesos treinta y cinco piezas')!;
      expect(p.name, 'Galletas');
      expect(p.priceCents, 12000);
      expect(p.stock, 35);
    });

    test('mezcla palabra + dígito', () {
      final p = parseProductUtterance('té verde ochenta 30')!;
      expect(p.name, 'Té verde');
      expect(p.priceCents, 8000);
      expect(p.stock, 30);
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
