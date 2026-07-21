import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../customers/customers_tab.dart';
import '../inventory/inventory_tab.dart';

/// Shell principal tras iniciar sesión: pestañas de Inventario y Clientes,
/// con sincronización y logout en la barra superior.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    if (ref.read(authControllerProvider).valueOrNull == SessionKind.demo) {
      messenger.showSnackBar(
        const SnackBar(content: Text('La sincronización no aplica en la demostración')),
      );
      return;
    }
    try {
      final sync = ref.read(syncServiceProvider);
      await sync.push();
      await sync.pull();
      ref.invalidate(productsProvider);
      ref.invalidate(customersProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Sincronización completa')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sin conexión: se sincronizará luego')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = ref.watch(authControllerProvider).valueOrNull == SessionKind.demo;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Inventario' : 'Clientes'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), tooltip: 'Sincronizar', onPressed: _sync),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: isDemo ? 'Salir de la demostración' : 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isDemo) const _DemoBanner(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [InventoryTab(), CustomersTab()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'),
        ],
      ),
    );
  }
}

/// Franja superior visible durante la demostración: comunica la oferta al cliente
/// y ofrece reiniciar los datos para volver a enseñarla desde cero.
class _DemoBanner extends ConsumerWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: const Color(0xFF15803D),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prueba gratis · 1 semana',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Estás viendo una demostración con datos de ejemplo',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).resetDemo(),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    );
  }
}
