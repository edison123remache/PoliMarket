import 'package:flutter/material.dart';
import 'package:randimarket/screens/chat_list_screen.dart';
import 'package:randimarket/screens/home_screen.dart';
import 'package:randimarket/screens/profile_screen.dart';
import 'package:randimarket/screens/cita_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔴 AÑADIDO

class MainScreen extends StatefulWidget {
  final String? path;

  const MainScreen({super.key, this.path});

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  final _supabase = Supabase.instance.client; // 🔴 AÑADIDO
  late final Stream<int> _unreadCountStream; // 🔴 AÑADIDO

  final items = [
    {
      'icon': Icons.home,
      'label': 'Inicio',
      'path': '/home',
      'content': HomeScreen(),
    },
    {
      'icon': Icons.calendar_today,
      'label': 'Agenda',
      'path': '/citaList',
      'content': AgendaScreen(),
    },
    {
      'icon': Icons.message,
      'label': 'Mensajes',
      'path': '/chats',
      'content': ChatListScreen(),
    },
    {
      'icon': Icons.person,
      'label': 'Perfil',
      'path': '/profile',
      'content': ProfileScreen(),
    },
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // 🔴 STREAM PARA MENSAJES PENDIENTES
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      _unreadCountStream = _supabase
          .from('mensajes') // 👈 TABLA DE MENSAJES, NO chats
          .stream(primaryKey: ['id'])
          .map((rows) {
            int count = 0;

            for (final msg in rows) {
              final esParaMi = msg['receptor_id'] == userId;
              final noLeido = msg['leido'] == false;

              if (esParaMi && noLeido) {
                count++;
              }
            }

            return count;
          });
    } else {
      _unreadCountStream = Stream.value(0);
    }

    if (widget.path == null) return;

    final index = items.indexWhere((i) => i['path'] == widget.path);

    if (index != -1) {
      currentIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: items[currentIndex]['content'] as Widget,
      ),
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
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          height: 68.0,
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...items.sublist(0, items.length ~/ 2).map(buildItem),

              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/SubirServ');
                },
                style: ButtonStyle(
                  elevation: WidgetStateProperty.all(4.0),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  minimumSize: WidgetStateProperty.all(const Size(52.0, 52.0)),
                  backgroundColor: WidgetStateProperty.all(
                    const Color(0xFFF5501D),
                  ),
                  shadowColor: WidgetStateProperty.all(
                    const Color(0xFFF5501D).withOpacity(1),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),

              ...items.sublist(items.length ~/ 2).map(buildItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(Map<String, Object> item) {
    final selected = items[currentIndex] == item;
    final isMessages = item['label'] == 'Mensajes'; // 🔴 AÑADIDO

    return Container(
      constraints: const BoxConstraints(minWidth: 68.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(100.0),
        onTap: () {
          if (!mounted) return;
          setState(() => currentIndex = items.indexOf(item));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4.0,
          children: [
            if (isMessages)
              StreamBuilder<int>(
                stream: _unreadCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: selected
                            ? const Color(0xFFF5501D)
                            : Colors.grey.shade400,
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2,
                          right: -6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            else
              Icon(
                item['icon'] as IconData,
                color: selected
                    ? const Color(0xFFF5501D)
                    : Colors.grey.shade400,
              ),
            Text(
              item['label'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: selected
                    ? const Color(0xFFF5501D)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
