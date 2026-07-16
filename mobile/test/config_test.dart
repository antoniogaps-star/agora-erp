import 'package:agora_erp_mobile/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('apiBaseUrl apunta al prefijo versionado de la API', () {
    expect(AppConfig.apiBaseUrl.endsWith('/api/v1'), isTrue);
  });
}
