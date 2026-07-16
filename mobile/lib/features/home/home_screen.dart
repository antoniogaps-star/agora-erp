import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Pantalla principal tras iniciar sesión. Muestra el perfil (/users/me) y
/// permite cerrar sesión. Los módulos de negocio (inventario, ventas) llegan
/// en etapas posteriores.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ágora ERP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: repo.me(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }
          final me = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Correo: ${me['email']}'),
                Text('Rol: ${me['role']}'),
                Text('Empresa (tenant): ${me['tenant_id']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
