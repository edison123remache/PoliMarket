import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'tutorial_policies_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Si es null, muestra el perfil del usuario actual

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>> _publicaciones = [];
  List<Map<String, dynamic>> _calificaciones = [];
  bool _isLoading = true;
  final authService = AuthService(Supabase.instance.client);

  int _selectedIndex = 4; // Índice para el elemento "Perfil" en el navbar

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = widget.userId ?? authService.currentUser?.id;
      if (userId == null) return;

      // Cargar perfil
      final perfilResponse = await Supabase.instance.client
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();

      // Cargar publicaciones del usuario
      final publicacionesResponse = await Supabase.instance.client
          .from('servicios')
          .select()
          .eq('user_id', userId)
          .eq('status', 'activa')
          .order('creado_en', ascending: false);

      // Cargar calificaciones
      final calificacionesResponse = await Supabase.instance.client
          .from('calificaciones')
          .select()
          .eq('to_user_id', userId);

      setState(() {
        _perfil = perfilResponse;
        _publicaciones = List<Map<String, dynamic>>.from(publicacionesResponse);
        _calificaciones = List<Map<String, dynamic>>.from(
          calificacionesResponse,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getCategoricalRatings() {
    Map<String, int> ratings = {};
    for (var cal in _calificaciones) {
      String categoria = cal['comentario_categorico'] ?? '';
      if (categoria.isNotEmpty) {
        ratings[categoria] = (ratings[categoria] ?? 0) + 1;
      }
    }
    return ratings;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              authService.signOut();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/');
        print('Navegar a Home');
        break;
      case 1:
        // Navegar a Calendario
        print('Navegar a Calendario');
        break;
      case 2:
        // Navegar a Añadir Publicación
        Navigator.of(context).pushNamed('/SubirServ');
        print('Navegar a Añadir Publicación');
        break;
      case 3:
        // Navegar a Mensajes
        print('Navegar a Mensajes');
        break;
      case 4:
        // Ya estamos en Perfil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        ),
      );
    }

    if (_perfil == null) {
      return const Scaffold(body: Center(child: Text('Error cargando perfil')));
    }

    final bool isOwnProfile =
        widget.userId == null || widget.userId == authService.currentUser?.id;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Fondo transparente para el degradado
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0EC), // Color superior del degradado (más claro)
              Color(
                0xFFF5F5F5,
              ), // Color inferior del degradado (más oscuro/neutro)
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con foto de perfil
              _buildProfileHeader(),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección "Sobre Mi"
                    _buildSobreMiSection(),

                    const SizedBox(height: 24),

                    // Sección de Calificaciones
                    _buildCalificacionesSection(),

                    const SizedBox(height: 24),

                    // Sección de Publicaciones
                    _buildPublicacionesSection(),

                    if (isOwnProfile) ...[
                      const SizedBox(height: 24),
                      // Sección "Más"
                      _buildMasSection(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 80), // Espacio para el BottomNavBar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileHeader() {
    final String nombre = _perfil?['nombre'] ?? 'Usuario';
    final String? avatarUrl = _perfil?['avatar_url'];
    final DateTime? creadoEn = _perfil?['creado_en'] != null
        ? DateTime.parse(_perfil!['creado_en'])
        : null;
    final String fechaCreacion = creadoEn != null
        ? DateFormat('dd/MM/yyyy').format(creadoEn)
        : '00/00/0000';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Foto de perfil circular
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF6B35), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(nombre);
                          },
                        )
                      : _buildDefaultAvatar(nombre),
                ),
              ),

              const SizedBox(height: 16),

              // Nombre de usuario
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),

              const SizedBox(height: 8),

              // Fecha de creación
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Usuario desde: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    fechaCreacion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3436),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Línea naranja separadora
              Container(
                height: 2,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String nombre) {
    return Container(
      color: const Color(0xFFFFB088),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSobreMiSection() {
    final String bio = _perfil?['bio'] ?? 'Sin descripción';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre Mi:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio == 'Sin descripción' ? 'Inserta Descripcion Aqui' : bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionesSection() {
    final double ratingAvg = (_perfil?['rating_avg'] ?? 0).toDouble();
    final Map<String, int> categoricalRatings = _getCategoricalRatings();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Calificaciones:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(width: 12),
              // Estrellas
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < ratingAvg.round() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF6B35),
                    size: 20,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                ratingAvg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Comentarios categóricos (scroll horizontal)
          if (categoricalRatings.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoricalRatings.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = categoricalRatings.entries.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB088).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF6B35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin calificaciones aún',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPublicacionesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Publicaciones:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 16),

          if (_publicaciones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin publicaciones',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _publicaciones.length,
              itemBuilder: (context, index) {
                return _buildPublicacionCard(_publicaciones[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPublicacionCard(Map<String, dynamic> publicacion) {
    final String titulo = publicacion['titulo'] ?? 'Sin título';
    final List<dynamic> fotos = publicacion['fotos'] ?? [];
    final String imageUrl = fotos.isNotEmpty ? fotos[0] : '';
    final String displayTitle = titulo.length > 20
        ? '${titulo.substring(0, 17)}...'
        : titulo;

    return GestureDetector(
      onTap: () {
        print('Publicación seleccionada: ${publicacion['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFFFB088).withOpacity(0.2),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.shopping_bag,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Más:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          _buildMasOption(Icons.settings, 'Ajustes de Cuenta', () {
            print('Navegar a Ajustes de Cuenta');
            // PENDIENTE: Implementar pantalla de ajustes
          }),
          _buildMasOption(
            Icons.school,
            'Tutorial de ayuda para usuarios nuevos',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialPoliciesScreen(
                    type: TutorialPolicyType.tutorialNuevos,
                  ),
                ),
              );
            },
          ),
          _buildMasOption(
            Icons.post_add,
            'Tutorial de ayuda para publicar tu servicio',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialPoliciesScreen(
                    type: TutorialPolicyType.tutorialPublicar,
                  ),
                ),
              );
            },
          ),
          _buildMasOption(Icons.policy, 'Políticas para usuarios', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TutorialPoliciesScreen(
                  type: TutorialPolicyType.politicasUsuarios,
                ),
              ),
            );
          }),
          _buildMasOption(Icons.description, 'Políticas de Publicación', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TutorialPoliciesScreen(
                  type: TutorialPolicyType.politicasPublicacion,
                ),
              ),
            );
          }),
          _buildMasOption(
            Icons.logout,
            'Cerrar Sesión',
            _showLogoutDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMasOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFFFFB088).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFFFF6B35),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : const Color(0xFF2D3436),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
}
