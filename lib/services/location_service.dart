import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationServiceIQ {
  static late String _apiKey;

  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  // Obtener la ubicación actual del dispositivo
  static Future<Position> getCurrentLocation() async {
    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permisos de ubicación permanentemente denegados. Por favor habilítalos en ajustes.',
      );
    }

    // Obtener ubicación
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Convertir coordenadas a dirección usando LocationIQ
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://us1.locationiq.com/v1/reverse.php?key=$_apiKey&lat=$lat&lon=$lon&format=json&accept-language=es',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        // Construir dirección legible
        String street = address['road'] ?? '';
        String number = address['house_number'] ?? '';
        String neighborhood = address['neighbourhood'] ?? '';
        String city =
            address['city'] ?? address['town'] ?? address['village'] ?? '';
        String state = address['state'] ?? '';

        List<String> addressParts = [];
        if (street.isNotEmpty) {
          addressParts.add('$street${number.isNotEmpty ? " $number" : ""}');
        }
        if (neighborhood.isNotEmpty) addressParts.add(neighborhood);
        if (city.isNotEmpty) addressParts.add(city);
        if (state.isNotEmpty) addressParts.add(state);

        return addressParts.join(', ');
      } else {
        throw Exception(
          'Error de LocationIQ: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener dirección: $e');
    }
  }

  // Buscar lugares por texto (para futuras implementaciones)
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final url = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$_apiKey&q=$query&format=json&accept-language=es&limit=5',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((place) {
          return {
            'display_name': place['display_name'],
            'lat': place['lat'],
            'lon': place['lon'],
          };
        }).toList();
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al buscar lugares: $e');
    }
  }
}
