import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén seguro de tokens (Keychain/Keystore del sistema).
/// Los JWT nunca se guardan en texto plano. Ver docs/09_Seguridad.md.
class SecureStore {
  const SecureStore();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
