import 'package:flutter/material.dart';
import 'package:poli_market/screens/info_servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Future<List<Map<String, dynamic>>>? loadDataFuture;
  String? searchQuery;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ModalRoute.of(context)!.settings.arguments as String;
      setState(() {
        searchQuery = query;
        loadDataFuture = loadData(query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FONDO CON EL DEGRADADO QUE TÚ QUERÍAS
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0EC), // Arriba (el que pusiste)
              Color(0xFFF5F5F5), // Abajo (el que pusiste)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header naranja del prototipo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE0B2), // Naranja clarito exacto del prototipo
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios,
                              color: Colors.black87, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Resultados de Búsqueda:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (searchQuery != null && searchQuery!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
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

              const SizedBox(height: 16),

              // Resultados o mensaje de "sin coincidencias"
              loadDataFuture == null
                  ? const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: loadDataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No se encontraron resultados",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    "Intenta con otra palabra",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            );
                          }

                          final servicios = snapshot.data!;

                          return GridView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
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
            ],
          ),
        ),
      ),
    );
  }

  // TODO LO DEMÁS QUEDA EXACTAMENTE IGUAL (tarjetas, loadData, etc.)
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 130,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                      )
                    : const Icon(Icons.shopping_bag,
                        size: 50, color: Colors.grey),
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

  Future<List<Map<String, dynamic>>> loadData(String query) async {
    final supabase = Supabase.instance.client;
    final pattern = '%${query.trim()}%';

    final response = await supabase
        .from('servicios')
        .select()
        .ilike('titulo', pattern)
        .order('creado_en', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}