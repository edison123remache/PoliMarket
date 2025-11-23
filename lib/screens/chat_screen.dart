import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import 'propuesta_encuentro_screen.dart';
import 'cita_detail_screen.dart';
import 'profile_screen.dart'; // ← Importante: para navegar al perfil

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
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

  final List<Map<String, dynamic>> _localMessages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.subscribeToMessages(widget.chatId);
    _loadOtherProfile();
    _loadHistoricalMessages();
  }

  Future<void> _loadOtherProfile() async {
    final p = await _chatService.getProfile(widget.otherUserId);
    setState(() => _otherProfile = p);
  }

  Future<void> _loadHistoricalMessages() async {
    final messages = await _chatService.getMessages(widget.chatId);
    setState(() {
      _localMessages.clear();
      _localMessages.addAll(messages);
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || user == null) return;

    final newMessage = {
      'remitente_id': user!.id,
      'contenido': text,
      'creado_en': DateTime.now().toIso8601String(),
    };

    setState(() {
      _localMessages.add(newMessage);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar mensaje')),
      );
      setState(() => _localMessages.remove(newMessage));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _otherProfile?['nombre'] ?? 'Cargando...';
    final String? avatarUrl = _otherProfile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          // ← AQUÍ ESTÁ LO QUE QUERÍAS: TOCAR FOTO O NOMBRE → ABRE PERFIL
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: widget.otherUserId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Toca para ver perfil',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              final citas = await _chatService.getCitas(widget.chatId);
              if (citas.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CitaDetailScreen(cita: citas[0]),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay propuesta registrada')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snap) {
                final streamMsgs = snap.data ?? [];
                final allMessages = [..._localMessages, ...streamMsgs];

                allMessages.sort((a, b) {
                  final da = a['creado_en'] != null
                      ? DateTime.parse(a['creado_en']).toLocal()
                      : DateTime.now();
                  final db = b['creado_en'] != null
                      ? DateTime.parse(b['creado_en']).toLocal()
                      : DateTime.now();
                  return da.compareTo(db);
                });

                if (allMessages.isEmpty) {
                  return const Center(child: Text('Empieza la conversación'));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: allMessages.length,
                  itemBuilder: (_, i) {
                    final msg = allMessages[i];
                    final bool isMe = user != null && msg['remitente_id'] == user!.id;
                    final content = msg['contenido'] ?? '';
                    final DateTime? time = msg['creado_en'] != null
                        ? DateTime.parse(msg['creado_en']).toLocal()
                        : null;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                            if (time != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de mensaje
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Escribe un mensaje...',
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}