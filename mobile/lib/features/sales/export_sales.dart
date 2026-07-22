import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/database.dart';

/// Exporta las ventas locales a un archivo CSV (se abre en Excel) y lo comparte.
Future<void> exportSalesCsv(AppDatabase db) async {
  final sales = await (db.select(db.sales)..where((s) => s.isDeleted.equals(false))).get();
  final products = await db.activeProducts();
  final nameById = {for (final p in products) p.id: p.name};

  final b = StringBuffer();
  b.writeln('Fecha,Producto,Cantidad,Precio unitario,Total');
  for (final s in sales) {
    final name = (nameById[s.productId] ?? s.productId).replaceAll('"', '""');
    final fecha = s.updatedAt.toLocal().toString().split('.').first;
    b.writeln('"$fecha","$name",${s.quantity},'
        '${(s.unitPriceCents / 100).toStringAsFixed(2)},'
        '${(s.totalCents / 100).toStringAsFixed(2)}');
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/ventas.csv');
  await file.writeAsString('﻿$b'); // BOM para acentos en Excel
  await Share.shareXFiles([XFile(file.path)], subject: 'Ventas · Ágora ERP');
}
