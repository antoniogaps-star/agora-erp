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
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Inventario' : 'Clientes'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), tooltip: 'Sincronizar', onPressed: _sync),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [InventoryTab(), CustomersTab()],
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
