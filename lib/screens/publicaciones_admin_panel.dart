import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicacionesAdminScreen extends StatefulWidget {
  const PublicacionesAdminScreen({super.key});

  @override
  State<PublicacionesAdminScreen> createState() =>
      _PublicacionesAdminScreenState();
}

class _PublicacionesAdminScreenState extends State<PublicacionesAdminScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _publicaciones = [];
  List<Map<String, dynamic>> _publicacionesAprobadas = [];
  List<Map<String, dynamic>> _publicacionesPendientes = [];
  List<Map<String, dynamic>> _filteredAprobadas = [];
  List<Map<String, dynamic>> _filteredPendientes = [];

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _sortOption = 'Más recientes';
  late TabController _tabController;
  int _currentTab = 0;
  bool _processingAction = false;

  // Para prevenir múltiples llamadas simultáneas
  bool _isRefreshing = false;

  // Timeouts y manejo de excepciones
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Inicializar el TabController con cuidado
    try {
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(() {
        if (mounted) {
          setState(() => _currentTab = _tabController.index);
        }
      });
    } catch (e) {
      debugPrint('Error inicializando TabController: $e');
    }

    // Cargar datos después de que el widget esté completamente inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPublicaciones();
    });
  }

  @override
  void dispose() {
    // Limpiar timers y controllers
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPublicaciones() async {
    if (!mounted || _isRefreshing) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _isRefreshing = true;
    });

    try {
      // Usar una consulta más simple primero para diagnóstico
      final response = await _supabase
          .from('servicios')
          .select('''
             id, 
          titulo, 
          descripcion, 
          status, 
          creado_en,
          user_id
          ''')
          .order('creado_en', ascending: false)
          .limit(50);

      if (!mounted) return;

      setState(() {
        _publicaciones = List<Map<String, dynamic>>.from(response);
        _separarPublicaciones();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error al cargar publicaciones: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar publicaciones: ${e.toString()}';
        _isRefreshing = false;
      });

      // Mostrar error de manera segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cargar publicaciones'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _cargarPerfilesParaPublicaciones(
    List<Map<String, dynamic>> publicaciones,
  ) async {
    final resultados = <Map<String, dynamic>>[];

    for (final publicacion in publicaciones) {
      try {
        final perfilResponse = await _supabase
            .from('perfiles')
            .select('id, nombre, email, avatar_url')
            .eq('id', publicacion['user_id'])
            .limit(1)
            .timeout(const Duration(seconds: 5))
            .then((data) => data.isNotEmpty ? data[0] : null)
            .catchError((_) => null);

        final reportesResponse = await _supabase
            .from('reportes')
            .select('id')
            .eq('service_id', publicacion['id'])
            .count(CountOption.exact)
            .timeout(const Duration(seconds: 5))
            .catchError((_) => null);

        resultados.add({
          ...publicacion,
          'perfiles': perfilResponse,
          'reportes_count': reportesResponse?.count ?? 0,
        });
      } catch (e) {
        // Si hay error, agregar la publicación sin datos adicionales
        resultados.add({...publicacion, 'perfiles': null, 'reportes_count': 0});
      }
    }

    return resultados;
  }

  void _separarPublicaciones() {
    try {
      _publicacionesAprobadas = _publicaciones
          .where((p) => p['status'] == 'activa')
          .toList();

      _publicacionesPendientes = _publicaciones
          .where((p) => (p['status'] as String?)?.toLowerCase() == 'pendiente')
          .toList();

      _filtrarPublicaciones();
    } catch (e) {
      debugPrint('Error al separar publicaciones: $e');
      _publicacionesAprobadas = [];
      _publicacionesPendientes = [];
    }
  }

  void _filtrarPublicaciones() {
    try {
      String searchTerm = _searchController.text.trim().toLowerCase();

      _filteredAprobadas = _publicacionesAprobadas.where((pub) {
        final titulo = (pub['titulo'] as String?)?.toLowerCase() ?? '';
        final desc = (pub['descripcion'] as String?)?.toLowerCase() ?? '';
        final user =
            (pub['perfiles']?['nombre'] as String?)?.toLowerCase() ?? '';

        if (searchTerm.isEmpty) return true;

        return titulo.contains(searchTerm) ||
            desc.contains(searchTerm) ||
            user.contains(searchTerm);
      }).toList();

      _filteredPendientes = _publicacionesPendientes.where((pub) {
        final titulo = (pub['titulo'] as String?)?.toLowerCase() ?? '';
        final desc = (pub['descripcion'] as String?)?.toLowerCase() ?? '';
        final user =
            (pub['perfiles']?['nombre'] as String?)?.toLowerCase() ?? '';

        if (searchTerm.isEmpty) return true;

        return titulo.contains(searchTerm) ||
            desc.contains(searchTerm) ||
            user.contains(searchTerm);
      }).toList();

      _aplicarOrdenamiento();
    } catch (e) {
      debugPrint('Error al filtrar publicaciones: $e');
      _filteredAprobadas = [];
      _filteredPendientes = [];
    }
  }

  void _aplicarOrdenamiento() {
    try {
      final Map<
        String,
        int Function(Map<String, dynamic>, Map<String, dynamic>)
      >
      comparadores = {
        'Más recientes': (a, b) {
          final fechaA = a['creado_en']?.toString() ?? '';
          final fechaB = b['creado_en']?.toString() ?? '';
          return fechaB.compareTo(fechaA);
        },
        'Más antiguos': (a, b) {
          final fechaA = a['creado_en']?.toString() ?? '';
          final fechaB = b['creado_en']?.toString() ?? '';
          return fechaA.compareTo(fechaB);
        },
        'A-Z': (a, b) {
          final tituloA = a['titulo']?.toString() ?? '';
          final tituloB = b['titulo']?.toString() ?? '';
          return tituloA.compareTo(tituloB);
        },
        'Z-A': (a, b) {
          final tituloA = a['titulo']?.toString() ?? '';
          final tituloB = b['titulo']?.toString() ?? '';
          return tituloB.compareTo(tituloA);
        },
        'Más reportadas': (a, b) {
          final reportesA = a['reportes_count'] ?? 0;
          final reportesB = b['reportes_count'] ?? 0;
          return reportesB.compareTo(reportesA);
        },
        'Menos reportadas': (a, b) {
          final reportesA = a['reportes_count'] ?? 0;
          final reportesB = b['reportes_count'] ?? 0;
          return reportesA.compareTo(reportesB);
        },
      };

      if (comparadores.containsKey(_sortOption)) {
        _filteredAprobadas.sort(comparadores[_sortOption]!);
        _filteredPendientes.sort(comparadores[_sortOption]!);
      }
    } catch (e) {
      debugPrint('Error al ordenar: $e');
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ordenar Publicaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...[
                  'Más recientes',
                  'Más antiguos',
                  'A-Z',
                  'Z-A',
                  'Más reportadas',
                  'Menos reportadas',
                ].map((option) {
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _sortOption,
                    onChanged: (value) {
                      if (value != null && mounted) {
                        setState(() => _sortOption = value);
                        _filtrarPublicaciones();
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetallePublicacion(
    Map<String, dynamic> publicacion,
    bool esPendiente,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(publicacion['titulo'] ?? 'Sin título'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado: ${publicacion['status']?.toUpperCase() ?? 'DESCONOCIDO'}',
                  style: TextStyle(
                    color: publicacion['status'] == 'pendiente'
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(publicacion['descripcion'] ?? 'Sin descripción'),
                const SizedBox(height: 16),
                const Text(
                  'Información:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ID: ${publicacion['id']}'),
                Text('Usuario ID: ${publicacion['user_id']}'),
                Text(
                  'Creado: ${publicacion['creado_en']?.toString().substring(0, 10) ?? 'N/A'}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (esPendiente) ...[
            ElevatedButton(
              onPressed: () => _aprobarPublicacion(publicacion['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Aprobar'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => _eliminarPublicacion(publicacion['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _aprobarPublicacion(String serviceId) async {
    try {
      await _supabase
          .from('servicios')
          .update({'status': 'activa'})
          .eq('id', serviceId);

      final res = await _supabase.functions.invoke(
        'notificar-servicio',
        body: {'service_id': serviceId},
      );

      debugPrint(res.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación aprobada')));

      Navigator.pop(context); // Cerrar diálogo
      _cargarPublicaciones(); // Recargar lista
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _eliminarPublicacion(String serviceId) async {
    final confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Eliminar publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _supabase
            .from('servicios')
            .update({'status': 'eliminada'})
            .eq('id', serviceId);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Publicación eliminada')));

        Navigator.pop(context); // Cerrar diálogo
        _cargarPublicaciones(); // Recargar lista
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rechazarPublicacion(
    String serviceId,
    BuildContext dialogContext,
  ) async {
    final razonController = TextEditingController();

    final razon = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Razón del rechazo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: razonController,
              decoration: const InputDecoration(
                hintText: 'Explica por qué se rechaza esta publicación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta información será visible para el usuario.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final razonText = razonController.text.trim();
              Navigator.pop(
                context,
                razonText.isNotEmpty ? razonText : 'Razón no especificada',
              );
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (razon == null) return;

    if (_processingAction) return;
    _processingAction = true;
    if (mounted) setState(() {});

    try {
      await _supabase
          .from('servicios')
          .update({
            'status': 'rechazada',
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', serviceId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación rechazada'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      await _cargarPublicaciones();

      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      debugPrint('Error al rechazar publicación: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _processingAction = false;
      if (mounted) setState(() {});
    }
  }

  Widget _buildListaPublicaciones(
    List<Map<String, dynamic>> publicaciones,
    bool esPendiente,
  ) {
    if (publicaciones.isEmpty) {
      return const Center(child: Text('No hay publicaciones'));
    }

    return ListView.builder(
      itemCount: publicaciones.length,
      itemBuilder: (context, index) {
        final pub = publicaciones[index];

        // Estado como texto simple
        final estado = pub['status'] == 'pendiente' ? 'PENDIENTE' : 'APROBADA';
        final estadoColor = pub['status'] == 'pendiente'
            ? Colors.orange
            : Colors.green;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(
              pub['titulo'] ?? 'Sin título',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  estado,
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pub['descripcion']?.length > 100
                      ? '${pub['descripcion'].substring(0, 100)}...'
                      : pub['descripcion'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID Usuario: ${pub['user_id']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Fecha: ${pub['creado_en']?.toString().substring(0, 10) ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _mostrarDetallePublicacion(pub, esPendiente),
          ),
        );
      },
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
              'Error al cargar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage.length > 100
                        ? '${_errorMessage.substring(0, 100)}...'
                        : _errorMessage
                  : 'Ocurrió un error inesperado',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _cargarPublicaciones,
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
        title: const Text('Publicaciones'),
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.check_circle),
                    text: 'Aprobadas (${_filteredAprobadas.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.pending),
                    text: 'Pendientes (${_filteredPendientes.length})',
                  ),
                ],
              ),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _cargarPublicaciones,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Recargar',
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
                  Text(
                    'Cargando publicaciones...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _hasError
          ? _buildErrorView()
          : Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar publicaciones...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filtrarPublicaciones();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => _filtrarPublicaciones(),
                  ),
                ),

                // Filtros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Orden: $_sortOption',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _mostrarFiltros,
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filtrar'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListaPublicaciones(_filteredAprobadas, false),
                      _buildListaPublicaciones(_filteredPendientes, true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
