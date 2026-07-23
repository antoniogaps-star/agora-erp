import 'package:flutter/material.dart';

/// Pantalla de bienvenida (splash) de Ágora ERP: el logo (A + micrófono) sobre el
/// azul marino de la marca y, debajo, la leyenda "Dictas, vendes, ganas" en grande.
/// Se muestra un instante al abrir la app y luego cede el paso al AuthGate.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Mismo azul marino del logo (#000214). También es el fondo nativo de arranque
  /// (ver android/.../colors.xml → splash_bg), así no hay destello blanco.
  static const Color background = Color(0xFF000214);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo sin la leyenda (la ponemos aparte, más grande y nítida).
            Image.asset(
              'assets/branding/logo_mark.png',
              width: width * 0.62,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const _Tagline(),
          ],
        ),
      ),
    );
  }
}

/// "Dictas, vendes, ganas" con los colores de la marca (azul, blanco, verde),
/// un poco más grande que en la imagen original.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        children: [
          TextSpan(text: 'Dictas', style: TextStyle(color: Color(0xFF3AA0FF))),
          TextSpan(text: ', ', style: TextStyle(color: Colors.white70)),
          TextSpan(text: 'vendes', style: TextStyle(color: Colors.white)),
          TextSpan(text: ', ', style: TextStyle(color: Colors.white70)),
          TextSpan(text: 'GANAS', style: TextStyle(color: Color(0xFF22C55E))),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
