import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Botón de dictado CONTINUO: al activarlo escucha, entrega cada frase terminada a
/// [onUtterance] y vuelve a escuchar, hasta que el usuario lo detiene. Pensado para
/// capturar inventario/clientes de corrido ("café 50 pesos 20 piezas… galletas 30…").
class VoiceCaptureButton extends StatefulWidget {
  const VoiceCaptureButton({
    super.key,
    required this.idleLabel,
    required this.onUtterance,
  });

  final String idleLabel;
  final Future<void> Function(String transcript) onUtterance;

  @override
  State<VoiceCaptureButton> createState() => _VoiceCaptureButtonState();
}

class _VoiceCaptureButtonState extends State<VoiceCaptureButton> {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _active = false;

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_active) {
      setState(() => _active = false);
      await _speech.stop();
      return;
    }

    if (!_initialized) {
      _initialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: (_) {}, // los errores transitorios se reintentan vía onStatus
      );
      if (!_initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Micrófono no disponible o permiso denegado'),
            ),
          );
        }
        return;
      }
    }

    setState(() => _active = true);
    await _listen();
  }

  Future<void> _listen() async {
    if (!_active || !mounted || _speech.isListening) return;
    await _speech.listen(onResult: _onResult);
  }

  void _onStatus(String status) {
    // Cuando una escucha termina (pausa del usuario), se reengancha si sigue activo.
    if (_active && (status == 'done' || status == 'notListening')) {
      Future<void>.delayed(const Duration(milliseconds: 300), _listen);
    }
  }

  Future<void> _onResult(SpeechRecognitionResult result) async {
    if (!result.finalResult) return;
    final transcript = result.recognizedWords.trim();
    if (transcript.isEmpty) return;
    await widget.onUtterance(transcript);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          // Verde de marca cuando está escuchando (paleta Ágora).
          backgroundColor: _active ? const Color(0xFF22C55E) : null,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: _toggle,
        icon: Icon(_active ? Icons.stop_circle : Icons.mic),
        label: Text(_active ? 'Escuchando… toca para detener' : widget.idleLabel),
      ),
    );
  }
}
