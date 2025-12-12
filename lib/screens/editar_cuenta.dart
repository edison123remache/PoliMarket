import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'admin_panel.dart';

class AjustesCuentaScreen extends StatefulWidget {
  const AjustesCuentaScreen({super.key});

  @override
  State<AjustesCuentaScreen> createState() => _AjustesCuentaScreenState();
}

class _AjustesCuentaScreenState extends State<AjustesCuentaScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService(Supabase.instance.client);
  final ImagePicker _picker = ImagePicker();

  File? _nuevaFoto;
  TextEditingController _bioController = TextEditingController();
  bool _isLoading = true;
  bool _guardando = false;
  Map<String, dynamic>? _perfil;
  String? _rolActual; // Solo para lectura

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final perfilData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _perfil = perfilData;
        _bioController.text = perfilData['bio'] ?? '';
        _rolActual = perfilData['rol'] ?? 'user';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (foto != null) {
        setState(() {
          _nuevaFoto = File(foto.path);
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar foto: $e');
    }
  }

  Future<void> _subirFotoPerfil() async {
    if (_nuevaFoto == null) return;

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final fileName =
          'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('avatars').upload(fileName, _nuevaFoto!);

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await _supabase
          .from('perfiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      setState(() {
        _perfil?['avatar_url'] = publicUrl;
      });

      _mostrarExito('Foto de perfil actualizada');
    } catch (e) {
      _mostrarError('Error al subir foto: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (_bioController.text.length > 140) {
      _mostrarError('La biografía no puede tener más de 140 caracteres');
      return;
    }

    setState(() => _guardando = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Actualizar biografía y avatar
      await _supabase
          .from('perfiles')
          .update({
            'bio': _bioController.text.trim(),
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Subir foto si hay una nueva
      if (_nuevaFoto != null) {
        await _subirFotoPerfil();
      }

      _mostrarExito('Cambios guardados correctamente');

      // Simplemente regresar a la pantalla anterior
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error al guardar cambios: $e');
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _mostrarDialogoCambioAModoAdmin() {
    final bool esAdmin = _rolActual == 'admin';

    if (esAdmin) {
      // Si ya es admin, mostrar diálogo para ir al panel de admin
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ir al Panel de Administración'),
          content: const Text('¿Quieres acceder al panel de administración?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _irAlPanelAdmin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir al Panel'),
            ),
          ],
        ),
      );
    } else {
      // Si no es admin, mostrar que no tiene permisos
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Acceso Denegado'),
          content: const Text(
            'No tienes permisos de administrador. '
            'Solo los usuarios administradores pueden acceder al panel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _irAlPanelAdmin() async {
    // Guardar cambios primero si hay cambios pendientes
    final bool hayCambios =
        _bioController.text != (_perfil?['bio'] ?? '') || _nuevaFoto != null;

    if (hayCambios) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text(
            'Tienes cambios sin guardar. '
            '¿Quieres guardar los cambios antes de ir al panel de administración?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar y continuar'),
            ),
          ],
        ),
      );

      if (confirmado == true) {
        await _guardarCambios();
      }
    }

    // Navegar al panel de administración
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminPanel()),
      (route) => false, // Limpiar el stack
    );
  }

  void _confirmarGuardarCambios() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Cambios'),
        content: const Text('¿Estás seguro de guardar los cambios realizados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarCambios();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _cancelar() {
    final bool hayCambios =
        _bioController.text != (_perfil?['bio'] ?? '') || _nuevaFoto != null;

    if (hayCambios) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar cambios?'),
          content: const Text(
            'Tienes cambios sin guardar. ¿Estás seguro de salir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  Widget _buildEstadoRol() {
    final bool esAdmin = _rolActual == 'admin';

    return GestureDetector(
      onTap: () {
        if (esAdmin) {
          // Si es admin, mostrar opciones
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Administrador'),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarDialogoCambioAModoAdmin();
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: esAdmin
              ? const Color.fromARGB(255, 243, 186, 79).withOpacity(0.1)
              : const Color.fromARGB(255, 109, 109, 109).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esAdmin
                ? const Color.fromARGB(255, 231, 106, 48)
                : const Color.fromARGB(255, 109, 109, 109),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Text(
              'Cambiar modo de usuario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: esAdmin
                    ? const Color.fromARGB(255, 231, 106, 48)
                    : const Color.fromARGB(255, 109, 109, 109),
              ),
            ),
            if (esAdmin) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_drop_down,
                color: Color.fromARGB(255, 231, 106, 48),
              ),
            ],
          ],
        ),
      ),
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

    final String? avatarUrl = _perfil?['avatar_url'];
    final String nombre = _perfil?['nombre'] ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelar,
        ),
        title: const Text('Ajustes de Cuenta'),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de perfil editable
            _buildSeccionFotoPerfil(avatarUrl, nombre),
            const SizedBox(height: 32),

            // Biografía editable
            _buildSeccionBiografia(),
            const SizedBox(height: 32),

            // Estado del rol (con opciones desplegables si es admin)
            const SizedBox(height: 4),
            _buildEstadoRol(),

            // Botones de acción
            const SizedBox(height: 24),
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFotoPerfil(String? avatarUrl, String nombre) {
    return Center(
      child: Stack(
        children: [
          // Foto de perfil
          GestureDetector(
            onTap: _seleccionarFoto,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF6B35), width: 3),
              ),
              child: ClipOval(
                child: _nuevaFoto != null
                    ? Image.file(_nuevaFoto!, fit: BoxFit.cover)
                    : avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFFFB088),
                        child: Center(
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Indicador de edición
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _seleccionarFoto,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionBiografia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre Mí',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cuéntale a la comunidad sobre ti (máx. 140 caracteres)',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLength: 140,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Inserte su descripción...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
            counterText: '${_bioController.text.length}/140',
            counterStyle: TextStyle(
              color: _bioController.text.length > 140
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Text(
          'Proporciona a los usuarios una breve descripción de quien eres y que ofreces.\nPor ejemplo: De donde vienes, carrera y cuales son tus fortalezas.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    final bool hayCambios =
        _bioController.text != (_perfil?['bio'] ?? '') || _nuevaFoto != null;

    return Column(
      children: [
        if (hayCambios) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tienes cambios sin guardar',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelar,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _guardando || !hayCambios
                    ? null
                    : _confirmarGuardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hayCambios
                      ? const Color(0xFFFF6B35)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        hayCambios ? 'Guardar Cambios' : 'Sin cambios',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
