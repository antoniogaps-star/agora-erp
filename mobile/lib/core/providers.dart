import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/sync/sync_service.dart';
import '../features/auth/auth_repository.dart';
import '../features/inventory/inventory_repository.dart';
import 'api_client.dart';
import 'secure_store.dart';

/// Inyección de dependencias con Riverpod.
final secureStoreProvider = Provider<SecureStore>((_) => const SecureStore());

final dioProvider = Provider<Dio>(
  (ref) => createDio(ref.watch(secureStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(secureStoreProvider)),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(databaseProvider), ref.watch(dioProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(
    ref.watch(databaseProvider),
    ref.watch(authRepositoryProvider),
  ),
);

/// Productos locales con su stock (suma de movimientos). Se invalida tras cada acción.
final productsProvider = FutureProvider.autoDispose<List<(Product, int)>>(
  (ref) => ref.watch(inventoryRepositoryProvider).productsWithStock(),
);

/// Estado de sesión: true si hay un refresh token guardado.
class AuthController extends AsyncNotifier<bool> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<bool> build() => _repo.hasSession();

  Future<void> login({
    required String companySlug,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.login(companySlug: companySlug, email: email, password: password);
      return true;
    });
  }

  Future<void> register({
    required String companyName,
    required String companySlug,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.register(
        companyName: companyName,
        companySlug: companySlug,
        email: email,
        password: password,
      );
      return true;
    });
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(false);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, bool>(AuthController.new);
