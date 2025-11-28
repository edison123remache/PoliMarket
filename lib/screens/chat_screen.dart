// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../services/chat_service.dart';
import 'propuesta_encuentro_screen.dart';
import 'profile_screen.dart';
import '../widgets/cita_message_bubble.dart';
import 'info_servicio.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? servicioTitulo;
  final String? servicioPrecio;
  final String? servicioFotoUrl;
  final String? servicioId; // <--- nuevo campo opcional

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.servicioTitulo,
    this.servicioPrecio,
    this.servicioFotoUrl,
    this.servicioId, // <--- agregar al constructor
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;
  final user = Supabase.instance.client.auth.currentUser;
  final TextEditingController _controller = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  Map<String, dynamic>? _otherProfile;
  final List<Map<String, dynamic>> _optimisticMessages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  int _lastRenderedCount = 0;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.subscribeToMessages(widget.chatId);
    _loadOtherProfile();

    _controller.addListener(() {
      setState(() => _isTyping = _controller.text.trim().isNotEmpty);
    });
  }

  Future<void> _loadOtherProfile() async {
    final p = await _chatService.getProfile(widget.otherUserId);
    if (mounted) setState(() => _otherProfile = p);
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || user == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final ahoraUtc = DateTime.now().toUtc().toIso8601String();

    final optimisticMessage = {
      'id': tempId,
      'remitente_id': user!.id,
      'contenido': text,
      'creado_en': ahoraUtc,
      '_is_optimistic': true,
    };

    setState(() {
      _optimisticMessages.add(optimisticMessage);
    });

    _controller.clear();
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user!.id,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar mensaje')),
        );
        setState(() {
          _optimisticMessages.removeWhere((m) => m['id'] == tempId);
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime _parseCreatedEn(dynamic value) {
    try {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0).toUtc();
      if (value is DateTime) return value.toUtc();
      if (value is String) return DateTime.parse(value).toUtc();
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0).toUtc();
  }

  String _formatHourFromCreated(dynamic createdEn) {
    try {
      final dt = _parseCreatedEn(createdEn);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  bool _optimisticMatchesServer(
    Map<String, dynamic> optimistic,
    Map<String, dynamic> server,
  ) {
    try {
      if (optimistic['remitente_id'] != server['remitente_id']) return false;

      final optContent = optimistic['contenido'];
      final srvContent = server['contenido'];

      if (optContent is String && srvContent is String) {
        if (optContent == srvContent) {
          final optTime = _parseCreatedEn(optimistic['creado_en']);
          final srvTime = _parseCreatedEn(server['creado_en']);
          return srvTime.difference(optTime).inSeconds.abs() <= 10;
        }
      }

      if (optContent is String && srvContent is Map) {
        if (srvContent.containsKey('text') &&
            srvContent['text'] == optContent) {
          final optTime = _parseCreatedEn(optimistic['creado_en']);
          final srvTime = _parseCreatedEn(server['creado_en']);
          return srvTime.difference(optTime).inSeconds.abs() <= 10;
        }
      }

      if (optContent is Map && srvContent is Map) {
        if (optContent.containsKey('client_id') &&
            srvContent.containsKey('client_id')) {
          return optContent['client_id'] == srvContent['client_id'];
        }
        if (optContent.containsKey('text') && srvContent.containsKey('text')) {
          if (optContent['text'] == srvContent['text']) {
            final optTime = _parseCreatedEn(optimistic['creado_en']);
            final srvTime = _parseCreatedEn(server['creado_en']);
            return srvTime.difference(optTime).inSeconds.abs() <= 10;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  bool _isAtBottom({double tolerance = 40.0}) {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    return (maxScroll - current) <= tolerance;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = _otherProfile?['nombre'] ?? 'Cargando...';
    final String? avatarUrl = _otherProfile?['avatar_url'];
    final bool soyVendedor = widget.servicioTitulo != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(  //cambios hechos1
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: widget.otherUserId),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 22)
                    : null,
                backgroundColor: Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    soyVendedor
                        ? 'Acerca del comprador'
                        : 'Acerca del vendedor',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Eliminar chat"),
                    content: const Text(
                      "Esto borrará todo el historial del chat. ¿Deseas continuar?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Eliminar"),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  await ChatService.instance.deleteChat(widget.chatId);

                  if (mounted) {
                    Navigator.pop(context); // Regresa a la bandeja
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text("Eliminar chat")),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          if (widget.servicioTitulo != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final servicioId = widget.servicioId;
                  if (servicioId != null && servicioId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleServicioScreen(servicioId: servicioId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Servicio no disponible')),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (widget.servicioFotoUrl != null &&
                          widget.servicioFotoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.servicioFotoUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.servicioTitulo!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.servicioPrecio != null &&
                                widget.servicioPrecio!.isNotEmpty)
                              Text(
                                widget.servicioPrecio!,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chat + Input
          Expanded(
            child: Stack(
              children: [
                // Lista de mensajes
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    final serverMessages = snapshot.data ?? [];

                    final Map<String, Map<String, dynamic>> mergedById = {};

                    for (final s in serverMessages) {
                      try {
                        final id = (s['id'] ?? '').toString();
                        if (id.isNotEmpty) {
                          mergedById[id] = Map<String, dynamic>.from(s);
                        } else {
                          final key =
                              'srv_${s['remitente_id']}_${s['creado_en'] ?? UniqueKey()}';
                          mergedById[key] = Map<String, dynamic>.from(s);
                        }
                      } catch (e) {
                        final key = 'srv_err_${UniqueKey()}';
                        mergedById[key] = Map<String, dynamic>.from(s);
                      }
                    }

                    for (final opt in _optimisticMessages) {
                      bool matched = false;
                      for (final srv in mergedById.values) {
                        if (_optimisticMatchesServer(opt, srv)) {
                          matched = true;
                          break;
                        }
                      }
                      if (!matched) {
                        mergedById[opt['id']] = Map<String, dynamic>.from(opt);
                      }
                    }

                    final toRemove = <String>{};
                    for (final opt in _optimisticMessages) {
                      for (final srv in mergedById.values) {
                        final srvIsOptimistic =
                            srv.containsKey('_is_optimistic') &&
                            srv['_is_optimistic'] == true;
                        if (!srvIsOptimistic &&
                            _optimisticMatchesServer(opt, srv)) {
                          toRemove.add(opt['id']);
                          break;
                        }
                      }
                    }

                    if (toRemove.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _optimisticMessages.removeWhere(
                            (m) => toRemove.contains(m['id']),
                          );
                        });
                      });
                    }

                    final allMessages = mergedById.values.toList();
                    allMessages.sort((a, b) {
                      final da = _parseCreatedEn(a['creado_en']);
                      final db = _parseCreatedEn(b['creado_en']);
                      return da.compareTo(db);
                    });

                    if (allMessages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Empieza la conversación',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (allMessages.length != _lastRenderedCount ||
                          _isAtBottom()) {
                        _lastRenderedCount = allMessages.length;
                        _scrollToBottom();
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: allMessages.length,
                      itemBuilder: (context, i) {
                        final msg = allMessages[i];
                        final isMe = user?.id == msg['remitente_id'];

                        final contenidoRaw = msg['contenido'];
                        final horaTexto = _formatHourFromCreated(
                          msg['creado_en'],
                        );

                        Map<String, dynamic>? citaMap;
                        if (contenidoRaw is Map<String, dynamic>) {
                          if (contenidoRaw.containsKey('cita_id')) {
                            citaMap = Map<String, dynamic>.from(contenidoRaw);
                          }
                        } else if (contenidoRaw is String) {
                          final raw = contenidoRaw.trim();
                          if (raw.startsWith('{') && raw.endsWith('}')) {
                            try {
                              final decoded = jsonDecode(raw);
                              if (decoded is Map<String, dynamic> &&
                                  decoded.containsKey('cita_id')) {
                                citaMap = decoded;
                              }
                            } catch (_) {}
                          }
                        }

                        if (citaMap != null) {
                          final cita = {
                            'id': citaMap['cita_id'].toString(),
                            'fecha': citaMap['fecha'] ?? 'Sin fecha',
                            'ubicacion':
                                citaMap['ubicacion'] ?? 'Sin ubicación',
                            'detalles': citaMap['detalles'] ?? '',
                            'estado': citaMap['estado'] ?? 'pendiente',
                            'propuesto_por':
                                citaMap['propuesto_por'] ?? user?.id,
                          };
                          return CitaMessageBubble1(
                            cita: cita,
                            esPropietario: isMe,
                          );
                        }

                        String texto = '[Mensaje]';
                        if (contenidoRaw is String) {
                          texto = contenidoRaw;
                        } else if (contenidoRaw is Map<String, dynamic>) {
                          if (contenidoRaw.containsKey('text') &&
                              contenidoRaw['text'] is String) {
                            texto = contenidoRaw['text'];
                          } else {
                            texto = contenidoRaw.toString();
                          }
                        }

                        final isOptimistic =
                            msg.containsKey('_is_optimistic') &&
                            msg['_is_optimistic'] == true;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Opacity(
                            opacity: isOptimistic ? 0.92 : 1.0,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF007AFF)
                                    : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    texto,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    horaTexto,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Input + Botón propuesta
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: "propuesta",
                        backgroundColor: Colors.orange,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropuestaEncuentroScreen(
                                chatId: widget.chatId,
                                otherUserId: widget.otherUserId,
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  onSubmitted: (_) =>
                                      _sendMessage(_controller.text.trim()),
                                ),
                              ),
                              if (_isTyping)
                                GestureDetector(
                                  onTap: () =>
                                      _sendMessage(_controller.text.trim()),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF007AFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
