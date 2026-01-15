import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'info_servicio.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- PALETA DE COLORES MEJORADA ---
  final Color _brandOrange = const Color(0xFFFF6B00);
  final Color _brandWhite = Colors.white;
  final Color _bgLight = const Color(0xFFFAFAFA);
  final Color _textDark = const Color(0xFF1A1A1A);

  // Colores para cada tab
  final Color _pendienteColor = const Color(0xFFFF6B00); // Naranja
  final Color _resueltoColor = const Color(0xFF4CAF50); // Verde
  final Color _todosColor = const Color(0xFF2196F3); // Azul

  // Variables de lógica (INTACTAS)
  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> _filteredReportes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _filtroStatus = 'pendiente';
  bool _processingAction = false;

  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _cargarReportes();

    debugPrint(_filteredReportes.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS (NO TOCAR) ---
  Future<void> _cargarReportes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await _supabase
          .from('reportes')
          .select('''
          id, 
          razones, 
          status, 
          creado_en, 
          service_id, 
          reporter_id
        ''')
          .order('creado_en', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final reportesConDatos = await _cargarDatosRelacionados(
        List<Map<String, dynamic>>.from(response),
      );

      setState(() {
        _reportes = reportesConDatos;
        _isLoading = false;

        // 🔥 ACTUALIZAR FILTRO BASADO EN LA PÁGINA ACTUAL
        switch (_currentPage) {
          case 0: // Pendientes
            _filtroStatus = 'pendiente';
            _filteredReportes = _reportes
                .where((r) => r['status'] == 'pendiente')
                .toList();
            break;
          case 1: // Resueltos (sin desactivar)
            _filtroStatus = 'resuelta';
            _filteredReportes = _reportes.where((r) {
              final servicioStatus = r['servicio']?['status'];
              return r['status'] == 'resuelta' && servicioStatus != 'rechazada';
            }).toList();
            break;
          case 2: // Desactivados
            _filtroStatus = 'desactivado';
            _filteredReportes = _reportes.where((r) {
              final servicioStatus = r['servicio']?['status'];
              return r['status'] == 'resuelta' && servicioStatus == 'rechazada';
            }).toList();
            break;
          case 3: // Todos
            _filtroStatus = 'todos';
            _filteredReportes = _reportes;
            break;
          default:
            _filtroStatus = 'pendiente';
            _filteredReportes = _reportes
                .where((r) => r['status'] == 'pendiente')
                .toList();
        }
      });
    } catch (e) {
      debugPrint('Error al cargar reportes: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar reportes';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _cargarDatosRelacionados(
    List<Map<String, dynamic>> reportes,
  ) async {
    final resultados = <Map<String, dynamic>>[];

    for (final reporte in reportes) {
      try {
        final servicioResponse = await _supabase
            .from('servicios')
            .select('id, titulo, descripcion, user_id, status, fotos')
            .eq('id', reporte['service_id'])
            .limit(1)
            .then((res) => res.isNotEmpty ? res[0] : null)
            .catchError((_) => null);

        final reporterResponse = await _supabase
            .from('perfiles')
            .select('id, nombre, email, avatar_url')
            .eq('id', reporte['reporter_id'])
            .limit(1)
            .then((res) => res.isNotEmpty ? res[0] : null)
            .catchError((_) => null);

        Map<String, dynamic>? usuarioReportado;
        if (servicioResponse != null && servicioResponse['user_id'] != null) {
          usuarioReportado = await _supabase
              .from('perfiles')
              .select('id, nombre, email')
              .eq('id', servicioResponse['user_id'])
              .limit(1)
              .then((res) => res.isNotEmpty ? res[0] : null)
              .catchError((_) => null);
        }

        resultados.add({
          ...reporte,
          'servicio': servicioResponse,
          'reporter': reporterResponse,
          'usuario_reportado': usuarioReportado,
        });
      } catch (e) {
        resultados.add(reporte);
      }
    }
    return resultados;
  }

  void _filtrarReportes(String status) {
    setState(() {
      _filtroStatus = status;
      if (status == 'todos') {
        _filteredReportes = _reportes;
      } else if (status == 'desactivado') {
        // 🔥 NUEVO: Filtrar solo los que tienen servicio desactivado
        _filteredReportes = _reportes.where((reporte) {
          final servicioStatus = reporte['servicio']?['status'];
          return reporte['status'] == 'resuelta' &&
              servicioStatus == 'rechazada';
        }).toList();
      } else if (status == 'resuelta') {
        // 🔥 ACTUALIZADO: Solo los resueltos SIN desactivar
        _filteredReportes = _reportes.where((reporte) {
          final servicioStatus = reporte['servicio']?['status'];
          return reporte['status'] == 'resuelta' &&
              servicioStatus != 'rechazada';
        }).toList();
      } else {
        _filteredReportes = _reportes
            .where((reporte) => reporte['status'] == status)
            .toList();
      }
    });
  }

  void _cambiarPagina(int index) {
    // 🔥 VERIFICAR QUE EL CONTROLLER ESTÉ ATTACHED
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _atenderReporte(String reporteId) async {
    if (_processingAction) return;
    setState(() => _processingAction = true);

    try {
      await _supabase
          .from('reportes')
          .update({'status': 'resuelta'})
          .eq('id', reporteId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reporte marcado como resuelto'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargarReportes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAction = false);
    }
  }

  // --- UI WIDGETS MEJORADOS ---
  Color _getColorForStatus(String status) {
    switch (status) {
      case 'pendiente':
        return _pendienteColor;
      case 'resuelta':
        return _resueltoColor;
      case 'desactivado': // 🔥 NUEVO
        return Colors.red.shade600;
      default:
        return _todosColor;
    }
  }

  Widget _buildStatusBadge(String status, {Map<String, dynamic>? servicio}) {
    // 🔥 Verificar si el servicio está desactivado
    final servicioDesactivado = servicio?['status'] == 'rechazada';

    if (servicioDesactivado && status == 'resuelta') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Text(
              'Desactivado',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    bool isPending = status == 'pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? Colors.orange.shade200 : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending ? Icons.warning_amber_rounded : Icons.check_circle,
            size: 14,
            color: isPending ? Colors.orange.shade800 : Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isPending ? 'Pendiente' : 'Resuelto',
            style: TextStyle(
              color: isPending ? Colors.orange.shade900 : Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Tabs con colores diferentes y animación mejorada
  Widget _buildFilterTab(String label, String value, int index) {
    bool isSelected = _currentPage == index;
    Color tabColor = value == 'pendiente'
        ? _pendienteColor
        : value == 'resuelta'
        ? _resueltoColor
        : value == 'desactivado' // 🔥 NUEVO
        ? Colors.red.shade600
        : _todosColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => _cambiarPagina(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isSelected ? tabColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tabColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    value == 'pendiente'
                        ? Icons.pending_actions
                        : value == 'resuelta'
                        ? Icons.check_circle
                        : value == 'desactivado' // 🔥 NUEVO
                        ? Icons.block
                        : Icons.list_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: _getColorForStatus(_filtroStatus).withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reportes aquí',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final reporte = lista[index];
        final servicio = reporte['servicio'] is Map
            ? reporte['servicio']
            : null;
        final reporter = reporte['reporter'] is Map
            ? reporte['reporter']
            : null;
        final usuarioReportado = reporte['usuario_reportado'] is Map
            ? reporte['usuario_reportado']
            : null; // 👈 NUEVO
        final status = reporte['status'] ?? 'pendiente';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _brandWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getColorForStatus(status).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getColorForStatus(status).withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _mostrarDetalleReporte(reporte),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 NUEVO: Encabezado con servicio y estado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto del servicio
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getColorForStatus(
                                status,
                              ).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                servicio?['fotos'] != null &&
                                    (servicio!['fotos'] as List).isNotEmpty
                                ? Image.network(
                                    servicio['fotos'][0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                servicio?['titulo'] ?? 'Servicio Eliminado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // 🔥 NUEVO: Mostrar dueño del servicio
                              if (usuarioReportado != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Publicado por ${usuarioReportado['nombre']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // 🔥 NUEVO: Sección "Reportado por"
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: reporter?['avatar_url'] != null
                              ? NetworkImage(reporter!['avatar_url'])
                              : null,
                          child: reporter?['avatar_url'] == null
                              ? Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reportado por',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                reporter?['nombre'] ?? 'Anónimo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Motivo del reporte
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOTIVO:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reporte['razones']?.toString() ?? 'Sin razón',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          reporte['creado_en']?.toString().substring(0, 10) ??
                              '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Reemplaza solo el método _mostrarDetalleReporte y _desactivarServicio

  void _mostrarDetalleReporte(Map<String, dynamic> reporte) {
    final servicio = reporte['servicio'] is Map ? reporte['servicio'] : null;
    final reporter = reporte['reporter'] is Map ? reporte['reporter'] : null;
    final usuarioReportado = reporte['usuario_reportado'] is Map
        ? reporte['usuario_reportado']
        : null;
    final razon = reporte['razones']?.toString() ?? 'Sin razón especificada';
    final status = reporte['status'] ?? 'pendiente';

    final servicioStatus = servicio?['status'] ?? '';
    final servicioYaDesactivado = servicioStatus == 'rechazada';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: _brandWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 50,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(status),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detalles del Reporte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (servicioYaDesactivado)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Este servicio ya fue desactivado',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 🔥 NUEVO: CARD COMPLETA DEL SERVICIO REPORTADO
                  if (servicio != null) ...[
                    Text(
                      'Servicio Reportado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: status == 'pendiente'
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalleServicioScreen(
                                      servicioId: servicio['id'],
                                    ),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagen del servicio
                              if (servicio['fotos'] != null &&
                                  (servicio['fotos'] as List).isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    servicio['fotos'][0],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.grey[400],
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    color: Colors.grey[400],
                                    size: 50,
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Título del servicio
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 20,
                                    color: _brandOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      servicio['titulo'] ?? 'Sin título',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: _textDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Descripción del servicio
                              Text(
                                servicio['descripcion'] ?? 'Sin descripción',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              // Dueño del servicio
                              if (usuarioReportado != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey[200],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Publicado por',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              usuarioReportado['nombre'] ??
                                                  'Usuario',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: _textDark,
                                              ),
                                            ),
                                            if (usuarioReportado['email'] !=
                                                null)
                                              Text(
                                                usuarioReportado['email'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Botón para ver completo
                              if (status == 'pendiente') ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Ver publicación completa',
                                      style: TextStyle(
                                        color: _brandOrange,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: _brandOrange,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Información de quien reportó
                  if (reporter != null) ...[
                    Text(
                      'Reportado por',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: reporter['avatar_url'] != null
                                ? NetworkImage(reporter['avatar_url'])
                                : null,
                            child: reporter['avatar_url'] == null
                                ? Icon(
                                    Icons.person,
                                    color: Colors.grey[400],
                                    size: 28,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reporter['nombre'] ?? 'Anónimo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
                                  ),
                                ),
                                if (reporter['email'] != null)
                                  Text(
                                    reporter['email'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Razón del reporte
                  Text(
                    'Razón del Reporte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      razon,
                      style: TextStyle(
                        color: Colors.red[900],
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _brandWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pendiente')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _atenderReporte(reporte['id']);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marcar Resuelto'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    if (servicio != null && !servicioYaDesactivado) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _desactivarServicio(
                            servicio['id'],
                            reporte['id'],
                          ),
                          icon: const Icon(Icons.block),
                          label: const Text('Desactivar Servicio'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _desactivarServicio(String serviceId, String reporteId) async {
    Navigator.pop(context);

    String? motivo;

    // 🔥 ARREGLADO: Dialog con scroll para evitar overflow
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desactivar Servicio'),
        content: SingleChildScrollView(
          // 👈 ESTO ARREGLA EL OVERFLOW
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción desactivará el servicio y notificará al usuario del motivo.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => motivo = value,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la desactivación *',
                  hintText: 'Ej: Contenido inapropiado',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivo == null || motivo!.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes especificar un motivo'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Rechazar servicio
      await _supabase
          .from('servicios')
          .update({'status': 'rechazada'})
          .eq('id', serviceId);

      // 2. Marcar reporte como resuelto
      await _supabase
          .from('reportes')
          .update({'status': 'resuelta'})
          .eq('id', reporteId);

      // 🔥 DEBUGGING: Agregar logs
      debugPrint('🔔 Enviando notificación...');
      debugPrint('Service ID: $serviceId');
      debugPrint('Motivo: ${motivo?.trim()}');

      // 3. Notificar usuario
      final response = await _supabase.functions.invoke(
        'notificar-servicio',
        body: {
          'service_id': serviceId,
          'razon': motivo?.trim() ?? 'No se especificó un motivo',
          'tipo_accion': 'desactivar_por_reporte',
        },
      );

      // 🔥 DEBUGGING: Ver respuesta
      debugPrint('📩 Respuesta de la función: ${response.data}');

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Verificar respuesta
      if (response.data != null && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Servicio desactivado y usuario notificado'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠ Servicio desactivado pero la notificación falló: ${response.data?['error'] ?? 'Error desconocido'}',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      await _cargarReportes();
    } catch (e) {
      debugPrint('❌ Error al desactivar servicio: $e');

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: _brandWhite,
            surfaceTintColor: _brandWhite,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Reportes',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              background: Container(color: _brandWhite),
            ),
            actions: [
              IconButton(
                onPressed: _processingAction ? null : _cargarReportes,
                icon: _processingAction
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _brandOrange,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, color: _textDark),
              ),
              const SizedBox(width: 10),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: _brandWhite,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      _buildFilterTab('Pendientes', 'pendiente', 0),
                      _buildFilterTab('Resueltos', 'resuelta', 1),
                      _buildFilterTab(
                        'Desactivados',
                        'desactivado',
                        2,
                      ), // 🔥 NUEVO
                      _buildFilterTab('Todos', 'todos', 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: _brandOrange))
            : _hasError
            ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    // 🔥 ACTUALIZAR FILTROS
                    switch (index) {
                      case 0:
                        _filtrarReportes('pendiente');
                        break;
                      case 1:
                        _filtrarReportes('resuelta');
                        break;
                      case 2: // 🔥 NUEVO
                        _filtrarReportes('desactivado');
                        break;
                      case 3:
                        _filtrarReportes('todos');
                        break;
                    }
                  });
                },
                children: [
                  // Pendientes
                  _buildList(
                    _reportes.where((r) => r['status'] == 'pendiente').toList(),
                  ),
                  // Resueltos (sin desactivar)
                  _buildList(
                    _reportes.where((r) {
                      final servicioStatus = r['servicio']?['status'];
                      return r['status'] == 'resuelta' &&
                          servicioStatus != 'rechazada';
                    }).toList(),
                  ),
                  // 🔥 NUEVO: Desactivados
                  _buildList(
                    _reportes.where((r) {
                      final servicioStatus = r['servicio']?['status'];
                      return r['status'] == 'resuelta' &&
                          servicioStatus == 'rechazada';
                    }).toList(),
                  ),
                  // Todos
                  _buildList(_reportes),
                ],
              ),
      ),
    );
  }
}
