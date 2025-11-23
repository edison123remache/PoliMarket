// /lib/screens/chat_list_screen.dart
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
  
  int _selectedIndex = 3; // Mensajes está activo

  // NAVEGACIÓN DE LA BARRA INFERIOR
  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
      case 1:
        debugPrint('Ir a Agenda');
        break;
      case 2:
        Navigator.of(context).pushNamed('/SubirServ');
        break;
      case 3:
        // Ya estás aquí
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
      // FONDO CON DEGRADADO (igual que en SearchScreen y Home)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0EC),
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Título como en Home
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Mensajes",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de chats
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _chatService.getUserChats(user!.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final chats = snap.data ?? [];
                    if (chats.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aún no tienes mensajes', style: TextStyle(fontSize: 16)),
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
                        final ultimo = chat['ultimo_mensaje'] ?? '';
                        final ts = chat['ultimo_mensaje_en'];

                        String timeLabel = '';
                        try {
                          if (ts != null) {
                            final dt = DateTime.parse(ts).toLocal();
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final date = DateTime(dt.year, dt.month, dt.day);

                            if (date == today) {
                              timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            } else if (date == today.subtract(const Duration(days: 1))) {
                              timeLabel = 'Ayer';
                            } else {
                              timeLabel = '${dt.day}/${dt.month}';
                            }
                          }
                        } catch (_) {}

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _chatService.getProfile(otherUserId),
                          builder: (context, pSnap) {
                            final profile = pSnap.data;
                            final name = profile?['nombre'] ?? 'Usuario';
                            final avatar = profile?['avatar_url'];

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundImage: (avatar != null && avatar.isNotEmpty)
                                    ? NetworkImage(avatar)
                                    : null,
                                child: (avatar == null || avatar.isEmpty)
                                    ? const Icon(Icons.person, size: 26)
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                ultimo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Text(
                                timeLabel,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatId: chat['id'],
                                      otherUserId: otherUserId,
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

      // BARRA DE NAVEGACIÓN INFERIOR (IGUAL QUE EN HOME Y CHAT)
      bottomNavigationBar: Container(
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
      ),
    );
  }

  // Ítems de la barra
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón central +
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
}