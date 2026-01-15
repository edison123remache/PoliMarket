import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
// Asegúrate de que este import sea correcto según la estructura de tu proyecto
import './info_servicio.dart';

// 1. Definimos un Enum para las opciones de ordenamiento para mayor claridad
enum SortOption { recent, oldest, aZ, zA }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController(
    viewportFraction: 0.92,
  );
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _serviciosFiltrados = [];
  bool _isLoading = true;
  String _userName = 'Usuario';
  String? _avatarUrl;
  Timer? _timer;
  int _currentPage = 0;
  double _scrollOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 2. Nueva variable de estado para controlar la opción de ordenamiento actual
  SortOption _currentSortOption = SortOption.recent;

  @override
  void initState() {
    super.initState();
    _initData();
    _startAutoPlay();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _initData() async {
    await _loadUserInfo();
    await _loadServicios();
    _savePlayerId();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('perfiles')
          .select('nombre, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _userName = response['nombre'] ?? 'Usuario';
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  Future<void> _loadServicios() async {
    try {
      final response = await Supabase.instance.client
          .from('servicios')
          .select('id, titulo, descripcion, fotos, ubicacion, creado_en')
          .eq('status', 'activa')
          // Cargamos inicialmente por más reciente, coincide con _currentSortOption default
          .order('creado_en', ascending: false);

      if (mounted) {
        setState(() {
          _servicios = List<Map<String, dynamic>>.from(response);
          // Aplicamos el filtro inicial (que incluye el ordenamiento)
          _updateFilteredList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlayerId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) await OneSignal.login(user.id);
  }

  bool _isRecent(String? dateStr) {
    if (dateStr == null) return false;
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    return diff.inHours <= 24;
  }

  // 3. Función Principal para filtrar y ordenar al mismo tiempo
  // Esta función reemplaza a la antigua _filtrarServicios
  void _updateFilteredList() {
    List<Map<String, dynamic>> tempResults = List.from(_servicios);

    // A. Aplicar Filtro de Búsqueda
    String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempResults = tempResults.where((servicio) {
        final titulo = servicio['titulo']?.toString().toLowerCase() ?? '';
        final descripcion =
            servicio['descripcion']?.toString().toLowerCase() ?? '';
        final ubicacion = servicio['ubicacion']?.toString().toLowerCase() ?? '';

        return titulo.contains(query) ||
            descripcion.contains(query) ||
            ubicacion.contains(query);
      }).toList();
    }

    // B. Aplicar Ordenamiento
    switch (_currentSortOption) {
      case SortOption.recent:
        tempResults.sort(
          (a, b) => (b['creado_en'] ?? '').compareTo(a['creado_en'] ?? ''),
        ); // Descendente
        break;
      case SortOption.oldest:
        tempResults.sort(
          (a, b) => (a['creado_en'] ?? '').compareTo(b['creado_en'] ?? ''),
        ); // Ascendente
        break;
      case SortOption.aZ:
        tempResults.sort(
          (a, b) => (a['titulo'] ?? '').toString().toLowerCase().compareTo(
            (b['titulo'] ?? '').toString().toLowerCase(),
          ),
        );
        break;
      case SortOption.zA:
        tempResults.sort(
          (a, b) => (b['titulo'] ?? '').toString().toLowerCase().compareTo(
            (a['titulo'] ?? '').toString().toLowerCase(),
          ),
        );
        break;
    }

    // C. Actualizar el estado
    setState(() {
      _serviciosFiltrados = tempResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          // Fondo decorativo con parallax
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -_scrollOffset * 0.5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.03),
                      const Color(0xFFFF8E53).withOpacity(0.02),
                      Colors.white.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Círculos decorativos con efecto parallax
          Positioned(
            top: -100 - _scrollOffset * 0.3,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150 - _scrollOffset * 0.2,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8E53).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFFFF6B35),
              onRefresh: _loadServicios,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildModernHeader(),
                    _buildSearchAndFilterBox(), // Widget actualizado
                    _buildBannerSection(),
                    _buildSectionTitle("Servicios Destacados"),
                    _isLoading ? _buildLoader() : _buildGrid(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    // ... (Código del header sin cambios)
    final headerOpacity = (1.0 - (_scrollOffset / 100)).clamp(0.0, 1.0);

    return SliverToBoxAdapter(
      child: Opacity(
        opacity: headerOpacity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Hola, ${_userName.split(' ')[0]}! 👋",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                        letterSpacing: -1.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B35).withOpacity(0.1),
                            const Color(0xFFFF8E53).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Encuentra lo que buscas hoy ✨",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildProfileAvatar(),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildProfileAvatar() {
  return Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey[100],
        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null,
        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
            : null,
      ),
    ),
  );
}

  // 4. Widget de Búsqueda y Filtro Actualizado
  Widget _buildSearchAndFilterBox() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Barra de búsqueda (Expanded)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  // Usamos la nueva función unificada
                  onChanged: (_) => _updateFilteredList(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: "Buscar servicios...",
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _updateFilteredList();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botón de Filtro/Ordenamiento Profesional
            GestureDetector(
              onTap: _showSortOptionsModal,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded, // Icono de filtro/ajustes
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Nueva función para mostrar el Modal Bottom Sheet con diseño profesional
  void _showSortOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Ordenar por",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Opciones de ordenamiento personalizadas
              _buildSortOptionItem(
                "Más recientes",
                SortOption.recent,
                Icons.access_time_filled_rounded,
              ),
              _buildSortOptionItem(
                "Más antiguos",
                SortOption.oldest,
                Icons.history_rounded,
              ),
              _buildSortOptionItem(
                "Alfabéticamente (A-Z)",
                SortOption.aZ,
                Icons.text_increase_rounded,
              ),
              _buildSortOptionItem(
                "Alfabéticamente (Z-A)",
                SortOption.zA,
                Icons.text_decrease_rounded,
              ),
              // Nota: No incluí "Mayor/Menor calificados" porque tu consulta a
              // Supabase no trae un campo de calificación actualmente.
            ],
          ),
        );
      },
    );
  }

  // Widget auxiliar para construir cada opción del modal
  Widget _buildSortOptionItem(
    String title,
    SortOption option,
    IconData iconData,
  ) {
    final bool isSelected = _currentSortOption == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSortOption = option;
          _updateFilteredList(); // Aplicar el nuevo orden
        });
        Navigator.pop(context); // Cerrar el modal
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              iconData,
              color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[500],
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF6B35),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

 // 🔥 SOLUCIÓN AL OVERFLOW EN EL BANNER

