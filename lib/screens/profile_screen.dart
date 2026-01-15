import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:randimarket/screens/admin_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import 'tutorial_policies_screen.dart';
import 'info_servicio.dart';
import 'editar_cuenta.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>> _publicaciones = [];
  List<Map<String, dynamic>> _calificaciones = [];
  bool _isLoading = true;
  final authService = AuthService(Supabase.instance.client);
  final RatingService _ratingService = RatingService(Supabase.instance.client);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colores del tema
  final Color _primaryColor = const Color(0xFFF5501D);
  final Color _secondaryColor = const Color(0xFFFF6B35);
  final Color _accentColor = const Color(0xFFFFB088);
  final Color _darkText = const Color(0xFF1A1A1A);
  final Color _lightText = const Color(0xFF6B7280);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = widget.userId ?? authService.currentUser?.id;
      if (userId == null) return;

      final perfilResponse = await Supabase.instance.client
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();

      final publicacionesResponse = await Supabase.instance.client
          .from('servicios')
          .select()
          .eq('user_id', userId)
          .eq('status', 'activa')
          .order('creado_en', ascending: false);

      final calificacionesResponse = await Supabase.instance.client
          .from('calificaciones')
          .select(
            '*, perfiles!calificaciones_from_user_id_fkey(nombre, avatar_url)',
          )
          .eq('to_user_id', userId);

      setState(() {
        _perfil = perfilResponse;
        _publicaciones = List<Map<String, dynamic>>.from(publicacionesResponse);
        _calificaciones = List<Map<String, dynamic>>.from(
          calificacionesResponse,
        );
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.1),
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Cerrar Sesión?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E272E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu sesión se cerrará y tendrás que volver a ingresar tus credenciales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.blueGrey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      // --- PASO 1: CERRAR EL DIÁLOGO INMEDIATAMENTE ---
                      // Usamos el context del Navigator para quitar el cuadro de la vista
                      Navigator.pop(context);

                      try {
                        // --- PASO 2: EJECUTAR LÓGICA DE SALIDA ---
                        await authService.signOut();
                        await OneSignal.logout();

                        // --- PASO 3: REDIRECCIÓN FORZADA (OPCIONAL SI TU MAIN YA ESCUCHA EL AUTH) ---
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login', // Verifica que esta ruta esté en tu main.dart
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        debugPrint("Error al cerrar sesión: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'SÍ, CERRAR SESIÓN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mantener sesión activa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCalificar() {
    final currentUser = authService.currentUser;
    if (currentUser == null || _perfil == null) return;
    if (currentUser.id == _perfil!['id']) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DialogoCalificarUsuario(
        toUserId: _perfil!['id'],
        onCalificado: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('¡Calificación enviada exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          _loadProfileData();
        },
      ),
    );
  }

  void _mostrarTodasCalificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TodasCalificacionesBottomSheet(
        calificaciones: _calificaciones,
        ratingStats: _ratingService.calculateRatingStats(_calificaciones),
        onCalificar: _mostrarDialogoCalificar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cargando perfil...',
                style: TextStyle(
                  color: _lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isOwnProfile =
        widget.userId == null || widget.userId == authService.currentUser?.id;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: isOwnProfile
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: _darkText,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: _perfil == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error cargando perfil',
                    style: TextStyle(color: _lightText, fontSize: 16),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _buildProfileHeader(isOwnProfile),
                  const SizedBox(height: 20),
                  _buildSobreMiSection(),
                  const SizedBox(height: 20),
                  _buildCalificacionesSection(isOwnProfile),
                  const SizedBox(height: 20),
                  _buildPublicacionesSection(),
                  if (isOwnProfile) ...[
                    const SizedBox(height: 20),
                    _buildMasSection(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    final String nombre = _perfil?['nombre'] ?? 'Usuario';
    final String? avatarUrl = _perfil?['avatar_url'];
    final DateTime? creadoEn = _perfil?['creado_en'] != null
        ? DateTime.parse(_perfil!['creado_en'])
        : null;
    final String fechaCreacion = creadoEn != null
        ? DateFormat('dd MMM yyyy').format(creadoEn)
        : '00/00/0000';

    final double ratingAvg = (_perfil?['rating_avg'] ?? 0).toDouble();
    final int totalPublicaciones = _publicaciones.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _accentColor.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar con efecto brillante
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.3),
                      _secondaryColor.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(nombre),
                          )
                        : _buildDefaultAvatar(nombre),
                  ),
                ),
              ),
              if (isOwnProfile)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Nombre y verificación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 20, color: Colors.blue),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fecha de creación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _lightText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Miembro desde $fechaCreacion',
                  style: TextStyle(
                    color: _lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Estadísticas en cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: ratingAvg.toStringAsFixed(1),
                  label: '${_calificaciones.length} reseñas',
                  color: Colors.amber[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.inventory_2_rounded,
                  value: '$totalPublicaciones',
                  label: totalPublicaciones == 1 ? 'servicio' : 'servicios',
                  color: _primaryColor,
                ),
              ),
            ],
          ),

          if (isOwnProfile) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AjustesCuentaScreen(),
                    ),
                  );
                  if (resultado == true) {
                    _loadProfileData();
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text(
                  'Editar Perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: _primaryColor.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _lightText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String nombre) {
    return Container(
      color: _accentColor,
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
    final String bio = _perfil?['bio'] ?? '';

    if (bio.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.15),
                      _primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sobre mí',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: _lightText,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionesSection(bool isOwnProfile) {
    final double ratingAvg = (_perfil?['rating_avg'] ?? 0).toDouble();
    final Map<String, int> categoricalRatings = _getCategoricalRatings();
    final int totalCalificaciones = _calificaciones.length;
    final bool puedeCalificar =
        !isOwnProfile && authService.currentUser != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.15),
                      Colors.amber.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Calificaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const Spacer(),
              if (totalCalificaciones > 0)
                TextButton.icon(
                  onPressed: _mostrarTodasCalificaciones,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Ver todas'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (totalCalificaciones == 0)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      size: 56,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin calificaciones aún',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      puedeCalificar ? '¡Sé el primero en calificar!' : '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                // Rating promedio
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.15),
                        Colors.amber.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < ratingAvg.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalCalificaciones ${totalCalificaciones == 1 ? 'reseña' : 'reseñas'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _lightText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Busca esta parte dentro de _buildCalificacionesSection:
                // ...
                // Comentarios categóricos
                Expanded(
                  child: categoricalRatings.isEmpty
                      ? Center(
                          child: Text(
                            'Sin comentarios',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : Wrap(
                          // <--- Este widget es la clave
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment
                              .start, // Añade esto para asegurar el inicio
                          children: categoricalRatings.entries.take(3).map((
                            entry,
                          ) {
                            return Container(
                              // Si el texto es muy largo, puedes envolver el contenido en un Flexible
                              // o simplemente dejar que el Wrap lo mande a la siguiente línea.
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    10, // Bajé un poco el padding para ganar espacio
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Usamos ConstrainedBox para que el texto no empuje demasiado
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.3,
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            11, // Bajamos un punto la fuente
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Si es muy largo, pone "..."
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // ... resto de tu código del contador (el círculo naranja)
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ],

          if (puedeCalificar) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _mostrarDialogoCalificar,
                icon: const Icon(Icons.star_outline_rounded, size: 20),
                label: const Text(
                  'Calificar Usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublicacionesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.15),
                      _primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Publicaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_publicaciones.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_publicaciones.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin publicaciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _lightText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _publicaciones.length,
              itemBuilder: (context, index) =>
                  _buildPublicacionCard(_publicaciones[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildPublicacionCard(Map<String, dynamic> publicacion) {
    final String titulo = publicacion['titulo'] ?? 'Sin título';
    final List<dynamic> fotos = publicacion['fotos'] ?? [];
    final String imageUrl = fotos.isNotEmpty ? fotos[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalleServicioScreen(servicioId: publicacion['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
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
    final isAdmin = _perfil?['rol'] == 'admin';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.15),
                      Colors.grey.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.grey[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Más opciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildMasOption(
            Icons.school_outlined,
            'Tutorial para nuevos usuarios',
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
            Icons.post_add_outlined,
            'Tutorial para publicar servicios',
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
          _buildMasOption(Icons.policy_outlined, 'Políticas para usuarios', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TutorialPoliciesScreen(
                  type: TutorialPolicyType.politicasUsuarios,
                ),
              ),
            );
          }),
          _buildMasOption(
            Icons.description_outlined,
            'Políticas de publicación',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialPoliciesScreen(
                    type: TutorialPolicyType.politicasPublicacion,
                  ),
                ),
              );
            },
          ),

          if (isAdmin)
            _buildMasOption(
              Icons.admin_panel_settings_outlined,
              'Panel de administración',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanel()),
                );
              },
              color: Colors.purple,
            ),

          const Divider(height: 32),

          _buildMasOption(
            Icons.logout_rounded,
            'Cerrar sesión',
            _showLogoutDialog,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMasOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final optionColor = color ?? _primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: optionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: optionColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _darkText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet para mostrar todas las calificaciones
class _TodasCalificacionesBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> calificaciones;
  final Map<String, dynamic> ratingStats;
  final VoidCallback onCalificar;

  const _TodasCalificacionesBottomSheet({
    required this.calificaciones,
    required this.ratingStats,
    required this.onCalificar,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFF5501D);
    final Color darkText = const Color(0xFF1A1A1A);
    final Color lightText = const Color(0xFF6B7280);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todas las calificaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      Text(
                        '${ratingStats['total']} ${ratingStats['total'] == 1 ? 'reseña' : 'reseñas'}',
                        style: TextStyle(fontSize: 14, color: lightText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: calificaciones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin calificaciones aún',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: lightText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: calificaciones.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rating = calificaciones[index];
                      final user = rating['perfiles'];
                      final String nombre = user?['nombre'] ?? 'Usuario';
                      final String? avatarUrl = user?['avatar_url'];
                      final int estrellas = rating['estrellas'] ?? 0;
                      final String comentario =
                          rating['comentario_categorico'] ?? '';
                      final String fecha = _formatDate(rating['creado_en']);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child:
                                      avatarUrl != null && avatarUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < estrellas
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                if (fecha.isNotEmpty)
                                  Text(
                                    fecha,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lightText,
                                    ),
                                  ),
                              ],
                            ),
                            if (comentario.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  comentario,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return '';
      final dt = date is String ? DateTime.parse(date) : date as DateTime;
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// Diálogo para calificar usuario
class _DialogoCalificarUsuario extends StatefulWidget {
  final String toUserId;
  final VoidCallback onCalificado;

  const _DialogoCalificarUsuario({
    required this.toUserId,
    required this.onCalificado,
  });

  @override
  State<_DialogoCalificarUsuario> createState() =>
      __DialogoCalificarUsuarioState();
}

class __DialogoCalificarUsuarioState extends State<_DialogoCalificarUsuario> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RatingService _ratingService = RatingService(Supabase.instance.client);

  int _estrellas = 0;
  String? _comentarioSeleccionado;
  bool _cargandoServicios = true;
  bool _enviando = false;
  List<Map<String, dynamic>> _serviciosDisponibles = [];
  String? _servicioSeleccionadoId;

  final Color _primaryColor = const Color(0xFFF5501D);
  final Color _darkText = const Color(0xFF1A1A1A);
  final Color _lightText = const Color(0xFF6B7280);

  final List<String> _comentarios = [
    'Buen Servicio',
    'Excelente Comunicacion',
    'Lento para responder',
    'Comunicacion Desubicada o Grosera',
    'Poco Comprometido Nunca llego al acuerdo',
  ];

  @override
  void initState() {
    super.initState();
    _cargarServiciosCalificables();
  }

  Future<void> _cargarServiciosCalificables() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final servicios = await _supabase
          .from('servicios')
          .select()
          .eq('user_id', widget.toUserId)
          .eq('status', 'activa');

      final serviciosCalificables = <Map<String, dynamic>>[];

      for (final servicio in servicios) {
        final puedeCalificar = await _ratingService.canUserRate(
          fromUserId: currentUser.id,
          toUserId: widget.toUserId,
          serviceId: servicio['id'],
        );

        if (puedeCalificar) {
          serviciosCalificables.add(servicio);
        }
      }

      setState(() {
        _serviciosDisponibles = serviciosCalificables;
        _cargandoServicios = false;

        if (_serviciosDisponibles.isNotEmpty) {
          _servicioSeleccionadoId = _serviciosDisponibles.first['id'];
        }
      });
    } catch (e) {
      print('Error cargando servicios: $e');
      setState(() => _cargandoServicios = false);
    }
  }

  Future<void> _enviarCalificacion() async {
    if (_estrellas == 0 ||
        _comentarioSeleccionado == null ||
        _servicioSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Por favor completa todos los campos')),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');

      await _ratingService.rateUser(
        fromUserId: currentUser.id,
        toUserId: widget.toUserId,
        serviceId: _servicioSeleccionadoId!,
        stars: _estrellas,
        categoricalFeedback: _comentarioSeleccionado!,
      );

      widget.onCalificado();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calificar Usuario',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_cargandoServicios)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: _primaryColor),
                      ),
                    )
                  else if (_serviciosDisponibles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes servicios disponibles para calificar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _darkText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Requisitos:\n• Mínimo 5 mensajes en el chat\n• O una cita aceptada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _lightText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      'Selecciona el servicio',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._serviciosDisponibles.map((servicio) {
                      final isSelected =
                          _servicioSeleccionadoId == servicio['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(
                              () => _servicioSeleccionadoId = servicio['id'],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _primaryColor.withOpacity(0.1)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryColor
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primaryColor
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          servicio['titulo'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _darkText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          servicio['descripcion'].length > 50
                                              ? '${servicio['descripcion'].substring(0, 50)}...'
                                              : servicio['descripcion'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _lightText,
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
                      );
                    }).toList(),

                    const SizedBox(height: 32),

                    Text(
                      '¿Cuántas estrellas?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () =>
                                setState(() => _estrellas = index + 1),
                            icon: Icon(
                              index < _estrellas
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 42,
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Comentario (selecciona uno)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _comentarios.map((comentario) {
                        final isSelected =
                            _comentarioSeleccionado == comentario;
                        return InkWell(
                          onTap: () => setState(
                            () => _comentarioSeleccionado = comentario,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              comentario,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _darkText,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: _darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_estrellas > 0 &&
                              _comentarioSeleccionado != null &&
                              _servicioSeleccionadoId != null &&
                              !_enviando)
                          ? _enviarCalificacion
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Enviar Calificación',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
