import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/vista_mapa.dart';

class DetalleServicioScreen extends StatefulWidget {
  final String servicioId;

  const DetalleServicioScreen({super.key, required this.servicioId});

  @override
  State<DetalleServicioScreen> createState() => _DetalleServicioScreenState();
}

class _DetalleServicioScreenState extends State<DetalleServicioScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService(Supabase.instance.client);

  Map<String, dynamic>? _servicio;
  UserModel? _vendedor;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  String? _mapaUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar datos del servicio
      final servicioData = await _supabase
          .from('servicios')
          .select()
          .eq('id', widget.servicioId)
          .single();

      // Cargar datos del vendedor
      final vendedorData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', servicioData['user_id'])
          .single();

      // Cargar mapa estático
      final mapaUrl = await MapService.getStaticMapForAddress(
        servicioData['ubicacion'],
      );

      setState(() {
        _servicio = servicioData;
        _vendedor = UserModel.fromJson(vendedorData);
        _mapaUrl = mapaUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMenuOpciones() {
    final user = _authService.currentUser;
    final bool esMiPublicacion = user?.id == _servicio?['user_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (esMiPublicacion)
              _buildOpcionMenu(
                icon: Icons.delete,
                texto: 'Borrar publicación',
                color: Colors.red,
                onTap: _borrarPublicacion,
              )
            else
              _buildOpcionMenu(
                icon: Icons.report,
                texto: 'Reportar publicación',
                color: Colors.orange,
                onTap: _mostrarReporteDialog,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionMenu({
    required IconData icon,
    required String texto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  void _borrarPublicacion() async {
    Navigator.pop(context); // Cerrar el menú

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar publicación'),
        content: const Text(
          '¿Estás seguro de que quieres borrar esta publicación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await _supabase.from('servicios').delete().eq('id', widget.servicioId);

        Navigator.pop(context); // Regresar a la pantalla anterior
      } catch (e) {
        _mostrarError('Error al borrar publicación: $e');
      }
    }
  }

  void _mostrarReporteDialog() {
    Navigator.pop(context); // Cerrar el menú

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReporteDialog(
        servicioId: widget.servicioId,
        onReportado: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte enviado correctamente')),
          );
        },
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_servicio == null || _vendedor == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Error al cargar el servicio')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalle del Servicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _mostrarMenuOpciones,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel de imágenes
            _buildCarruselImagenes(),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    _servicio!['titulo'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Botón Contactar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implementar chat
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Contactar Vendedor',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  _buildSeccionDescripcion(),
                  const SizedBox(height: 24),

                  // Información del vendedor
                  _buildSeccionVendedor(),
                  const SizedBox(height: 24),

                  // Ubicación
                  _buildSeccionUbicacion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarruselImagenes() {
    final List<String> fotos = List<String>.from(_servicio!['fotos'] ?? []);

    if (fotos.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.photo, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: fotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: fotos[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < fotos.length; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == i
                      ? Colors.blue
                      : Colors.grey[400],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _servicio!['descripcion'],
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSeccionVendedor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acerca del vendedor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // TODO: Navegar a perfil del vendedor
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _vendedor!.avatarUrl != null
                    ? NetworkImage(_vendedor!.avatarUrl!)
                    : null,
                child: _vendedor!.avatarUrl == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vendedor!.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildEstrellasCalificacion(_vendedor!.ratingAvg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstrellasCalificacion(double rating) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSeccionUbicacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación del vendedor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Mapa estático
        if (_mapaUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _mapaUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('Error al cargar mapa'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _servicio!['ubicacion'],
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

// Diálogo de reporte
class _ReporteDialog extends StatefulWidget {
  final String servicioId;
  final VoidCallback onReportado;

  const _ReporteDialog({required this.servicioId, required this.onReportado});

  @override
  State<_ReporteDialog> createState() => __ReporteDialogState();
}

class __ReporteDialogState extends State<_ReporteDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _razonSeleccionada;
  bool _enviandoReporte = false;

  final List<String> _razones = [
    'Esta publicación es Estafa/Spam',
    'Esta publicación Tiene una Información Imprecisa',
    'Esta publicación restringe las Normas',
    'Esta publicación incita al Acoso, odio o Violencia',
    'Esta publicación contiene Desnudos o Actividad sexual',
  ];

  Future<void> _enviarReporte() async {
    if (_razonSeleccionada == null) return;

    setState(() => _enviandoReporte = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _supabase.from('reportes').insert({
        'reporter_id': user.id,
        'service_id': widget.servicioId,
        'razones': _razonSeleccionada,
        'status': 'pendiente',
      });

      widget.onReportado();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar reporte: $e')));
    } finally {
      setState(() => _enviandoReporte = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior para arrastrar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Encabezado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Reportar publicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Razones de reporte
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _razones.map((razon) {
                return RadioListTile<String>(
                  title: Text(razon),
                  value: razon,
                  groupValue: _razonSeleccionada,
                  onChanged: (value) {
                    setState(() {
                      _razonSeleccionada = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _razonSeleccionada != null && !_enviandoReporte
                        ? _enviarReporte
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _enviandoReporte
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Enviar Reporte'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
