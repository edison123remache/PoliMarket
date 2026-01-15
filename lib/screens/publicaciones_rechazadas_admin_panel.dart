import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicacionesRechazadasAdminScreen extends StatefulWidget {
  const PublicacionesRechazadasAdminScreen({super.key});

  @override
  State<PublicacionesRechazadasAdminScreen> createState() =>
      _PublicacionesRechazadasAdminScreenState();
}

class _PublicacionesRechazadasAdminScreenState
    extends State<PublicacionesRechazadasAdminScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _rechazadas = [];
  late AnimationController _animationController;

  // --- PALETA DE COLORES MEJORADA ---
  final Color _brandOrange = const Color(0xFFFF6B00);
  final Color _errorRed = const Color(0xFFE53935);
  final Color _bgLight = const Color(0xFFFAFAFA);
  final Color _textDark = const Color(0xFF1A1A1A);
  final Color _cardWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _cargarRechazadas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarRechazadas() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('servicios')
          .select('''
        id,
        titulo,
        descripcion,
        motivo_rechazo,
        fotos,
        creado_en,
        perfiles:perfiles(
          nombre,
          email,
          avatar_url
        )
      ''')
          .eq('status', 'rechazada')
          .order('creado_en', ascending: false);

      setState(() {
        _rechazadas = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });

      if (_rechazadas.isEmpty) {
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('ERROR SUPABASE: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al cargar publicaciones rechazadas'),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- UI WIDGETS MEJORADOS ---

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 80,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Todo en Orden!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay publicaciones rechazadas',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'El historial está limpio',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar Mejorado
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: _cardWhite,
            surfaceTintColor: _cardWhite,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      color: _errorRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rechazadas',
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  color: _cardWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _loading ? null : _cargarRechazadas,
                  icon: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _brandOrange,
                          ),
                        )
                      : Icon(Icons.refresh_rounded, color: _brandOrange),
                  tooltip: 'Actualizar',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Contador de rechazadas
          if (!_loading && _rechazadas.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _errorRed.withOpacity(0.1),
                      _errorRed.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorRed.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _errorRed.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: _errorRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_rechazadas.length} ${_rechazadas.length == 1 ? 'publicación rechazada' : 'publicaciones rechazadas'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _errorRed,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Revisa los motivos de rechazo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Lista de contenido
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : _rechazadas.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final pub = _rechazadas[index];
                      return _buildCard(pub, index);
                    }, childCount: _rechazadas.length),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> pub, int index) {
    final perfil = pub['perfiles'];
    final fotos = (pub['fotos'] is List) ? pub['fotos'] as List : [];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _errorRed.withOpacity(0.15), width: 2),
          boxShadow: [
            BoxShadow(
              color: _errorRed.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _mostrarDetalle(pub),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con Avatar y Badge
                  Row(
                    children: [
                      // Avatar con borde rojo
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _errorRed.withOpacity(0.3),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _errorRed.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: _bgLight,
                          backgroundImage: perfil?['avatar_url'] != null
                              ? NetworkImage(perfil['avatar_url'])
                              : null,
                          child: perfil?['avatar_url'] == null
                              ? Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pub['titulo'] ?? 'Sin título',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _textDark,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              perfil?['nombre'] ?? 'Usuario',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de rechazado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _errorRed,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _errorRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rechazada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Preview de fotos si existen
                  if (fotos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length > 3 ? 3 : fotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                fotos[idx],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (idx == 2 && fotos.length > 3)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${fotos.length - 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Motivo de rechazo mejorado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _errorRed.withOpacity(0.08),
                          _errorRed.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _errorRed.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _errorRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.report_problem_outlined,
                            color: _errorRed,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MOTIVO DE RECHAZO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _errorRed.withOpacity(0.7),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pub['motivo_rechazo'] ??
                                    'Sin motivo registrado',
                                style: TextStyle(
                                  color: _darkenColor(_errorRed, 0.1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Footer con fecha y flecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatearFecha(pub['creado_en']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _brandOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: _brandOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'Fecha desconocida';
    try {
      final date = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoy';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return fecha.substring(0, 10);
    }
  }

  void _mostrarDetalle(Map<String, dynamic> pub) {
    final perfil = pub['perfiles'];
    final fotos = (pub['fotos'] is List) ? pub['fotos'] as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Header del modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_errorRed, _darkenColor(_errorRed, 0.1)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _errorRed.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'RECHAZADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _bgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, size: 22),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Título grande
                  Text(
                    pub['titulo'] ?? 'Sin título',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      letterSpacing: -1,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 28),

                  // Motivo del rechazo destacado
                  _buildSectionTitle(
                    'MOTIVO DEL RECHAZO',
                    Icons.report_problem_rounded,
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _errorRed.withOpacity(0.12),
                          _errorRed.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _errorRed.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      pub['motivo_rechazo'] ?? 'No se especificó un motivo.',
                      style: TextStyle(
                        color: _darkenColor(_errorRed, 0.15),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Descripción original
                  _buildSectionTitle(
                    'DESCRIPCIÓN ORIGINAL',
                    Icons.description_outlined,
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      pub['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Fotos adjuntas
                  if (fotos.isNotEmpty) ...[
                    SizedBox(height: 32),
                    _buildSectionTitle(
                      'FOTOS ADJUNTAS (${fotos.length})',
                      Icons.photo_library_outlined,
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12),
                        itemBuilder: (_, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.network(
                              fotos[index],
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  Divider(color: Colors.grey[200], thickness: 1),

                  SizedBox(height: 24),

                  // Información del autor mejorada
                  _buildSectionTitle(
                    'AUTOR DE LA PUBLICACIÓN',
                    Icons.person_outline_rounded,
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _brandOrange.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: perfil?['avatar_url'] != null
                                ? NetworkImage(perfil['avatar_url'])
                                : null,
                            child: perfil?['avatar_url'] == null
                                ? Icon(Icons.person, size: 28)
                                : null,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfil?['nombre'] ?? 'Usuario',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                perfil?['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
