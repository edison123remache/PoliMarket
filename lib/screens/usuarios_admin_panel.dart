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
  double _minRating = 0;
  double _maxRating = 5;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

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
        _filteredUsuarios = _usuarios;
        _isLoading = false;
      });
    } catch (e) {
      // Error handling
      setState(() => _isLoading = false);
    }
  }

  void _filtrarUsuarios() {
    String searchTerm = _searchController.text.toLowerCase();

    setState(() {
      _filteredUsuarios = _usuarios.where((usuario) {
        final nombre = usuario['nombre']?.toString().toLowerCase() ?? '';
        final email = usuario['email']?.toString().toLowerCase() ?? '';

        // Filtro de búsqueda
        bool matchesSearch =
            nombre.contains(searchTerm) || email.contains(searchTerm);

        // Filtro por rol
        bool matchesRole =
            _filterRole == 'Todos' ||
            usuario['rol'] == _filterRole.toLowerCase();

        // Filtro por calificación
        final rating = usuario['rating_avg'] ?? 0.0;
        bool matchesRating = rating >= _minRating && rating <= _maxRating;

        return matchesSearch && matchesRole && matchesRating;
      }).toList();

      // Aplicar ordenamiento
      _aplicarOrdenamiento();
    });
  }

  void _aplicarOrdenamiento() {
    switch (_sortOption) {
      case 'Más recientes':
        _filteredUsuarios.sort(
          (a, b) =>
              (b['creado_en'] as String).compareTo(a['creado_en'] as String),
        );
        break;
      case 'Más antiguos':
        _filteredUsuarios.sort(
          (a, b) =>
              (a['creado_en'] as String).compareTo(b['creado_en'] as String),
        );
        break;
      case 'A-Z':
        _filteredUsuarios.sort(
          (a, b) => (a['nombre'] ?? '').compareTo(b['nombre'] ?? ''),
        );
        break;
      case 'Z-A':
        _filteredUsuarios.sort(
          (a, b) => (b['nombre'] ?? '').compareTo(a['nombre'] ?? ''),
        );
        break;
      case 'Más calificados':
        _filteredUsuarios.sort(
          (a, b) => ((b['rating_avg'] ?? 0.0) as double).compareTo(
            (a['rating_avg'] ?? 0.0) as double,
          ),
        );
        break;
      case 'Menos calificados':
        _filteredUsuarios.sort(
          (a, b) => ((a['rating_avg'] ?? 0.0) as double).compareTo(
            (b['rating_avg'] ?? 0.0) as double,
          ),
        );
        break;
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filtrar Usuarios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Filtro por rol
                const Text(
                  'Rol:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: ['Todos', 'Admin', 'User'].map((rol) {
                    return ChoiceChip(
                      label: Text(rol),
                      selected: _filterRole == rol,
                      onSelected: (selected) {
                        setState(() => _filterRole = rol);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Rango de calificación
                const Text(
                  'Rango de Calificación:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: RangeValues(_minRating, _maxRating),
                  min: 0,
                  max: 5,
                  divisions: 10,
                  labels: RangeLabels('$_minRating', '$_maxRating'),
                  onChanged: (values) {
                    setState(() {
                      _minRating = values.start;
                      _maxRating = values.end;
                    });
                  },
                ),
                Text('De $_minRating a $_maxRating estrellas'),

                const SizedBox(height: 20),

                // Ordenamiento
                const Text(
                  'Ordenar por:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  children:
                      [
                        'Más recientes',
                        'Más antiguos',
                        'A-Z',
                        'Z-A',
                        'Más calificados',
                        'Menos calificados',
                      ].map((option) {
                        return RadioListTile(
                          title: Text(option),
                          value: option,
                          groupValue: _sortOption,
                          onChanged: (value) {
                            setState(() => _sortOption = value!);
                          },
                        );
                      }).toList(),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _filtrarUsuarios();
                          Navigator.pop(context);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _filterRole = 'Todos';
                            _minRating = 0;
                            _maxRating = 5;
                            _sortOption = 'Más recientes';
                          });
                          _filtrarUsuarios();
                          Navigator.pop(context);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalleUsuario(Map<String, dynamic> usuario) {
    final serviciosCount = usuario['servicios']?[0]['count'] ?? 0;
    final reportesCount = usuario['reportes']?[0]['count'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario['nombre']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (usuario['avatar_url'] != null)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(usuario['avatar_url']),
                  ),
                ),
              const SizedBox(height: 10),

              Text('Email: ${usuario['email']}'),
              Text('Rol: ${usuario['rol']}'),
              if (usuario['bio'] != null) Text('Bio: ${usuario['bio']}'),

              const SizedBox(height: 15),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        serviciosCount.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Servicios'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        reportesCount.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Reportes'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        (usuario['rating_avg'] ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Calificación'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (usuario['rol'] != 'admin')
            ElevatedButton(
              onPressed: () => _deshabilitarUsuario(usuario['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Deshabilitar'),
            ),
          ElevatedButton(
            onPressed: () => _cambiarRolUsuario(usuario),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              usuario['rol'] == 'admin' ? 'Quitar Admin' : 'Hacer Admin',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deshabilitarUsuario(String userId) async {
    final confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshabilitar Usuario'),
        content: const Text('¿Estás seguro de deshabilitar este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deshabilitar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        // Aquí puedes marcar al usuario como inactivo o eliminarlo
        // Por ejemplo, agregar un campo 'activo' a la tabla perfiles
        await _supabase
            .from('perfiles')
            .update({'activo': false})
            .eq('id', userId);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario deshabilitado')));

        _cargarUsuarios();
        Navigator.pop(context); // Cerrar el diálogo de detalle
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cambiarRolUsuario(Map<String, dynamic> usuario) async {
    final nuevoRol = usuario['rol'] == 'admin' ? 'user' : 'admin';

    try {
      await _supabase
          .from('perfiles')
          .update({'rol': nuevoRol})
          .eq('id', usuario['id']);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rol cambiado a $nuevoRol')));

      _cargarUsuarios();
      Navigator.pop(context); // Cerrar el diálogo de detalle
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Registrados'),
        actions: [
          IconButton(
            onPressed: _cargarUsuarios,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuarios...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => _filtrarUsuarios(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _mostrarFiltros,
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filtrar y ordenar',
                ),
              ],
            ),
          ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredUsuarios.length} usuarios encontrados',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Orden: $_sortOption',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsuarios.isEmpty
                ? const Center(child: Text('No se encontraron usuarios'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredUsuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = _filteredUsuarios[index];
                      final serviciosCount =
                          usuario['servicios']?[0]['count'] ?? 0;
                      final rating = usuario['rating_avg'] ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: usuario['avatar_url'] != null
                                ? NetworkImage(usuario['avatar_url'])
                                : null,
                            child: usuario['avatar_url'] == null
                                ? Text(usuario['nombre'][0])
                                : null,
                          ),
                          title: Text(usuario['nombre']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(usuario['email']),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(usuario['rol']),
                                    backgroundColor: usuario['rol'] == 'admin'
                                        ? Colors.deepPurple.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.2),
                                  ),
                                  const SizedBox(width: 5),
                                  Chip(
                                    label: Text('$serviciosCount servicios'),
                                  ),
                                  const SizedBox(width: 5),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      Text(' ${rating.toStringAsFixed(1)}'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _mostrarDetalleUsuario(usuario),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
