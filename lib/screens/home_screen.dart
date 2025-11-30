import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import './info_servicio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _servicios = [];
  bool _isLoading = true;
  String _sortOption = 'Más recientes'; // Opción de ordenamiento actual

  @override
  void initState() {
    super.initState();
    _loadServicios();
    // No hacemos initState async; llamamos a la función async sin await
    savePlayerId();
  }

  Future<void> _loadServicios() async {
    try {
      final response = await Supabase.instance.client
          .from('servicios')
          .select('id, titulo, descripcion, fotos, ubicacion')
          .eq('status', 'activa')
          .order('creado_en', ascending: false);

      setState(() {
        _servicios = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      _applySorting(); // Aplicar ordenamiento después de cargar
    } catch (e) {
      debugPrint('Error cargando servicios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshServicios() async {
    setState(() {
      _isLoading = true;
    });

    await _loadServicios();
  }

  // --------- Guardar Onesignal player id -----------
Future<void> savePlayerId() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // API nueva de OneSignal v5
    final String? playerId = OneSignal.User.pushSubscription.id;

    if (playerId == null || playerId.isEmpty) {
      debugPrint('OneSignal: playerId todavía no disponible');
      return;
    }

    await Supabase.instance.client
        .from('perfiles')
        .update({'onesignal_id': playerId})
        .eq('id', user.id);

    debugPrint('OneSignal: playerId guardado -> $playerId');
  } catch (e) {
    debugPrint('Error guardando playerId: $e');
  }
}


  void _applySorting() {
    setState(() {
      if (_sortOption == 'Más recientes') {
        // Ya viene ordenado por creado_en descendente
      } else if (_sortOption == 'Más antiguos') {
        _servicios = _servicios.reversed.toList();
      } else if (_sortOption == 'A-Z') {
        _servicios.sort(
          (a, b) => (a['titulo'] ?? '').toString().toLowerCase().compareTo(
            (b['titulo'] ?? '').toString().toLowerCase(),
          ),
        );
      } else if (_sortOption == 'Z-A') {
        _servicios.sort(
          (a, b) => (b['titulo'] ?? '').toString().toLowerCase().compareTo(
            (a['titulo'] ?? '').toString().toLowerCase(),
          ),
        );
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _buildSortOption('Más recientes'),
              _buildSortOption('Más antiguos'),
              _buildSortOption('A-Z'),
              _buildSortOption('Z-A'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String option) {
    final bool isSelected = _sortOption == option;
    return ListTile(
      leading: Radio<String>(
        value: option,
        groupValue: _sortOption,
        activeColor: const Color(0xFFF5501D),
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _sortOption = value;
            });
            _applySorting();
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        option,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _sortOption = option;
        });
        _applySorting();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda con botón de ordenar
            _buildSearchBar(),

            // Contenido scrolleable
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFF5501D),
                onRefresh: _refreshServicios,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBannerSection(),
                      const SizedBox(height: 24),
                      _buildServiciosSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (value) {
                  debugPrint('Buscar: $value');

                  if (value.trim().isEmpty) return;

                  Navigator.pushNamed(
                    context,
                    '/search',
                    arguments: value.trim(),
                  );
                  _searchController.clear();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de ordenar
          GestureDetector(
            onTap: _showSortOptions,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFB89968),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.swap_vert, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    final PageController controller = PageController();

    final List<Map<String, String>> banners = [
      {
        'title':
            'Explora una nueva dimensión de\noportunidades en tu área de interés.',
        'image':
            'https://images.unsplash.com/photo-1557683316-973673baf926?w=600',
      },
      {
        'title': '¿En serio alguien lee esto?',
        'image':
            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600',
      },
      {
        'title': 'Odio mi vida',
        'image':
            'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600',
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(banner['title']!, banner['image']!);
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: controller,
          count: banners.length,
          effect: WormEffect(
            dotHeight: 10,
            dotWidth: 10,
            activeDotColor: Colors.deepOrange,
            dotColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(String title, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image, size: 60, color: Colors.white),
                  ),
                );
              },
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiciosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Principal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid de servicios
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B35),
                    ),
                  ),
                ),
              )
            : _servicios.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    'No hay servicios disponibles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _servicios.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(_servicios[index]);
                  },
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> servicio) {
    final String titulo = servicio['titulo'] ?? 'Sin título';
    final List<dynamic> fotos = servicio['fotos'] ?? [];
    final String imageUrl = fotos.isNotEmpty ? fotos[0] : '';

    // Acortar título si es muy largo
    final String displayTitle = titulo.length > 25
        ? '${titulo.substring(0, 22)}...'
        : titulo;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalleServicioScreen(servicioId: servicio['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                color: const Color.fromARGB(0, 255, 195, 157).withOpacity(0.2),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            // Información del servicio
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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
    );
  }
}
