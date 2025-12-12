import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  final SupabaseClient _supabase;

  RatingService(this._supabase);

  // Verificar si un usuario puede calificar a otro para un servicio específico
  Future<bool> canUserRate({
    required String fromUserId,
    required String toUserId,
    required String serviceId,
  }) async {
    try {
      final existingRating = await _supabase
          .from('calificaciones')
          .select()
          .eq('from_user_id', fromUserId)
          .eq('to_user_id', toUserId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (existingRating != null) {
        return false; // Esta es la condicion que se aplica para cuando el user ya haya hecho una calificacion antes}
      }

      // Aqui se encargar de verificar si hubo un chat entre los usuarios para este servicio
      final chat = await _supabase
          .from('chats')
          .select()
          .or('user1_id.eq.$fromUserId,user2_id.eq.$fromUserId')
          .or('user1_id.eq.$toUserId,user2_id.eq.$toUserId')
          .eq('service_id', serviceId)
          .maybeSingle();

      if (chat == null) {
        return false; // No hay chat
      }

      // Interaccion minima de 5 mensajes en el chat
      final messages = await _supabase
          .from('mensajes')
          .select()
          .eq('chat_id', chat['id'])
          .limit(5);

      // Funcion para verificar si hubo una propuesta aceptada entre los ususarios
      final acceptedAppointment = await _supabase
          .from('citas')
          .select()
          .eq('chat_id', chat['id'])
          .eq('estado', 'aceptada')
          .maybeSingle();

      // Puede calificar si: hay al menos 5 mensajes O hay una cita aceptada
      return messages.length >= 5 || acceptedAppointment != null;
    } catch (e) {
      print('Error en canUserRate: $e');
      return false;
    }
  }

  // Enviar calificación
  Future<void> rateUser({
    required String fromUserId,
    required String toUserId,
    required String serviceId,
    required int stars,
    required String categoricalFeedback,
  }) async {
    try {
      // Verificar que puede calificar
      final canRate = await canUserRate(
        fromUserId: fromUserId,
        toUserId: toUserId,
        serviceId: serviceId,
      );

      if (!canRate) {
        throw Exception(
          'No puedes calificar a este usuario. '
          'Debes haber interactuado en el chat (mínimo 5 mensajes) '
          'o tener una cita aceptada.',
        );
      }

      // Insertar calificación
      await _supabase.from('calificaciones').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'service_id': serviceId,
        'estrellas': stars,
        'comentario_categorico': categoricalFeedback,
      });

      // Actualizar promedio del usuario calificado (se hace automáticamente con trigger)
    } catch (e) {
      print('Error en rateUser: $e');
      rethrow;
    }
  }

  // Funcion para Obtener todas las calificaciones de un usuario
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    final ratings = await _supabase
        .from('calificaciones')
        .select(
          '*, perfiles!calificaciones_from_user_id_fkey(nombre, avatar_url)',
        )
        .eq('to_user_id', userId)
        .order('creado_en', ascending: false);

    return ratings;
  }

  // Funcion para Obtener calificación específica entre dos usuarios para un servicio
  Future<Map<String, dynamic>?> getRatingBetweenUsers({
    required String fromUserId,
    required String toUserId,
    required String serviceId,
  }) async {
    return await _supabase
        .from('calificaciones')
        .select()
        .eq('from_user_id', fromUserId)
        .eq('to_user_id', toUserId)
        .eq('service_id', serviceId)
        .maybeSingle();
  }

  // Calculo de las calificaciones
  Map<String, dynamic> calculateRatingStats(
    List<Map<String, dynamic>> ratings,
  ) {
    if (ratings.isEmpty) {
      return {
        'average': 0.0,
        'total': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'percentageDistribution': {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0},
      };
    }

    double total = 0;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var rating in ratings) {
      final stars = rating['estrellas'] as int;
      total += stars;
      distribution[stars] = (distribution[stars] ?? 0) + 1;
    }

    final average = total / ratings.length;

    // Calcular porcentajes
    Map<int, double> percentageDistribution = {};
    distribution.forEach((stars, count) {
      percentageDistribution[stars] = (count / ratings.length) * 100;
    });

    return {
      'average': double.parse(average.toStringAsFixed(1)),
      'total': ratings.length,
      'distribution': distribution,
      'percentageDistribution': percentageDistribution,
    };
  }
}
