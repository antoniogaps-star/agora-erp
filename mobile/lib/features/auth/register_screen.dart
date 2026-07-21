import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Fuerza minúsculas y solo caracteres válidos de slug (a-z, 0-9, guion) mientras
/// se escribe, para que el campo coincida con lo que exige el backend.
class _SlugFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// Registro de una empresa nueva + su usuario dueño. Al terminar, la sesión queda
/// iniciada (real) y el AuthGate muestra la app.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _companyName = TextEditingController();
  final _slug = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _companyName.dispose();
    _slug.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final name = _companyName.text.trim();
    final slug = _slug.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    // Validación amigable antes de llamar al servidor.
    if (name.length < 2) return _snack('Escribe el nombre de tu empresa');
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      return _snack('El identificador debe ser en minúsculas, sin espacios (ej: mi-tienda)');
    }
    if (!email.contains('@') || !email.contains('.')) {
      return _snack('Escribe un correo válido');
    }
    if (password.length < 8) return _snack('La contraseña debe tener al menos 8 caracteres');

    await ref.read(authControllerProvider.notifier).register(
          companyName: name,
          companySlug: slug,
          email: email,
          password: password,
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      _snack('No se pudo crear la cuenta. Puede que ese identificador o correo ya existan, '
          'o que el servidor tarde en despertar. Intenta de nuevo.');
    } else {
      // Registro exitoso: la sesión ya es real; cerramos esta pantalla y el
      // AuthGate mostrará la app por debajo.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Registra tu empresa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Se creará tu empresa y tu usuario dueño.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la empresa',
                hintText: 'Ej: Abarrotes Doña Rosa',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _slug,
              inputFormatters: [_SlugFormatter()],
              keyboardType: TextInputType.visiblePassword, // evita autocorrección
              decoration: const InputDecoration(
                labelText: 'Identificador (para entrar)',
                hintText: 'ej: mi-tienda',
                helperText: 'Solo minúsculas, números y guiones. Lo usarás para iniciar sesión.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                helperText: 'Mínimo 8 caracteres.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(isLoading ? 'Creando…' : 'Crear cuenta'),
            ),
            const SizedBox(height: 12),
            const Text(
              'La primera vez puede tardar hasta ~1 minuto mientras el servidor despierta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
