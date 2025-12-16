import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> _filteredReportes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _filtroStatus = 'pendiente';
  bool _processingAction = false;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Consulta simplificada - solo datos esenciales
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
          .limit(100) // Limitar resultados
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      // Cargar datos relacionados por separado
      final reportesConDatos = await _cargarDatosRelacionados(
        List<Map<String, dynamic>>.from(response),
      );

      setState(() {
        _reportes = reportesConDatos;
        _filteredReportes = _reportes;
        _isLoading = false;
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
        // Cargar servicio
        final servicioResponse = await _supabase
            .from('servicios')
            .select('id, titulo, descripcion, user_id, status')
            .eq('id', reporte['service_id'])
            .limit(1)
            .timeout(const Duration(seconds: 5))
            .then((res) => res.isNotEmpty ? res[0] : null)
            .catchError((_) => null);

        // Cargar reporter
        final reporterResponse = await _supabase
            .from('perfiles')
            .select('id, nombre, email')
            .eq('id', reporte['reporter_id'])
            .limit(1)
            .timeout(const Duration(seconds: 5))
            .then((res) => res.isNotEmpty ? res[0] : null)
            .catchError((_) => null);

        // Cargar usuario reportado
        Map<String, dynamic>? usuarioReportado;
        if (servicioResponse != null && servicioResponse['user_id'] != null) {
          usuarioReportado = await _supabase
              .from('perfiles')
              .select('id, nombre, email')
              .eq('id', servicioResponse['user_id'])
              .limit(1)
              .timeout(const Duration(seconds: 5))
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
        debugPrint('Error cargando datos relacionados: $e');
        resultados.add(reporte);
      }
    }

    return resultados;
  }

  void _filtrarReportes(String status) {
    try {
      setState(() {
        _filtroStatus = status;
        if (status == 'todos') {
          _filteredReportes = _reportes;
        } else {
          _filteredReportes = _reportes
              .where((reporte) => reporte['status'] == status)
              .toList();
        }
      });
    } catch (e) {
      debugPrint('Error al filtrar reportes: $e');
    }
  }

  Future<void> _atenderReporte(String reporteId) async {
    if (_processingAction) return;

    _processingAction = true;
    if (mounted) setState(() {});

    try {
      await _supabase
          .from('reportes')
          .update({'status': 'resuelta'})
          .eq('id', reporteId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte marcado como resuelto'),
          backgroundColor: Colors.green,
        ),
      );

      await _cargarReportes();
    } catch (e) {
      debugPrint('Error al atender reporte: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _processingAction = false;
      if (mounted) setState(() {});
    }
  }

  void _mostrarDetalleReporte(Map<String, dynamic> reporte) {
    final servicio = reporte['servicio'] is Map ? reporte['servicio'] : null;
    final reporter = reporte['reporter'] is Map ? reporte['reporter'] : null;
    final usuarioReportado = reporte['usuario_reportado'] is Map
        ? reporte['usuario_reportado']
        : null;
    final razon = reporte['razones']?.toString() ?? 'Sin razón especificada';
    final fecha = reporte['creado_en']?.toString().substring(0, 10) ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: !_processingAction,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Detalles del Reporte'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Razon del reporte
                  const Text(
                    'Razón:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(razon),

                  const SizedBox(height: 15),

                  // Servicio reportado
                  const Text(
                    'Servicio Reportado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  if (servicio != null) ...[
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarDetalleServicio(servicio);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicio['titulo']?.toString() ?? 'Sin título',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              servicio['descripcion']?.length > 100
                                  ? '${servicio['descripcion'].toString().substring(0, 100)}...'
                                  : servicio['descripcion']?.toString() ??
                                        'Sin descripción',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Estado: ${servicio['status']?.toUpperCase() ?? 'DESCONOCIDO'}',
                              style: TextStyle(
                                color: servicio['status'] == 'activa'
                                    ? Colors.green
                                    : servicio['status'] == 'pendiente'
                                    ? Colors.orange
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Servicio no encontrado o eliminado',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 15),

                  // Usuarios involucrados
                  const Text(
                    'Usuarios Involucrados:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Usuario que reporta
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Usuario que reporta:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(reporter?['nombre']?.toString() ?? 'Anónimo'),
                            if (reporter?['email'] != null)
                              Text(
                                reporter!['email'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Usuario reportado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_off, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Usuario reportado:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              usuarioReportado?['nombre']?.toString() ??
                                  'Desconocido',
                            ),
                            if (usuarioReportado?['email'] != null)
                              Text(
                                usuarioReportado!['email'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Fecha
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reportado el: $fecha',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              if (_processingAction)
                const Center(child: CircularProgressIndicator())
              else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                if (reporte['status'] == 'pendiente')
                  ElevatedButton(
                    onPressed: () {
                      _atenderReporte(reporte['id']);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Marcar como Resuelto'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (servicio != null) {
                      Navigator.pop(context);
                      _mostrarDetalleServicio(servicio);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Ver Servicio'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _mostrarDetalleServicio(Map<String, dynamic> servicio) {
    final _ = servicio['fotos'] is List
        ? servicio['fotos'] as List<dynamic>
        : [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(servicio['titulo']?.toString() ?? 'Servicio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del servicio
              Text(
                servicio['descripcion']?.toString() ?? 'Sin descripción',
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 10),

              // Estado del servicio
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: servicio['status'] == 'activa'
                      ? Colors.green[50]
                      : servicio['status'] == 'pendiente'
                      ? Colors.orange[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: servicio['status'] == 'activa'
                        ? Colors.green
                        : servicio['status'] == 'pendiente'
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                child: Text(
                  'Estado: ${servicio['status']?.toUpperCase() ?? 'DESCONOCIDO'}',
                  style: TextStyle(
                    color: servicio['status'] == 'activa'
                        ? Colors.green[800]
                        : servicio['status'] == 'pendiente'
                        ? Colors.orange[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Acciones
              const Text(
                'Acciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (servicio['status'] == 'activa')
                ElevatedButton(
                  onPressed: () => _desactivarServicio(servicio['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Desactivar Servicio'),
                )
              else if (servicio['status'] == 'pendiente')
                ElevatedButton(
                  onPressed: () => _aprobarServicio(servicio['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Aprobar Servicio'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _aprobarServicio(String serviceId) async {
    try {
      await _supabase
          .from('servicios')
          .update({
            'status': 'activa',
          }) // Cambia a 'activa' en lugar de 'aprobada'
          .eq('id', serviceId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio aprobado (activado)'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Cerrar diálogo
    } catch (e) {
      debugPrint('Error al aprobar servicio: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _desactivarServicio(String serviceId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Servicio'),
        content: const Text('¿Estás seguro de desactivar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _supabase
          .from('servicios')
          .update({'status': 'inactiva'}) // Cambia a 'inactiva'
          .eq('id', serviceId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio desactivado'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context); // Cerrar diálogo
    } catch (e) {
      debugPrint('Error al desactivar servicio: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReporteCard(Map<String, dynamic> reporte) {
    final servicio = reporte['servicio'] is Map ? reporte['servicio'] : null;
    final reporter = reporte['reporter'] is Map ? reporte['reporter'] : null;
    final isPendiente = reporte['status'] == 'pendiente';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleReporte(reporte),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y estado
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPendiente ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      servicio?['titulo']?.toString() ??
                          'Servicio no disponible',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isPendiente ? 'PENDIENTE' : 'RESUELTO',
                    style: TextStyle(
                      color: isPendiente ? Colors.orange : Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Razón del reporte
              Text(
                'Razón: ${reporte['razones']?.toString() ?? 'No especificada'}',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Información de usuarios
              Row(
                children: [
                  // Usuario que reporta
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reporter?['nombre']?.toString() ?? 'Anónimo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fecha
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reporte['creado_en']?.toString().substring(0, 10) ??
                              '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Error al cargar reportes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _cargarReportes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            onPressed: _processingAction ? null : _cargarReportes,
            icon: _processingAction
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Cargando reportes...'),
                ],
              ),
            )
          : _hasError
          ? _buildErrorView()
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Pendientes'),
                        selected: _filtroStatus == 'pendiente',
                        onSelected: (selected) => _filtrarReportes('pendiente'),
                      ),
                      FilterChip(
                        label: const Text('Resueltos'),
                        selected: _filtroStatus == 'resuelta',
                        onSelected: (selected) => _filtrarReportes('resuelta'),
                      ),
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _filtroStatus == 'todos',
                        onSelected: (selected) => _filtrarReportes('todos'),
                      ),
                    ],
                  ),
                ),

                // Contador
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredReportes.length} reportes',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _filtroStatus == 'pendiente'
                            ? 'Mostrando pendientes'
                            : _filtroStatus == 'resuelta'
                            ? 'Mostrando resueltos'
                            : 'Mostrando todos',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de reportes
                Expanded(
                  child: _filteredReportes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 60,
                                color: Colors.green,
                              ),
                              SizedBox(height: 10),
                              Text('No hay reportes'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredReportes.length,
                          itemBuilder: (context, index) {
                            return _buildReporteCard(_filteredReportes[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
