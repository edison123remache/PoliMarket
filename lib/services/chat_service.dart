// /lib/services/chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService._private();
  static final ChatService instance = ChatService._private();
  final SupabaseClient supabase = Supabase.instance.client;

  // Obtener o crear chat entre dos usuarios (opcional serviceId)
  Future<String> getOrCreateChat({
    required String user1Id,
    required String user2Id,
    String? serviceId,
  }) async {
    final condition =
        "or(and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id))";

    final filtered = await supabase
        .from('chats')
        .select()
        .or(condition)
        .maybeSingle();

    if (filtered != null &&
        (serviceId == null || filtered['service_id'] == serviceId)) {
      return filtered['id'];
    }

    final inserted = await supabase
        .from('chats')
        .insert({
          'user1_id': user1Id,
          'user2_id': user2Id,
          'service_id': serviceId,
          'ultimo_mensaje': '',
        })
        .select()
        .single();

    return inserted['id'];
  }

  // Enviar mensaje (firma usada por los screens)
  // En ChatService
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    // Insertar mensaje en mensajes
    final res = await supabase
        .from('mensajes')
        .insert({
          'chat_id': chatId,
          'remitente_id': senderId,
          'contenido': text,
          'creado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    // Actualizar último mensaje en chats
    await supabase
        .from('chats')
        .update({
          'ultimo_mensaje': text,
          'ultimo_mensaje_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', chatId);

    return Map<String, dynamic>.from(res);
  }

  // Stream realtime de mensajes de un chat (filtrado por eq - OK en streams)
  // Stream realtime de mensajes de un chat (corrige el retraso al enviar)
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String chatId) {
    // 🔹 Suscribirse directamente con filtro en Supabase
    return supabase
        .from(
          'mensajes:chat_id=eq.$chatId',
        ) // filtra desde Supabase, no en memoria
        .stream(primaryKey: ['id'])
        .order('creado_en')
        .map((event) {
          // Convertir cada elemento a Map<String, dynamic>
          final data = event.map((e) => Map<String, dynamic>.from(e)).toList();

          // Ordenar por fecha por si acaso
          data.sort((a, b) {
            final da = a['creado_en'] != null
                ? DateTime.parse(a['creado_en'])
                : DateTime.now();
            final db = b['creado_en'] != null
                ? DateTime.parse(b['creado_en'])
                : DateTime.now();
            return da.compareTo(db);
          });

          return data;
        });
  }

  // Obtener mensajes históricos (una vez)
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final res = await supabase
        .from('mensajes')
        .select()
        .eq('chat_id', chatId)
        .order('creado_en', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // Obtener lista de chats del usuario (consulta normal)
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    final res = await supabase
        .from('chats')
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('ultimo_mensaje_en', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // Stream realtime de chats: escuchar la tabla completa y filtrar en memoria
  Stream<List<Map<String, dynamic>>> subscribeToUserChats(String userId) {
    final stream = supabase.from('chats').stream(primaryKey: ['id']);

    return stream.map((data) {
      final filtered = data.where((chat) {
        return chat['user1_id'] == userId || chat['user2_id'] == userId;
      }).toList();

      filtered.sort((a, b) {
        final da = a['ultimo_mensaje_en'] != null
            ? DateTime.parse(a['ultimo_mensaje_en'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        final db = b['ultimo_mensaje_en'] != null
            ? DateTime.parse(b['ultimo_mensaje_en'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da); // desc
      });

      return filtered.cast<Map<String, dynamic>>();
    });
  }

  // Obtener perfil de usuario (tabla 'perfiles')
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await supabase
        .from('perfiles')
        .select('id, nombre, avatar_url, bio')
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  // CITAS
  Future<void> crearCita({
    required String chatId,
    required String propuestoPor,
    required DateTime fecha,
    required String hora,
    required String ubicacion,
    String? detalles,
  }) async {
    await supabase.from('citas').insert({
      'chat_id': chatId,
      'propuesto_por': propuestoPor,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'ubicacion': ubicacion,
      'detalles': detalles,
    });
  }

// Obtener todas las citas de un chat
Future<List<Map<String, dynamic>>> getCitas(String chatId) async {
  final res = await supabase
      .from('citas')
      .select()
      .eq('chat_id', chatId)
      .order('creado_en', ascending: false);

  return List<Map<String, dynamic>>.from(res);
}

  Future<void> actualizarEstadoCita(String citaId, String estado) async {
    await supabase.from('citas').update({'estado': estado}).eq('id', citaId);
  }
}
