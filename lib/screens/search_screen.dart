import 'package:flutter/material.dart';
import 'package:poli_market/screens/info_servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  Future<List<Map<String, dynamic>>>? loadDataFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ModalRoute.of(context)!.settings.arguments as String;
      setState(() {
        loadDataFuture = loadData(query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: loadDataFuture != null
          ? SafeArea(
              child: FutureBuilder(
                future: loadDataFuture!,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Cargando...'));
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) {
                      return buildServiceCard(snapshot.data![index]);
                    },
                    separatorBuilder: (_, _) {
                      return SizedBox(height: 16.0);
                    },
                  );
                },
              ),
            )
          : SizedBox.shrink(),
    );
  }

  Widget buildServiceCard(Map<String, dynamic> servicio) {
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

  Future<List<Map<String, dynamic>>> loadData(String query) async {
    final supabase = Supabase.instance.client;

    String pattern = '%${query.trim()}%';

    return await supabase
        .from('servicios')
        .select()
        .ilike('titulo', pattern)
        .order('creado_en', ascending: false);
  }
}
