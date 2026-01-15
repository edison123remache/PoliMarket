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

  // --- PALETA DE COLORES PREMIUM ---
  final Color _brandOrange = const Color(0xFFFF6B00); // Naranja vibrante
  final Color _brandWhite = Colors.white;
  final Color _bgLight = const Color(0xFFFAFAFA); // Blanco casi puro
  final Color _textDark = const Color(0xFF1A1A1A);

  // Variables de lógica (INTACTAS)
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
  //int _currentTab = 0;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(() {
        //if (mounted) setState(() => _currentTab = _tabController.index);
      });
    } catch (e) {
      debugPrint('Error TabController: $e');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPublicaciones();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS (NO SE TOCA, SOLO SE OPTIMIZA VISUALIZACIÓN) ---
  Future<void> _cargarPublicaciones() async {
    if (!mounted || _isRefreshing) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _isRefreshing = true;
    });

    try {
      final response = await _supabase
          .from('servicios')
          .select('''
      id, titulo, descripcion, status, creado_en, user_id, fotos,
      perfiles:perfiles (id, nombre, email, avatar_url),
      reportes:reportes(count),
      numero_de_reportes
    ''')
          .order('creado_en', ascending: false)
          .limit(50);

      if (!mounted) return;

      _publicaciones = List<Map<String, dynamic>>.from(response).map((p) {
        return {
          ...p,
          'reportes_count':
              p['numero_de_reportes'] ?? p['reportes']?[0]?['count'] ?? 0,
        };
      }).toList();

      _separarPublicaciones();
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        _isRefreshing = false;
      });
    }
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
      _publicacionesAprobadas = [];
      _publicacionesPendientes = [];
    }
  }

  void _filtrarPublicaciones() {
    if (!mounted) return;
    setState(() {
      String searchTerm = _searchController.text.trim().toLowerCase();

      bool filterFunc(Map<String, dynamic> pub) {
        final titulo = (pub['titulo'] as String?)?.toLowerCase() ?? '';
        final desc = (pub['descripcion'] as String?)?.toLowerCase() ?? '';
        final user =
            (pub['perfiles']?['nombre'] as String?)?.toLowerCase() ?? '';
        if (searchTerm.isEmpty) return true;
        return titulo.contains(searchTerm) ||
            desc.contains(searchTerm) ||
            user.contains(searchTerm);
      }

      _filteredAprobadas = _publicacionesAprobadas.where(filterFunc).toList();
      _filteredPendientes = _publicacionesPendientes.where(filterFunc).toList();
      _aplicarOrdenamiento();
    });
  }

  void _aplicarOrdenamiento() {
    // Misma lógica de ordenamiento
    try {
      int Function(Map<String, dynamic>, Map<String, dynamic>)? sorter;
      switch (_sortOption) {
        case 'Más recientes':
          sorter = (a, b) =>
              (b['creado_en'] ?? '').compareTo(a['creado_en'] ?? '');
          break;
        case 'Más antiguos':
          sorter = (a, b) =>
              (a['creado_en'] ?? '').compareTo(b['creado_en'] ?? '');
          break;
        case 'A-Z':
          sorter = (a, b) => (a['titulo'] ?? '').compareTo(b['titulo'] ?? '');
          break;
        case 'Z-A':
          sorter = (a, b) => (b['titulo'] ?? '').compareTo(a['titulo'] ?? '');
          break;
        case 'Más reportadas':
          sorter = (a, b) => ((b['reportes_count'] ?? 0) as int).compareTo(
            (a['reportes_count'] ?? 0) as int,
          );
          break;
        case 'Menos reportadas':
          sorter = (a, b) => ((a['reportes_count'] ?? 0) as int).compareTo(
            (b['reportes_count'] ?? 0) as int,
          );
          break;
      }
      if (sorter != null) {
        _filteredAprobadas.sort(sorter);
        _filteredPendientes.sort(sorter);
      }
    } catch (e) {
      debugPrint('Error orden: $e');
    }
  }

  // --- ACCIONES DE SUPABASE (Lógica de negocio) ---
  Future<void> _aprobarPublicacion(String serviceId) async {
    try {
      await _supabase
          .from('servicios')
          .update({'status': 'activa'})
          .eq('id', serviceId);
      // ignore: unused_local_variable
      final res = await _supabase.functions.invoke(
        'notificar-servicio',
        body: {'service_id': serviceId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Publicación aprobada con éxito!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
        _cargarPublicaciones();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rechazarPublicacion(
    String serviceId,
    BuildContext dialogContext,
  ) async {
    final razonController = TextEditingController();
    final razon = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motivo del rechazo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: razonController,
          decoration: InputDecoration(
            hintText: 'Explica por qué no cumple las normas...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              razonController.text.trim().isNotEmpty
                  ? razonController.text.trim()
                  : 'Sin motivo',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Confirmar Rechazo'),
          ),
        ],
      ),
    );

    if (razon == null) return;

    try {
      await _supabase
          .from('servicios')
          .update({
            'status': 'rechazada',
            'motivo_rechazo': razon,
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', serviceId);

      await _supabase.functions.invoke(
        'notificar-servicio',
        body: {'service_id': serviceId, 'razon': razon},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicación rechazada'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _cargarPublicaciones();
        if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _eliminarPublicacion(String serviceId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar definitivamente?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _supabase
            .from('servicios')
            .update({'status': 'eliminada'})
            .eq('id', serviceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eliminada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
          _cargarPublicaciones();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- UI WIDGETS MEJORADOS ---

  Widget _buildStatusBadge(String status) {
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
            isPending ? Icons.access_time_filled : Icons.check_circle,
            size: 14,
            color: isPending ? Colors.orange.shade800 : Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isPending ? 'Revisión Pendiente' : 'Activa',
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

  void _mostrarDetallePublicacion(Map<String, dynamic> pub, bool esPendiente) {
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
            // Handle bar
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
                      _buildStatusBadge(pub['status'] ?? 'unknown'),
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
                    pub['titulo'] ?? 'Sin título',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Perfil Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              pub['perfiles']?['avatar_url'] != null
                              ? NetworkImage(pub['perfiles']['avatar_url'])
                              : null,
                          child: pub['perfiles']?['avatar_url'] == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pub['perfiles']?['nombre'] ?? 'Usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                pub['perfiles']?['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              pub['creado_en']?.toString().substring(0, 10) ??
                                  '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pub['descripcion'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[800],
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),

                  if (pub['fotos'] != null &&
                      (pub['fotos'] as List).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Galería',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (pub['fotos'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              pub['fotos'][index],
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 140,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Botones de acción fijos abajo
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
                child: Row(
                  children: [
                    if (esPendiente) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _rechazarPublicacion(pub['id'], context),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _aprobarPublicacion(pub['id']),
                          icon: const Icon(Icons.check),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _eliminarPublicacion(pub['id']),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar Publicación'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
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

  Widget _buildList(List<Map<String, dynamic>> lista, bool esPendiente) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: Colors.orange.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay publicaciones aquí',
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
        final pub = lista[index];
        final reportes = pub['reportes_count'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _brandWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _mostrarDetallePublicacion(pub, esPendiente),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _brandOrange.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[100],
                            backgroundImage:
                                pub['perfiles']?['avatar_url'] != null
                                ? NetworkImage(pub['perfiles']['avatar_url'])
                                : null,
                            child: pub['perfiles']?['avatar_url'] == null
                                ? Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Textos Header
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pub['titulo'] ?? 'Sin título',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Por ${pub['perfiles']?['nombre'] ?? 'Desconocido'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge Status Pequeño
                        if (reportes > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$reportes',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Descripción
                    Text(
                      pub['descripcion'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(pub['status'] ?? ''),
                        Text(
                          pub['creado_en']?.toString().substring(0, 10) ?? '',
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
            surfaceTintColor: _brandWhite, // Evita tinte morado en Material 3
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Administración',
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
                onPressed: _cargarPublicaciones,
                icon: _isRefreshing
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
              IconButton(
                icon: Icon(Icons.sort_rounded, color: _textDark),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Ordenar por',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ...[
                            'Más recientes',
                            'Más antiguos',
                            'A-Z',
                            'Z-A',
                            'Más reportadas',
                          ].map(
                            (o) => ListTile(
                              title: Text(o),
                              trailing: _sortOption == o
                                  ? Icon(Icons.check, color: _brandOrange)
                                  : null,
                              onTap: () {
                                setState(() => _sortOption = o);
                                _filtrarPublicaciones();
                                Navigator.pop(c);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: _brandOrange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _brandOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Aprobadas (${_filteredAprobadas.length})'),
                      Tab(text: 'Pendientes (${_filteredPendientes.length})'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Buscador Flotante
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filtrarPublicaciones(),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, usuario...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _brandOrange, width: 1),
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
              ),
            ),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _brandOrange),
                    )
                  : _hasError
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_filteredAprobadas, false),
                        _buildList(_filteredPendientes, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
