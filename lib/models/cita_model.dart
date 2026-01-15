import 'package:flutter/material.dart';

class Cita {
  final String id;
  final String chatId;
  final String propuestoPor;
  final DateTime fecha;
  final TimeOfDay hora;
  final String ubicacion;
  final String? detalles;
  final String estado;
  final DateTime creadoEn;
  final Map<String, dynamic>? chatInfo;
  final Map<String, dynamic>? perfilInfo;
  final Map<String, dynamic>? servicioInfo;
  final bool esPropietario;
  final String? otroUsuarioId; // ID del otro usuario en el chat

  // CAMBIO AQUÍ: Se eliminó 'final' para permitir la actualización del nombre
  String? otroUsuarioNombre;

  Cita({
    required this.id,
    required this.chatId,
    required this.propuestoPor,
    required this.fecha,
    required this.hora,
    required this.ubicacion,
    this.detalles,
    required this.estado,
    required this.creadoEn,
    this.chatInfo,
    this.perfilInfo,
    this.servicioInfo,
    required this.esPropietario,
    this.otroUsuarioId,
    this.otroUsuarioNombre,
  });

  factory Cita.fromMap(Map<String, dynamic> map, String currentUserId) {
    final horaParts = (map['hora'] as String).split(':');

    // Extraer información del chat
    final chat = map['chats'] as Map<String, dynamic>?;
    final servicio = map['chats']?['servicios'] as Map<String, dynamic>?;
    final perfil = map['perfiles'] as Map<String, dynamic>?;

    // Determinar quién es el otro usuario en el chat
    String? otroUsuarioId;

    if (chat != null) {
      if (chat['user1_id'] == currentUserId) {
        otroUsuarioId = chat['user2_id'];
      } else {
        otroUsuarioId = chat['user1_id'];
      }
    }

    return Cita(
      id: map['id'],
      chatId: map['chat_id'],
      propuestoPor: map['propuesto_por'],
      fecha: DateTime.parse(map['fecha']),
      hora: TimeOfDay(
        hour: int.parse(horaParts[0]),
        minute: int.parse(horaParts[1]),
      ),
      ubicacion: map['ubicacion'],
      detalles: map['detalles'],
      estado: map['estado'] ?? 'pendiente',
      creadoEn: DateTime.parse(map['creado_en']),
      chatInfo: chat,
      perfilInfo: perfil,
      servicioInfo: servicio,
      esPropietario: map['propuesto_por'] == currentUserId,
      otroUsuarioId: otroUsuarioId,
      otroUsuarioNombre: 'Usuario', // Temporal, se actualizará después
    );
  }

  DateTime get fechaHoraCompleta {
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  bool get esHoy {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }

  bool get esPasada {
    return fechaHoraCompleta.isBefore(DateTime.now());
  }

  bool get esFutura {
    return fechaHoraCompleta.isAfter(DateTime.now());
  }

  bool get esProxima {
    final now = DateTime.now();
    final diferencia = fechaHoraCompleta.difference(now);
    return esFutura && diferencia.inDays <= 2; // Próximos 2 días
  }
}
