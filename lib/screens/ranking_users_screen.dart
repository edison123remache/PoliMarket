import 'package:flutter/material.dart';
import 'package:randimarket/screens/info_servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingServiciosScreen extends StatefulWidget {
  final String mode; // "best" | "worst"

  const RankingServiciosScreen({super.key, required this.mode});

  @override
  State<RankingServiciosScreen> createState() =>
      _RankingServiciosScreenState();
}

class _RankingServiciosScreenState extends State<RankingServiciosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _servicios = [];

  @override
  void initState() {
    super.initState();
    _loadServicios();
  }

  Future<void> _loadServicios() async {
    final response = await Supabase.instance.client
        .from('servicios')
        .select('''
          id,
          titulo,
          fotos,
          perfiles ( rating_avg )
        ''')
        .eq('status', 'activa')
        .limit(50);

    final List<Map<String, dynamic>> servicios =
        List<Map<String, dynamic>>.from(response);

    // 🔥 FILTRAR EN DART
    final filtrados = servicios.where((s) {
      final rating =
          (s['perfiles']?['rating_avg'] as num?)?.toDouble() ?? 0.0;

      return widget.mode == 'best'
          ? rating >= 4.0
          : rating <= 2.5;
    }).toList();

    // 🔥 ORDENAR
    filtrados.sort((a, b) {
      final ra =
          (a['perfiles']?['rating_avg'] as num?)?.toDouble() ?? 0.0;
      final rb =
          (b['perfiles']?['rating_avg'] as num?)?.toDouble() ?? 0.0;

      return widget.mode == 'best'
          ? rb.compareTo(ra)
          : ra.compareTo(rb);
    });

    setState(() {
      _servicios = filtrados;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.mode == 'best'
              ? 'Servicios Mayor Calificados'
              : 'Servicios Menor Calificados',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _servicios.isEmpty
              ? Center(
                  child: Text(
                    widget.mode == 'best'
                        ? 'No hay servicios bien calificados'
                        : 'No hay servicios mal calificados',
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _servicios.length,
                  itemBuilder: (_, i) =>
                      _buildServiceCard(_servicios[i]),
                ),
    );
  }

Widget _buildServiceCard(Map<String, dynamic> servicio) {
  final String titulo = servicio['titulo'] ?? 'Sin título';
  final List fotos = servicio['fotos'] ?? [];
  final String imageUrl = fotos.isNotEmpty ? fotos.first : '';

  final double rating =
      (servicio['perfiles']?['rating_avg'] as num?)?.toDouble() ?? 0.0;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 IMAGEN
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 130,
              width: double.infinity,
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40),
            ),
          ),

          // 📄 INFO
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 TÍTULO
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // ⭐ RANKING DEL USUARIO
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
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