Widget _buildBannerSection() {
  final List<Map<String, String>> banners = [
    {
      'title': 'Explora nuevas\noportunidades',
      'subtitle': 'Conecta con servicios de calidad',
      'image':
          'https://images.unsplash.com/photo-1557683316-973673baf926?w=800',
    },
    {
      'title': 'Apoya emprendimientos\nlocales',
      'subtitle': 'De la comunidad politécnica',
      'image':
          'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
    },
    {
      'title': 'Encuentra lo que\nnecesitas',
      'subtitle': 'Todo en un solo lugar',
      'image':
          'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
    },
  ];

  return SliverToBoxAdapter(
    child: Column(
      children: [
        SizedBox(
          height: 200, // 🔥 Reducido de 210 a 200
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (int index) =>
                setState(() => _currentPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final scale = _currentPage == index ? 1.0 : 0.92;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: scale),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            // Imagen de fondo
                            Positioned.fill(
                              child: Image.network(
                                banners[index]['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Gradiente overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 🔥 CONTENIDO AJUSTADO
                            Padding(
                              padding: const EdgeInsets.all(22), // 🔥 Reducido de 28 a 22
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, // 🔥 Reducido de 12 a 10
                                      vertical: 5, // 🔥 Reducido de 6 a 5
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      'DESTACADO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9, // 🔥 Reducido de 10 a 9
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10), // 🔥 Reducido de 12 a 10
                                  Text(
                                    banners[index]['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 23, // 🔥 Reducido de 26 a 23
                                      height: 1.1, // 🔥 Reducido de 1.2 a 1.1
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6), // 🔥 Reducido de 8 a 6
                                  Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B35),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          banners[index]['subtitle']!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontSize: 13, // 🔥 Reducido de 14 a 13
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1, // 🔥 NUEVO: Limitar a 1 línea
                                          overflow: TextOverflow.ellipsis, // 🔥 NUEVO
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
        ),
        const SizedBox(height: 18),
        SmoothPageIndicator(
          controller: _bannerController,
          count: banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 4,
            spacing: 6,
            activeDotColor: const Color(0xFFFF6B35),
            dotColor: Colors.grey.withOpacity(0.3),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFFFF6B35),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando servicios...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_serviciosFiltrados.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchController.text.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.inbox_rounded,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay servicios disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Sé el primero en publicar',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: _buildServiceCard(_serviciosFiltrados[index]),
                ),
              );
            },
          );
        }, childCount: _serviciosFiltrados.length),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
    final List fotos = item['fotos'] ?? [];
    final bool isNew = _isRecent(item['creado_en']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleServicioScreen(servicioId: item['id']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Imagen principal
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: Image.network(
                        fotos.isNotEmpty
                            ? fotos[0]
                            : 'https://via.placeholder.com/300',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Gradiente overlay sutil
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge NUEVO
                  if (isNew)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "NUEVO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Información del servicio
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['titulo'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B35).withOpacity(0.1),
                              const Color(0xFFFF8E53).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['ubicacion'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
