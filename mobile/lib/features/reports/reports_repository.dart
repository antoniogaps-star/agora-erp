import '../../data/local/database.dart';

/// Una venta del día para la lista de reportes.
class SaleLine {
  const SaleLine({
    required this.productName,
    required this.quantity,
    required this.totalCents,
    required this.at,
  });
  final String productName;
  final int quantity;
  final int totalCents;
  final DateTime at;
}

/// Un producto en el ranking de más vendidos.
class TopProduct {
  const TopProduct({required this.name, required this.units, required this.totalCents});
  final String name;
  final int units;
  final int totalCents;
}

/// Un producto con existencias bajas.
class LowStockItem {
  const LowStockItem({required this.name, required this.stock});
  final String name;
  final int stock;
}

/// Números y listas para la pestaña de Reportes.
class ReportData {
  const ReportData({
    required this.todayCents,
    required this.todayCount,
    required this.weekCents,
    required this.weekCount,
    required this.todaySales,
    required this.top,
    required this.lowStock,
  });

  final int todayCents;
  final int todayCount;
  final int weekCents;
  final int weekCount;
  final List<SaleLine> todaySales;
  final List<TopProduct> top;
  final List<LowStockItem> lowStock;
}

/// Umbral por debajo del cual una existencia se considera "baja".
const int kLowStockThreshold = 5;

/// Arma los reportes a partir de los datos LOCALES (funciona sin internet).
class ReportsRepository {
  ReportsRepository(this._db);
  final AppDatabase _db;

  Future<ReportData> load() async {
    final sales = await _db.activeSales(); // ya vienen más recientes primero
    final products = await _db.activeProducts();
    final stock = await _db.stockByProduct();
    final names = {for (final p in products) p.id: p.name};

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    // Semana que empieza el lunes (weekday: 1=lunes … 7=domingo).
    final startWeek = startToday.subtract(Duration(days: now.weekday - 1));

    var todayCents = 0, todayCount = 0, weekCents = 0, weekCount = 0;
    final today = <SaleLine>[];
    final units = <String, int>{};
    final cents = <String, int>{};

    for (final s in sales) {
      if (!s.updatedAt.isBefore(startWeek)) {
        weekCents += s.totalCents;
        weekCount++;
      }
      if (!s.updatedAt.isBefore(startToday)) {
        todayCents += s.totalCents;
        todayCount++;
        today.add(SaleLine(
          productName: names[s.productId] ?? 'Producto',
          quantity: s.quantity,
          totalCents: s.totalCents,
          at: s.updatedAt,
        ));
      }
      units[s.productId] = (units[s.productId] ?? 0) + s.quantity;
      cents[s.productId] = (cents[s.productId] ?? 0) + s.totalCents;
    }

    final top = units.entries
        .map((e) => TopProduct(
              name: names[e.key] ?? 'Producto',
              units: e.value,
              totalCents: cents[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.units.compareTo(a.units));

    final low = <LowStockItem>[];
    for (final p in products) {
      final st = stock[p.id] ?? 0;
      if (st < kLowStockThreshold) low.add(LowStockItem(name: p.name, stock: st));
    }
    low.sort((a, b) => a.stock.compareTo(b.stock));

    return ReportData(
      todayCents: todayCents,
      todayCount: todayCount,
      weekCents: weekCents,
      weekCount: weekCount,
      todaySales: today,
      top: top.take(5).toList(),
      lowStock: low,
    );
  }
}
