import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/slug.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _company.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // El usuario escribe el NOMBRE de su empresa; la app lo traduce al
    // identificador interno igual que en el registro (ver slugify).
    await ref.read(authControllerProvider.notifier).login(
          companySlug: slugify(_company.text),
          email: _email.text.trim().toLowerCase(),
          password: _password.text,
        );
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo entrar. Revisa tu identificador, correo y contraseña. '
            'Si es la primera vez, primero crea tu cuenta.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Ágora ERP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ágora ERP',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F6DF6),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dictas. Vendes. Ganas.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                hintText: 'El nombre de tu negocio',
              ),
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(isLoading ? 'Entrando…' : 'Entrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
              child: const Text('¿No tienes cuenta? Crear empresa'),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).enterDemo(),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Ver demostración'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba gratis · 1 semana',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
