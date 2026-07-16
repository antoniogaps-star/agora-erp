import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén seguro de tokens y de la llave de cifrado de la base local
/// (Keychain/Keystore del sistema). Nada se guarda en texto plano. Ver docs/09_Seguridad.md.
class SecureStore {
  const SecureStore();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _dbKey = 'db_encryption_key';

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

  /// Llave de 256 bits para cifrar la base local con SQLCipher. Se genera una vez
  /// (aleatoria) y se conserva en el almacenamiento seguro del sistema. No se borra en
  /// logout: los datos locales siguen cifrados entre sesiones.
  Future<String> databaseKey() async {
    var key = await _storage.read(key: _dbKey);
    if (key == null) {
      final rng = Random.secure();
      key = base64UrlEncode(List<int>.generate(32, (_) => rng.nextInt(256)));
      await _storage.write(key: _dbKey, value: key);
    }
    return key;
  }
}
