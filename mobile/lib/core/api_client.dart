import 'package:dio/dio.dart';

import 'config.dart';
import 'secure_store.dart';

// Un único refresco en vuelo compartido por todas las peticiones. Con rotación de
// tokens, varios 401 concurrentes que refrescaran en paralelo revocarían el token en el
// primero y fallarían en el segundo, cerrando la sesión.
Future<String?>? _refreshInFlight;

Future<String?> _refreshAccessToken(SecureStore store, String refresh) async {
  try {
    final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).post(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );
    final access = response.data['access_token'] as String;
    await store.saveTokens(access, response.data['refresh_token'] as String);
    return access;
  } finally {
    _refreshInFlight = null;
  }
}

/// Crea un Dio con inyección del bearer y refresco automático ante 401.
Dio createDio(SecureStore store) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !alreadyRetried) {
          final refresh = await store.refreshToken;
          if (refresh != null) {
            try {
              _refreshInFlight ??= _refreshAccessToken(store, refresh);
              final access = await _refreshInFlight;
              if (access != null) {
                final retryOptions = error.requestOptions
                  ..extra['retried'] = true
                  ..headers['Authorization'] = 'Bearer $access';
                final cloned = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
                    .fetch(retryOptions);
                return handler.resolve(cloned);
              }
            } catch (_) {
              await store.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
