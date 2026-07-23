import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'reports_repository.dart';

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

String _hora(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
}

/// Pestaña de Reportes: ganancias de hoy/semana, ventas del día, más vendidos y
/// stock bajo. Todo se calcula de la base local, así que funciona sin internet.
class ReportsTab extends ConsumerWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reportsProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar el reporte: $e'),
        ))]),
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _MoneyCard(
                  title: 'Ventas de hoy',
                  amount: _money(r.todayCents),
                  subtitle: '${r.todayCount} ${r.todayCount == 1 ? 'venta' : 'ventas'}',
                  color: const Color(0xFF15803D),
                )),
                const SizedBox(width: 12),
                Expanded(child: _MoneyCard(
                  title: 'Esta semana',
                  amount: _money(r.weekCents),
                  subtitle: '${r.weekCount} ${r.weekCount == 1 ? 'venta' : 'ventas'}',
                  color: const Color(0xFF2F6DF6),
                )),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Ventas de hoy',
              child: r.todaySales.isEmpty
                  ? const _Empty('Aún no hay ventas hoy.')
                  : Column(children: [
                      for (final s in r.todaySales)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.productName),
                          subtitle: Text('${s.quantity} pzas · ${_hora(s.at)}'),
                          trailing: Text(_money(s.totalCents),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ]),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Más vendidos',
              child: r.top.isEmpty
                  ? const _Empty('Sin ventas todavía.')
                  : Column(children: [
                      for (final t in r.top)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B)),
                          title: Text(t.name),
                          subtitle: Text('${t.units} pzas vendidas'),
                          trailing: Text(_money(t.totalCents),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ]),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Stock bajo (menos de $kLowStockThreshold)',
              child: r.lowStock.isEmpty
                  ? const _Empty('Todo con buen inventario. 👌')
                  : Column(children: [
                      for (final l in r.lowStock)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.warning_amber,
                              color: l.stock == 0 ? const Color(0xFFB91C1C) : const Color(0xFFF59E0B)),
                          title: Text(l.name),
                          trailing: Text('${l.stock} pzas',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: l.stock == 0 ? const Color(0xFFB91C1C) : null)),
                        ),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.color,
  });
  final String title;
  final String amount;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(),
        child,
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );
}
