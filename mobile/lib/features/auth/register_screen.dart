import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/slug.dart';
import 'auth_errors.dart';

/// Registro de una empresa nueva + su usuario dueño. El usuario solo escribe el
/// nombre del negocio, su correo y una contraseña; el identificador interno se
/// genera solo a partir del nombre (ver [slugify]).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _companyName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _companyName.dispose();
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
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    final companySlug = slugify(name);

    // Validación amigable antes de llamar al servidor.
    if (name.length < 2 || companySlug.length < 2) {
      return _snack('Escribe el nombre de tu empresa (con letras)');
    }
    if (!email.contains('@') || !email.contains('.')) {
      return _snack('Escribe un correo válido');
    }
    if (password.length < 8) return _snack('La contraseña debe tener al menos 8 caracteres');

    final store = ref.read(secureStoreProvider);
    await ref.read(authControllerProvider.notifier).register(
          companyName: name,
          companySlug: companySlug,
          email: email,
          password: password,
        );

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      if (mounted) _snack(authErrorMessage(state.error, isRegister: true));
    } else {
      // Guarda los datos para prellenar el próximo login (así no habrá typos).
      await store.saveLastLogin(name, email);
      // A partir de ahora, al abrir la app se mostrará la pantalla verde "Entrar".
      ref.invalidate(savedAccountProvider);
      // Registro exitoso: la sesión ya es real; cerramos esta pantalla y el
      // AuthGate mostrará la app por debajo.
      if (mounted) Navigator.of(context).pop();
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
            // Recuadro naranja superior (primera vez que se abre la app).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Crear empresa',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Registra tu empresa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Con estos datos entrarás después.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la empresa',
                hintText: 'Ej: Modelorama Toño',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                helperText: 'Mínimo 8 caracteres. Toca el ojo para verla y anótala.',
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  tooltip: _showPassword ? 'Ocultar' : 'Ver contraseña',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
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
