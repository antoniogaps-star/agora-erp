import 'package:dio/dio.dart';

import 'config.dart';
import 'secure_store.dart';

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
        final refresh = await store.refreshToken;

        if (isUnauthorized && !alreadyRetried && refresh != null) {
          try {
            final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
            final response = await refreshDio.post(
              '/auth/refresh',
              data: {'refresh_token': refresh},
            );
            final access = response.data['access_token'] as String;
            await store.saveTokens(access, response.data['refresh_token'] as String);

            final retryOptions = error.requestOptions
              ..extra['retried'] = true
              ..headers['Authorization'] = 'Bearer $access';
            final cloned = await refreshDio.fetch(retryOptions);
            return handler.resolve(cloned);
          } catch (_) {
            await store.clear();
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
