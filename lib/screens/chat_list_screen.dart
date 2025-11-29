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

  int _selectedIndex = 3; // Mensajes activo

  final Map<String, Map<String, dynamic>?> _profileCache = {};

  Future<Map<String, dynamic>?> _getProfileCached(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }
    final profile = await _chatService.getProfile(userId);
    _profileCache[userId] = profile;
    return profile;
  }

  void _onNavBarTap(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/');
        break;
      case 1:
        debugPrint('/Agenda');
        break;
      case 2:
        Navigator.of(context).pushNamed('/SubirServ');
        break;
      case 3:
        break;
      case 4:
        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0EC), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    const Text(
                      "Bandeja de Entrada",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.subscribeToUserChats(user!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data!;

                    if (chats.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aún no tienes mensajes'),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
itemBuilder: (context, i) {
  final chat = chats[i];

  final otherUserId = chat['user1_id'] == user!.id
      ? chat['user2_id']
      : chat['user1_id'];

  final ultimoMensaje = (chat['ultimo_mensaje'] ?? '').toString();
  final ultimoMensajeEn = chat['ultimo_mensaje_en'] as String?;
  final servicioTitulo = chat['servicio_titulo']?.toString() ?? '';
  final servicioFotoUrl = chat['servicio_foto_url']?.toString();
  final servicioId = chat['service_id']?.toString();

  return FutureBuilder<Map<String, dynamic>?>(
    future: _getProfileCached(otherUserId),
    builder: (context, profileSnap) {
      final profile = profileSnap.data;
      final nombreUsuario = profile?['nombre'] ?? 'Usuario';

      return ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: servicioFotoUrl != null &&
                  servicioFotoUrl.startsWith("http")
              ? Image.network(
                  servicioFotoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_outlined),
                ),
        ),
        title: Text(
          "$nombreUsuario · $servicioTitulo",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: ultimoMensaje.isNotEmpty
            ? Text(
                ultimoMensaje,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(_formatLastMessageTime(ultimoMensajeEn)),
        onTap: () async {
          // ✅ Obtener vendedor_id del servicio
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
                servicioTitulo: servicioTitulo.isNotEmpty ? servicioTitulo : null,
                servicioFotoUrl: servicioFotoUrl,
                servicioId: servicioId,
                vendedorId: vendedorId, // ✅ PASADO
              ),
            ),
          );
        },
      );
    },
  );
},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ BARRA DE NAVEGACIÓN EXACTA A HOME
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavBarItem(Icons.home, 'Home', 0),
              _buildNavBarItem(Icons.calendar_today, 'Agenda', 1),
              _buildAddButton(),
              _buildNavBarItem(Icons.message, 'Mensajes', 3),
              _buildNavBarItem(Icons.person, 'Perfil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavBarTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF5501D) : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFFF5501D) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () => _onNavBarTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF5501D),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5501D).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  String _formatLastMessageTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}