import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/login_screen.dart';
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

/// Muestra Home si hay sesión, Login si no.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (isAuthenticated) => isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
