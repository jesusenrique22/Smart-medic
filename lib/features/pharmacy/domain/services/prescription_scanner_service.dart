import 'dart:io';

import 'package:flutter/foundation.dart';

/// Escaneo de recetas. ML Kit no funciona en simulador iOS (arm64); en móvil
/// se usa lista demo hasta probar en dispositivo físico o reactivar ML Kit.
class PrescriptionScannerService {
  Future<List<String>> processPrescription(File imageFile) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      return ['Amoxicilina', 'Ibuprofeno'];
    }

    // google_mlkit_text_recognition no enlaza en simulador iOS 26+ (arm64).
    // Evita crash nativo al arrancar; en dispositivo real se puede volver a añadir el plugin.
    await Future.delayed(const Duration(milliseconds: 800));
    return ['Amoxicilina', 'Ibuprofeno', 'Paracetamol'];
  }

  void dispose() {}
}
