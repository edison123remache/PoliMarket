import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatService {
  ChatService._private();
  static final ChatService instance = ChatService._private();
  final SupabaseClient supabase = Supabase.instance.client;

  // ===========================================================
  // ðŸ”¹ Obtener o crear un chat
  // ===========================================================
  Future<String> getOrCreateChat({
    required String user1Id,
    required String user2Id,
    String? serviceId,
  }) async {
    final condition =
        "or(and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id))";

    var query = supabase.from('chats').select().or(condition);

    // âœ… FILTRAR POR SERVICIO SI EXISTE
    if (serviceId != null) {
      query = query.eq('service_id', serviceId.toString());
    }

    final existing = await query.limit(1);

    // âœ… SI YA EXISTE CHAT â†’ USARLO
    if (existing.isNotEmpty) {
      return existing.first['id'].toString();
    }

    // âœ… SI NO EXISTE â†’ CREAR NUEVO
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

    return inserted['id'].toString();
  }

  // ===========================================================
  // ðŸ”¹ Enviar mensaje + actualizar chat
  // ===========================================================
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final res = await supabase
        .from('mensajes')
        .insert({
          'chat_id': chatId,
          'remitente_id': senderId,
          'contenido': {'text': text},
          'creado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    await supabase
        .from('chats')
        .update({
          'ultimo_mensaje': text,
          'ultimo_mensaje_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', chatId);

    final data = await supabase
        .from('chats')
        .select('user1_id, user2_id')
        .eq('id', chatId)
        .maybeSingle();

    if (data == null) return {};

    final ids = [data['user1_id'] as String, data['user2_id'] as String];

    final recipientId = ids[0] == senderId ? ids[1] : ids[0];

    final response =await supabase.functions.invoke(
      'send-notification',
      body: {'user_id': recipientId, 'content': text},
    );

    debugPrint(response.toString());

    return Map<String, dynamic>.from(res);
  }

  // ===========================================================
  // ðŸ”¹ Stream de mensajes en tiempo real
  // ===========================================================
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String chatId) {
    return Supabase.instance.client
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('creado_en')
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final res = await supabase
        .from('mensajes')
        .select()
        .eq('chat_id', chatId)
        .order('creado_en', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ===========================================================
  // ðŸ”¥ðŸ”¥ðŸ”¥ STREAM OPTIMIZADO DE LISTA DE CHATS ðŸ”¥ðŸ”¥ðŸ”¥
  // ===========================================================
  Stream<List<Map<String, dynamic>>> subscribeToUserChats(String userId) {
    return supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((rawChats) async {
          final filtered = rawChats.where((chat) {
            return (chat['user1_id'] == userId || chat['user2_id'] == userId) &&
                (chat['ultimo_mensaje'] != null &&
                    chat['ultimo_mensaje'].toString().trim().isNotEmpty);
          }).toList();

          final List<Map<String, dynamic>> result = [];

          for (var chat in filtered) {
            final map = Map<String, dynamic>.from(chat);

            final serviceId = map['service_id'];
            if (serviceId != null) {
              final serv = await supabase
                  .from('servicios')
                  .select('titulo, fotos')
                  .eq('id', serviceId)
                  .maybeSingle();

              final fotos = serv?['fotos'];

              map['servicio_titulo'] = serv?['titulo'];
              map['servicio_foto_url'] = (fotos is List && fotos.isNotEmpty)
                  ? fotos[0]
                  : null;
            } else {
              map['servicio_titulo'] = null;
              map['servicio_foto_url'] = null;
            }

            result.add(map);
          }

          result.sort((a, b) {
            final da = a['ultimo_mensaje_en'] != null
                ? DateTime.parse(a['ultimo_mensaje_en'])
                : DateTime.fromMillisecondsSinceEpoch(0);

            final db = b['ultimo_mensaje_en'] != null
                ? DateTime.parse(b['ultimo_mensaje_en'])
                : DateTime.fromMillisecondsSinceEpoch(0);

            return db.compareTo(da);
          });

          return result;
        })
        .asyncMap((e) => e);
  }

  // ===========================================================
  // ðŸ”¹ borrar chat
  // ===========================================================
  Future<void> deleteChat(String chatId) async {
    await supabase.from('mensajes').delete().eq('chat_id', chatId);
    await supabase.from('citas').delete().eq('chat_id', chatId);
    await supabase.from('chats').delete().eq('id', chatId);
  }

  // ===========================================================
  // ðŸ”¹ Obtener perfil
  // ===========================================================
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await supabase
        .from('perfiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return res == null ? null : Map<String, dynamic>.from(res);
  }

  // ===========================================================
  // ðŸ”¥ CREAR CITA + MENSAJE
  // ===========================================================
  Future<Map<String, dynamic>> crearCitaYEnviarMensaje({
    required String chatId,
    required String propuestoPor,
    required DateTime fecha,
    required String ubicacion,
    String? detalles,
    required String fechaFormateada,
  }) async {
    final citaRes = await supabase
        .from('citas')
        .insert({
          'chat_id': chatId,
          'propuesto_por': propuestoPor,
          'fecha': fecha.toIso8601String(),
          'hora': DateFormat('HH:mm').format(fecha),
          'ubicacion': ubicacion,
          'detalles': detalles?.trim().isEmpty == true ? null : detalles,
          'estado': 'pendiente',
          'creado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    final citaId = citaRes['id'];

    final mensajeRes = await supabase
        .from('mensajes')
        .insert({
          'chat_id': chatId,
          'remitente_id': propuestoPor,
          'contenido': {
            'cita_id': citaId,
            'fecha': fechaFormateada,
            'ubicacion': ubicacion,
            'detalles': detalles ?? '',
            'estado': 'pendiente',
            'propuesto_por': propuestoPor,
          },
          'creado_en': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    await supabase
        .from('chats')
        .update({
          'ultimo_mensaje': 'Propuso un encuentro',
          'ultimo_mensaje_en': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', chatId);

    return Map<String, dynamic>.from(mensajeRes);
  }

  // ===========================================================
  // ðŸ”¹ Actualizar estado cita
  // ===========================================================
  Future<void> actualizarEstadoCitaCompleto(
    String citaId,
    String nuevoEstado,
  ) async {
    // 1ï¸âƒ£ Actualiza la tabla citas
    await supabase
        .from('citas')
        .update({'estado': nuevoEstado})
        .eq('id', citaId);

    // 2ï¸âƒ£ Buscar mensajes usando ->> (EXTRAE TEXTO, NO JSON)
    final mensajes = await supabase
        .from('mensajes')
        .select('id, contenido')
        .filter('contenido->>cita_id', 'eq', citaId.toString());

    for (final msg in mensajes) {
      final Map<String, dynamic> contenido = Map<String, dynamic>.from(
        msg['contenido'],
      );

      contenido['estado'] = nuevoEstado;

      await supabase
          .from('mensajes')
          .update({'contenido': contenido})
          .eq('id', msg['id'])
          .filter('contenido->>estado', 'eq', 'pendiente');
    }
  }
}
