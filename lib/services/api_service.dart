import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  /// Llama a la API y devuelve la ruta local del PDF guardado
  static Future<String?> downloadPdf() async {
    try {
      final url = Uri.parse('https://llama-market-api.vercel.app/api/report');

      // Hacer GET
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Bytes del PDF
        Uint8List bytes = response.bodyBytes;

        // Ruta local
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/report.pdf');

        // Guardar
        await file.writeAsBytes(bytes, flush: true);

        return file.path;
      } else {
        debugPrint('Error al descargar PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception en downloadPdf: $e');
      return null;
    }
  }
}
