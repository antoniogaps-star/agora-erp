import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/sync/sync_service.dart';
import '../features/auth/auth_repository.dart';
import '../features/customers/customers_repository.dart';
import '../features/inventory/inventory_repository.dart';
import 'api_client.dart';
import 'demo.dart';
import 'secure_store.dart';

/// Tipo de sesión activa: ninguna (mostrar login), real (empresa de verdad) o
/// demostración (datos fijos locales, sin servidor).
enum SessionKind { none, real, demo }

/// Inyección de dependencias con Riverpod.
final secureStoreProvider = Provider<SecureStore>((_) => const SecureStore());

final dioProvider = Provider<Dio>(
  (ref) => createDio(ref.watch(secureStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(secureStoreProvider)),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.encrypted(ref.watch(secureStoreProvider));
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(databaseProvider), ref.watch(dioProvider)),
);

final demoSeederProvider = Provider<DemoSeeder>(
  (ref) => DemoSeeder(ref.watch(databaseProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(
    ref.watch(databaseProvider),
    ref.watch(authRepositoryProvider).currentTenantId,
    ref.watch(dioProvider),
  ),
);

/// Productos locales con su stock (suma de movimientos). Se invalida tras cada acción.
final productsProvider = FutureProvider.autoDispose<List<(Product, int)>>(
  (ref) => ref.watch(inventoryRepositoryProvider).productsWithStock(),
);

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepository(
    ref.watch(databaseProvider),
    ref.watch(authRepositoryProvider).currentTenantId,
  ),
);

/// Clientes locales. Se invalida tras cada alta o sincronización.
final customersProvider = FutureProvider.autoDispose<List<Customer>>(
  (ref) => ref.watch(customersRepositoryProvider).listCustomers(),
);

/// Cuenta recordada en este equipo (empresa + correo con los que se entró antes).
/// Si existe, al abrir la app se muestra la pantalla verde de "Entrar" (solo pide
/// contraseña); si no, se muestra directamente la de crear empresa.
final savedAccountProvider = FutureProvider<(String company, String email)?>((ref) async {
  final store = ref.watch(secureStoreProvider);
  final company = await store.lastCompany;
  final email = await store.lastEmail;
  if (company == null || email == null || company.isEmpty || email.isEmpty) return null;
  return (company, email);
});

/// Estado de sesión: real (token guardado), demo (datos fijos locales) o ninguna.
class AuthController extends AsyncNotifier<SessionKind> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<SessionKind> build() async {
    if (await _repo.isDemo) return SessionKind.demo;
    return (await _repo.hasSession()) ? SessionKind.real : SessionKind.none;
  }

  /// Inicia sesión. NO usa AsyncLoading para no reemplazar la pantalla de login
  /// mientras se procesa (si se reemplazara, el error nunca se alcanzaría a mostrar).
  /// Lanza la excepción si falla; la pantalla la atrapa y muestra el mensaje.
  Future<void> login({
    required String companySlug,
    required String email,
    required String password,
  }) async {
    await _repo.login(companySlug: companySlug, email: email, password: password);
    state = const AsyncData(SessionKind.real);
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
      return SessionKind.real;
    });
  }

  /// Entra al modo demostración: marca la sesión local y carga datos fijos frescos.
  Future<void> enterDemo() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(secureStoreProvider).setDemo(true);
      await ref.read(demoSeederProvider).reset();
      return SessionKind.demo;
    });
  }

  /// Reinicia los datos de demo a su estado original (para volver a enseñarla limpia).
  Future<void> resetDemo() async {
    await ref.read(demoSeederProvider).reset();
    ref.invalidate(productsProvider);
    ref.invalidate(customersProvider);
  }

  Future<void> logout() async {
    if (state.valueOrNull == SessionKind.demo) {
      await ref.read(demoSeederProvider).wipe();
      await ref.read(secureStoreProvider).setDemo(false);
    } else {
      await _repo.logout();
    }
    state = const AsyncData(SessionKind.none);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, SessionKind>(AuthController.new);
