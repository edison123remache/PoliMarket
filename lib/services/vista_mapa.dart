import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapService {
  static late String _apiKey;
  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  // Geocodificar una dirección a coordenadas
  static Future<Map<String, double>> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$_apiKey&q=${Uri.encodeComponent(address)}&format=json&limit=1',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
          };
        }
      }
      throw Exception('No se pudo geocodificar la dirección');
    } catch (e) {
      throw Exception('Error en geocodificación: $e');
    }
  }

  // Generar URL de mapa estático
  static String getStaticMapUrl(
    double lat,
    double lon, {
    int width = 300,
    int height = 200,
  }) {
    return 'https://maps.locationiq.com/v3/staticmap?key=$_apiKey&center=$lat,$lon&zoom=15&size=${width}x$height&format=png&markers=icon:small-red-cutout|$lat,$lon';
  }

  // Obtener mapa estático para una dirección
  static Future<String> getStaticMapForAddress(String address) async {
    try {
      final coords = await geocodeAddress(address);
      return getStaticMapUrl(coords['lat']!, coords['lon']!);
    } catch (e) {
      // Si falla la geocodificación, retornar mapa por defecto
      return 'https://maps.locationiq.com/v3/staticmap?key=$_apiKey&center=-0.180653,-78.467834&zoom=15&size=300x200&format=png&markers=icon:small-red-cutout|-0.180653,-78.467834';
    }
  }
}
