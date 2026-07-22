import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ticket.dart';

/// Muestra el ticket de una venta y permite enviarlo por WhatsApp o compartirlo.
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.ticket});
  final SaleTicket ticket;

  Future<void> _whatsapp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(ticket.text())}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _compartir() async {
    await Share.share(ticket.text(), subject: 'Ticket de venta');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket de venta')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  ticket.text().replaceAll('*', '').replaceAll('🧾 ', ''),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                      onPressed: () => _whatsapp(context),
                      icon: const Icon(Icons.chat),
                      label: const Text('Enviar por WhatsApp'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _compartir,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir / Guardar'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
