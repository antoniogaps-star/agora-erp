import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/quick_login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: AgoraApp()));
}

class AgoraApp extends StatelessWidget {
  const AgoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ágora ERP',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2F6DF6), useMaterial3: true),
      home: const _AuthGate(),
    );
  }
}

/// Decide qué pantalla mostrar al abrir la app:
/// - Con sesión (real o demo): la app (Home).
/// - Sin sesión y con una cuenta ya guardada en el equipo: "Entrar" (verde),
///   solo pide la contraseña.
/// - Sin sesión y sin cuenta guardada (primera vez): "Crear empresa" (naranja).
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  static const _loadingScreen =
      Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => _loadingScreen,
      error: (_, __) => _firstScreen(ref),
      data: (session) =>
          session == SessionKind.none ? _firstScreen(ref) : const HomeScreen(),
    );
  }

  /// Elige entre "Entrar" (cuenta guardada) y "Crear empresa" (primera vez).
  Widget _firstScreen(WidgetRef ref) {
    final saved = ref.watch(savedAccountProvider);
    return saved.when(
      loading: () => _loadingScreen,
      error: (_, __) => const RegisterScreen(),
      data: (account) => account == null
          ? const RegisterScreen()
          : QuickLoginScreen(company: account.$1, email: account.$2),
    );
  }
}
