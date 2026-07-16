import 'package:dio/dio.dart';

import '../../core/secure_store.dart';

/// Acceso a los endpoints de autenticación y perfil.
class AuthRepository {
  AuthRepository(this._dio, this._store);

  final Dio _dio;
  final SecureStore _store;

  Future<void> login({
    required String companySlug,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'company_slug': companySlug,
      'email': email,
      'password': password,
    });
    await _saveTokens(response.data);
  }

  Future<void> register({
    required String companyName,
    required String companySlug,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'company_name': companyName,
      'company_slug': companySlug,
      'email': email,
      'password': password,
    });
    await _saveTokens(response.data);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get('/users/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> logout() => _store.clear();

  Future<bool> hasSession() async => (await _store.refreshToken) != null;

  Future<void> _saveTokens(dynamic data) async {
    await _store.saveTokens(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
  }
}
