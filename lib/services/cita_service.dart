import 'package:supabase_flutter/supabase_flutter.dart';

class CitaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCitasAceptadas() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Obtener chats donde el usuario participa (basado en tu esquema)
      final chatsResponse = await _supabase
          .from('chats')
          .select('id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      if (chatsResponse.isEmpty) return [];

      final chatIds = chatsResponse.map((c) => c['id'] as String).toList();

      // 2. Obtener solo citas ACEPTADAS de esos chats
      final response = await _supabase
          .from('citas')
          .select('''
            *,
            chats (
              id,
              user1_id,
              user2_id,
              service_id,
              servicios:service_id (
                titulo
              )
            ),
            perfiles:propuesto_por (
              id,
              nombre,
              avatar_url
            )
          ''')
          .filter('chat_id', 'in', chatIds)
          .eq('estado', 'aceptada') // SOLO CITAS ACEPTADAS
          .order('fecha', ascending: true)
          .order('hora', ascending: true);

      return response;
    } catch (e) {
      print('Error en getCitasAceptadas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCitaDetallada(String citaId) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('''
            *,
            chats (
              id,
              user1_id,
              user2_id,
              service_id,
              servicios:service_id (
                titulo,
                descripcion
              )
            ),
            perfiles:propuesto_por (
              id,
              nombre,
              avatar_url,
              bio
            )
          ''')
          .eq('id', citaId)
          .single();

      return response;
    } catch (e) {
      print('Error en getCitaDetallada: $e');
      return null;
    }
  }

  // NO necesitamos método para cambiar estado porque solo mostramos aceptadas
}
