// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../services/chat_service.dart';
import 'propuesta_encuentro_screen.dart';
import 'profile_screen.dart';
import 'cita_detail_screen.dart';
import 'info_servicio.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? servicioTitulo;
  final String? servicioPrecio;
  final String? servicioFotoUrl;
  final String? servicioId;
  final String? vendedorId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.servicioTitulo,
    this.servicioPrecio,
    this.servicioFotoUrl,
    this.servicioId,
    this.vendedorId,
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

  final Color kPrimary = const Color(0xFFFF6B35);
  final Color kMyMessage = const Color(0xFFFF6B35);
  final Color kOtherMessage = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.subscribeToMessages(widget.chatId);
    _loadOtherProfile();

    _controller.addListener(() {
      setState(() => _isTyping = _controller.text.trim().isNotEmpty);
    });

    debugPrint('=== CHAT SCREEN DEBUG ===');
    debugPrint('Mi ID (user): ${user?.id}');
    debugPrint('Otro usuario ID: ${widget.otherUserId}');
    debugPrint('Vendedor ID recibido: ${widget.vendedorId}');
    debugPrint('========================');
  }

  Future<void> _loadOtherProfile() async {
    final p = await _chatService.getProfile(widget.otherUserId);
    if (mounted) setState(() => _otherProfile = p);
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || user == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final ahoraLocal = DateTime.now().toIso8601String();

    final optimisticMessage = {
      'id': tempId,
      'remitente_id': user!.id,
      'contenido': text,
      'creado_en': ahoraLocal,
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
          SnackBar(
            content: const Text('Error al enviar mensaje'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      if (value is String) return DateTime.parse(value).toLocal();
    } catch (_) {}
    return DateTime.now();
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

    final bool soyVendedor = widget.vendedorId != null
        ? widget.vendedorId == user?.id
        : false;

    final bool otroEsVendedor = widget.vendedorId != null
        ? widget.vendedorId == widget.otherUserId
        : widget.servicioTitulo != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.grey.shade800,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.otherUserId),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  backgroundColor: kPrimary.withOpacity(0.1),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(Icons.person_rounded, size: 24, color: kPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      otroEsVendedor ? 'Vendedor' : 'Comprador',
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("Eliminar"),
                        ),
                      ],
                    ),
                  );

                  if (confirmar == true) {
                    await ChatService.instance.deleteChat(widget.chatId);
                    if (mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text("Eliminar chat"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Card de servicio mejorada
          if (widget.servicioTitulo != null)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                        SnackBar(
                          content: const Text('Servicio no disponible'),
                          backgroundColor: Colors.orange.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        if (widget.servicioFotoUrl != null &&
                            widget.servicioFotoUrl!.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.servicioFotoUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: kPrimary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.servicioTitulo!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.servicioPrecio != null &&
                                  widget.servicioPrecio!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.servicioPrecio!,
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: kPrimary.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Empieza la conversación',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                            'lat': citaMap['lat'],
                            'lon': citaMap['lon'],
                          };
                          return CitaMessageBubble(
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
                            opacity: isOptimistic ? 0.7 : 1.0,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? LinearGradient(
                                        colors: [
                                          kPrimary,
                                          kPrimary.withOpacity(0.8),
                                        ],
                                      )
                                    : null,
                                color: isMe ? null : kOtherMessage,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: isMe
                                      ? const Radius.circular(20)
                                      : const Radius.circular(4),
                                  bottomRight: isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    texto,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        horaTexto,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (soyVendedor)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kPrimary, kPrimary.withOpacity(0.8)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            onSubmitted: (_) =>
                                _sendMessage(_controller.text.trim()),
                          ),
                        ),
                        if (_isTyping)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kPrimary, kPrimary.withOpacity(0.8)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _sendMessage(_controller.text.trim()),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
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
