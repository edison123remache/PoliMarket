import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = true;
  String _sortOption = 'Más recientes';
  String _filterRole = 'Todos';
  final double _minRating = 0;
  final double _maxRating = 5;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // --- LÓGICA DE DATOS ---
  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('perfiles')
          .select('''
            *,
            servicios:servicios(count),
            reportes:reportes!reporter_id(count)
          ''')
          .order('creado_en', ascending: false);

      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(response);
        _filteredUsuarios = List.from(_usuarios);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filtrarUsuarios() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredUsuarios = _usuarios.where((u) {
        final matchesSearch =
            searchTerm.isEmpty ||
            (u['nombre'] ?? '').toLowerCase().contains(searchTerm) ||
            (u['email'] ?? '').toLowerCase().contains(searchTerm);

        final rolUsuario = (u['rol'] ?? '').toString().toLowerCase();
        final matchesRole =
            _filterRole == 'Todos' || rolUsuario == _filterRole.toLowerCase();

        final rating = (u['rating_avg'] as num?)?.toDouble() ?? 0.0;
        return matchesSearch &&
            matchesRole &&
            rating >= _minRating &&
            rating <= _maxRating;
      }).toList();
      _aplicarOrdenamiento();
    });
  }

  void _aplicarOrdenamiento() {
    switch (_sortOption) {
      case 'A-Z':
        _filteredUsuarios.sort(
          (a, b) => (a['nombre'] ?? '').compareTo(b['nombre'] ?? ''),
        );
        break;
      case 'Más calificados':
        _filteredUsuarios.sort(
          (a, b) => (b['rating_avg'] ?? 0.0).compareTo(a['rating_avg'] ?? 0.0),
        );
        break;
      case 'Más recientes':
        _filteredUsuarios.sort(
          (a, b) => (b['creado_en'] ?? '').compareTo(a['creado_en'] ?? ''),
        );
        break;
    }
  }

  // --- INTERFAZ (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Usuarios LlamaMarket",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargarUsuarios,
            icon: const Icon(Icons.sync_rounded, color: Color(0xFFFF6B35)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  )
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _statItem("Total", _usuarios.length.toString(), Colors.blue),
          _statItem(
            "Admins",
            _usuarios.where((u) => u['rol'] == 'admin').length.toString(),
            Colors.deepPurple,
          ),
          _statItem(
            "Top",
            _usuarios
                .where((u) => (u['rating_avg'] ?? 0) >= 4.5)
                .length
                .toString(),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filtrarUsuarios(),
                decoration: const InputDecoration(
                  hintText: "Buscar por nombre o email...",
                  prefixIcon: Icon(Icons.search, color: Color(0xFFFF6B35)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: _mostrarFiltros,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsuarios.isEmpty) {
      return const Center(child: Text("Sin resultados"));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsuarios.length,
      itemBuilder: (context, index) {
        final u = _filteredUsuarios[index];
        final isAdmin = u['rol'] == 'admin';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
              backgroundImage: u['avatar_url'] != null
                  ? NetworkImage(u['avatar_url'])
                  : null,
              child: u['avatar_url'] == null
                  ? Text(
                      u['nombre'][0],
                      style: const TextStyle(color: Color(0xFFFF6B35)),
                    )
                  : null,
            ),
            title: Text(
              u['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                _miniBadge(
                  isAdmin ? "ADMIN" : "USER",
                  isAdmin ? Colors.purple : Colors.blue,
                ),
                const SizedBox(width: 6),
                _miniBadge("${u['rating_avg'] ?? 0} ★", Colors.orange),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => _mostrarDetalleUsuario(u),
          ),
        );
      },
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- MODAL DE FILTROS ---
  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Opciones de Filtro",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: ['Todos', 'Admin', 'User']
                    .map(
                      (r) => ChoiceChip(
                        label: Text(r),
                        selected: _filterRole == r,
                        onSelected: (s) {
                          setState(() => _filterRole = r);
                          setMState(() {});
                        },
                        selectedColor: const Color(0xFFFF6B35),
                        labelStyle: TextStyle(
                          color: _filterRole == r ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text("Ordenar por"),
              DropdownButton<String>(
                value: _sortOption,
                isExpanded: true,
                items: ['Más recientes', 'A-Z', 'Más calificados'].map((
                  String s,
                ) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) {
                  setState(() => _sortOption = v!);
                  setMState(() {});
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    _filtrarUsuarios();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "APLICAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIÁLOGO DE DETALLE ---
  void _mostrarDetalleUsuario(Map<String, dynamic> u) {
    final servicios = u['servicios']?[0]['count'] ?? 0;
    final reportes = u['reportes']?[0]['count'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header elegante
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFFF8C42), const Color(0xFFFF6B35)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Patrón decorativo
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(painter: _CirclePatternPainter()),
                      ),
                    ),
                    // Badge de rol
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              u['rol'] == 'admin'
                                  ? Icons.verified_rounded
                                  : Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              u['rol'] == 'admin' ? 'ADMIN' : 'USER',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Avatar
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFF3F4F6),
                            backgroundImage: u['avatar_url'] != null
                                ? NetworkImage(u['avatar_url'])
                                : null,
                            child: u['avatar_url'] == null
                                ? Text(
                                    u['nombre'][0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF667EEA),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // Nombre y Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      u['nombre'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              u['email'],
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Estadísticas elegantes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _estadisticaCard(
                        icon: Icons.shopping_bag_outlined,
                        label: "Servicios",
                        value: servicios.toString(),
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _estadisticaCard(
                        icon: Icons.outlined_flag_rounded,
                        label: "Reportes",
                        value: reportes.toString(),
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _estadisticaCard(
                        icon: Icons.star_outline_rounded,
                        label: "Rating",
                        value: (u['rating_avg'] ?? 0.0).toStringAsFixed(1),
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  color: const Color(0xFFE5E7EB),
                  thickness: 1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 20),
              // Botones de acción
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _cambiarRol(u),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              u['rol'] == 'admin'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              u['rol'] == 'admin'
                                  ? "Bajar a User"
                                  : "Subir a Admin",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () => _confirmarBorrado(u['id']),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        tooltip: "Eliminar usuario",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadisticaCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- ACCIONES SUPABASE ---
  Future<void> _cambiarRol(Map<String, dynamic> user) async {
    final nuevoRol = user['rol'] == 'admin' ? 'user' : 'admin';
    await _supabase
        .from('perfiles')
        .update({'rol': nuevoRol})
        .eq('id', user['id']);
    Navigator.pop(context);
    _cargarUsuarios();
  }

// Reemplaza el método _confirmarBorrado con este:

// Reemplaza el método _confirmarBorrado con este:

Future<void> _confirmarBorrado(String id) async {
  // Primero cierra el diálogo de detalle
  Navigator.pop(context);
  
  // Muestra un diálogo de confirmación
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
          SizedBox(width: 10),
          Text('¿Eliminar usuario?'),
        ],
      ),
      content: const Text(
        'Esta acción desactivará el usuario. ¿Estás seguro?',
        style: TextStyle(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  // Si confirmó, procede a eliminar
  if (confirmar == true) {
    try {
      // Opción 1: Si quieres ELIMINAR permanentemente
      await _supabase
          .from('perfiles')
          .delete()
          .eq('id', id);
      
      // Opción 2: Si tienes columna 'activo', descomenta esto:
      // await _supabase
      //     .from('perfiles')
      //     .update({'activo': false})
      //     .eq('id', id);
      
      // Muestra mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario desactivado correctamente'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Recarga la lista
      await _cargarUsuarios();
    } catch (e) {
      // Muestra mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
}

// Custom painter para el patrón decorativo del header
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dibuja círculos decorativos
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 20, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
