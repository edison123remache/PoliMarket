import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:llama_market/screens/info_servicio.dart'; // Verifica esta ruta

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Variables de estado
  Future<List<Map<String, dynamic>>>? loadDataFuture;
  String searchQuery = '';
  String _sortOption = 'Más recientes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialQuery =
          (ModalRoute.of(context)?.settings.arguments as String?)?.trim() ?? '';

      setState(() {
        searchQuery = initialQuery;
        _searchController.text = initialQuery;
        loadDataFuture = loadData(initialQuery);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE RECARGA (REFRESH) ---
  Future<void> _handleRefresh() async {
    setState(() {
      // Recargamos la data usando el texto actual
      loadDataFuture = loadData(searchQuery);
    });
    await loadDataFuture;
  }

  // --- LÓGICA DE BÚSQUEDA ---
  void _applySearchOrSort() {
    setState(() {
      loadDataFuture = loadData(searchQuery);
    });
  }

  void _handleSortTap(String option) {
    Navigator.pop(context);

    if (option == 'Mayor calificados') {
      Navigator.pushNamed(context, '/ranking-servicios', arguments: 'best');
      return;
    }

    if (option == 'Menor calificados') {
      Navigator.pushNamed(context, '/ranking-servicios', arguments: 'worst');
      return;
    }

    // 👉 SI NO, ES ORDEN NORMAL
    setState(() => _sortOption = option);
    _applySearchOrSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mismo fondo que tu Home
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER (Fijo, no scrollea) ---
            _buildHeader(),

            // --- 2. RESULTADOS (Con RefreshIndicator) ---
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFF5501D), // Tu color naranja
                backgroundColor: Colors.white,
                onRefresh: _handleRefresh,
                child: loadDataFuture == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: loadDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // Si no hay datos, mostramos mensaje (envuelto en ListView para que funcione el refresh)
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                ),
                                _buildEmptyState(),
                              ],
                            );
                          }

                          final servicios = snapshot.data!;

                          // Si hay datos, mostramos la Grilla
                          return GridView.builder(
                            // Esta física es vital para que el Refresh funcione siempre
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.78,
                                ),
                            itemCount: servicios.length,
                            itemBuilder: (context, index) {
                              return buildServiceCard(servicios[index]);
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE UI ---

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5), // Color de fondo para que se funda
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Flecha, Barra, Botón Filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 20, 5),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            searchQuery = value.trim();
                          });
                          _applySearchOrSort();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB89968),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Título de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resultados de Búsqueda:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"$searchQuery"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No se encontraron resultados",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            "Intenta con otra palabra",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // --- MODAL DE ORDENAR ---
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
              _buildSortOption('Mayor calificados'),
              _buildSortOption('Menor calificados'),
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
        onChanged: (_) => _handleSortTap(option),
      ),
      title: Text(
        option,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () => _handleSortTap(option),
    );
  }

  // --- SUPABASE DATA (Corregido con dynamic para evitar error de tipo) ---
  Future<List<Map<String, dynamic>>> loadData(String query) async {
    final supabase = Supabase.instance.client;
    final pattern = '%${query.trim()}%';

    // Usamos 'dynamic' para evitar el conflicto de tipos entre FilterBuilder y TransformBuilder
    dynamic queryBuilder = supabase
        .from('servicios')
        .select('*, perfiles(rating_avg)')
        .ilike('titulo', pattern)
        .eq('status', 'activa');

    switch (_sortOption) {
      case 'Más antiguos':
        queryBuilder = queryBuilder.order('creado_en', ascending: true);
        break;

      case 'A-Z':
        queryBuilder = queryBuilder.order('titulo', ascending: true);
        break;

      case 'Z-A':
        queryBuilder = queryBuilder.order('titulo', ascending: false);
        break;

      case 'Mejor calificados':
        queryBuilder = queryBuilder.order(
          'perfiles.rating_avg',
          ascending: false,
        );
        break;

      case 'Peor calificados':
        queryBuilder = queryBuilder.order(
          'perfiles.rating_avg',
          ascending: true,
        );
        break;

      case 'Más recientes':
      default:
        queryBuilder = queryBuilder.order('creado_en', ascending: false);
        break;
    }

    final response = await queryBuilder;
    return List<Map<String, dynamic>>.from(response);
  }

  // --- CARD DEL SERVICIO ---
  Widget buildServiceCard(Map<String, dynamic> servicio) {
    final String titulo = servicio['titulo'] ?? 'Sin título';
    final List<dynamic> fotos = servicio['fotos'] ?? [];
    final String imageUrl = fotos.isNotEmpty ? fotos[0] : '';

    final String displayTitle = titulo.length > 28
        ? '${titulo.substring(0, 25)}...'
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 130,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
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
}
