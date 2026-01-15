// lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService.instance;
  final user = Supabase.instance.client.auth.currentUser;

  // Controladores y Estados
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>?> _profileCache = {};

  final Color kPrimary = const Color(0xFFFF6B35);
  final Color kDark = const Color(0xFF1E293B);

  Future<Map<String, dynamic>?> _getProfileCached(String userId) async {
    if (_profileCache.containsKey(userId)) return _profileCache[userId];
    final profile = await _chatService.getProfile(userId);
    _profileCache[userId] = profile;
    return profile;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.subscribeToUserChats(user!.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    );
                  }

                  // Precargar perfiles para búsqueda
                  for (var chat in snapshot.data!) {
                    final otherId = chat['user1_id'] == user!.id
                        ? chat['user2_id']
                        : chat['user1_id'];
                    _getProfileCached(otherId);
                  }

                  // Filtrar por búsqueda
                  final chatsFiltrados = snapshot.data!.where((chat) {
                    final otherId = chat['user1_id'] == user!.id
                        ? chat['user2_id']
                        : chat['user1_id'];
                    final nombre =
                        _profileCache[otherId]?['nombre']
                            ?.toString()
                            .toLowerCase() ??
                        "";
                    final titulo =
                        chat['servicio_titulo']?.toString().toLowerCase() ?? "";
                    final mensaje =
                        chat['ultimo_mensaje']?.toString().toLowerCase() ?? "";
                    final query = _searchQuery.toLowerCase();

                    return nombre.contains(query) ||
                        titulo.contains(query) ||
                        mensaje.contains(query);
                  }).toList();

                  if (chatsFiltrados.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: chatsFiltrados.length,
                    itemBuilder: (context, i) =>
                        _buildChatTile(chatsFiltrados[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Mensajes",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Buscar conversaciones...",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: kPrimary, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    final otherUserId = chat['user1_id'] == user!.id
        ? chat['user2_id']
        : chat['user1_id'];

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfileCached(otherUserId),
      builder: (context, profileSnap) {
        final nombre = profileSnap.data?['nombre'] ?? 'Usuario';
        final foto = chat['servicio_foto_url'];
        final servicioId = chat['service_id']?.toString();
        final servicioTitulo = chat['servicio_titulo']?.toString() ?? '';
        final ultimoMensaje = chat['ultimo_mensaje']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                String? vendedorId;
                if (servicioId != null) {
                  try {
                    final servicio = await Supabase.instance.client
                        .from('servicios')
                        .select('user_id')
                        .eq('id', servicioId)
                        .single();
                    vendedorId = servicio['user_id'];
                  } catch (e) {
                    debugPrint('Error obteniendo vendedor: $e');
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chat['id'].toString(),
                      otherUserId: otherUserId,
                      servicioTitulo: servicioTitulo.isNotEmpty
                          ? servicioTitulo
                          : null,
                      servicioFotoUrl: foto,
                      servicioId: servicioId,
                      vendedorId: vendedorId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Avatar con sombra y gradiente
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: foto != null && foto.startsWith("http")
                            ? Image.network(
                                foto,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      kPrimary,
                                      kPrimary.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Contenido del chat
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatTime(chat['ultimo_mensaje_en']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (servicioTitulo.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 14,
                                  color: kPrimary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    servicioTitulo,
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (ultimoMensaje.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              ultimoMensaje,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Chevron
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: kPrimary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No se encontraron chats",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Intenta con otra búsqueda",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      } else if (diff.inDays == 1) {
        return "Ayer";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d";
      } else {
        return "${date.day}/${date.month}";
      }
    } catch (_) {
      return '';
    }
  }
}
