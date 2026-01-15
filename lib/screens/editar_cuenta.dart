import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

class AjustesCuentaScreen extends StatefulWidget {
  const AjustesCuentaScreen({super.key});

  @override
  State<AjustesCuentaScreen> createState() => _AjustesCuentaScreenState();
}

class _AjustesCuentaScreenState extends State<AjustesCuentaScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService(Supabase.instance.client);
  final ImagePicker _picker = ImagePicker();

  File? _nuevaFoto;
  final _bioController = TextEditingController();
  bool _isLoading = true;
  bool _guardando = false;
  Map<String, dynamic>? _perfil;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bioController.dispose();
    super.dispose();
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cambiar Foto de Perfil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige cómo actualizar tu imagen',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _buildOpcionFoto(
                  icon: Icons.photo_library_rounded,
                  titulo: 'Galería',
                  descripcion: 'Selecciona una foto existente',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _tomarFoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 16),
                _buildOpcionFoto(
                  icon: Icons.camera_alt_rounded,
                  titulo: 'Cámara',
                  descripcion: 'Toma una nueva foto',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _tomarFoto(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionFoto({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
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

      await _supabase
          .from('perfiles')
          .update({
            'bio': _bioController.text.trim(),
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_nuevaFoto != null) {
        await _subirFotoPerfil();
      }

      _mostrarExito('Cambios guardados correctamente');

      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error al guardar cambios: $e');
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _confirmarGuardarCambios() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            borderRadius: BorderRadius.circular(28),
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
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¿Guardar Cambios?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tus cambios serán guardados de forma permanente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _guardarCambios();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _cancelar() {
    final bool hayCambios =
        _bioController.text != (_perfil?['bio'] ?? '') || _nuevaFoto != null;

    if (hayCambios) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey[50]!],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[300]!, Colors.orange[500]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Descartar cambios?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tienes cambios sin guardar que se perderán',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Descartar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.pop(context, false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF6B35).withOpacity(0.1),
                const Color(0xFFFF8E53).withOpacity(0.05),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF6B35)),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    final String? avatarUrl = _perfil?['avatar_url'];
    final String nombre = _perfil?['nombre'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: _cancelar,
            ),
          ),
        ),
        actions: [
          if (_guardando)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Fondo animado con gradientes
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.05),
                    const Color(0xFFFF8E53).withOpacity(0.03),
                    Colors.white.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          // Círculos decorativos
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8E53).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildSeccionFotoPerfil(avatarUrl, nombre),
                      const SizedBox(height: 36),
                      _buildSeccionBiografia(),
                      const SizedBox(height: 40),
                      _buildBotonesAccion(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personaliza tu perfil y experiencia',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionFotoPerfil(String? avatarUrl, String nombre) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              // Anillo animado exterior
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.2),
                      const Color(0xFFFF8E53).withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              // Foto de perfil
              GestureDetector(
                onTap: _seleccionarFoto,
                child: Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _nuevaFoto != null
                        ? Image.file(_nuevaFoto!, fit: BoxFit.cover)
                        : avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFFF8E53),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                nombre.isNotEmpty
                                    ? nombre[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              // Botón de editar con efecto pulsante
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _seleccionarFoto,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.1),
                  const Color(0xFFFF8E53).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_rounded,
                  size: 16,
                  color: const Color(0xFFFF6B35).withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  _authService.currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionBiografia() {
    final longitudActual = _bioController.text.length;
    final porcentaje = (longitudActual / 140) * 100;
    final color = porcentaje >= 90
        ? Colors.red
        : porcentaje >= 70
        ? Colors.orange
        : const Color(0xFFFF6B35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Biografía',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Cuéntanos sobre ti y comparte tus intereses con la comunidad',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: porcentaje >= 90
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _bioController,
                maxLength: 140,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  letterSpacing: -0.2,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Ej: Amante de la tecnología 💻 | Fotógrafo aficionado 📸 | Siempre aprendiendo algo nuevo ✨',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                  counterText: '',
                ),
                onChanged: (value) => setState(() {}),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: longitudActual / 140,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$longitudActual/140',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    final bool hayCambios =
        _bioController.text != (_perfil?['bio'] ?? '') || _nuevaFoto != null;

    return Column(
      children: [
        if (hayCambios)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange[50]!,
                  Colors.orange[100]!.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cambios pendientes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recuerda guardar tus cambios',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _cancelar,
                    borderRadius: BorderRadius.circular(20),
                    child: const Center(
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 60,
                decoration: BoxDecoration(
                  gradient: hayCambios
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        )
                      : LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: hayCambios
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_guardando || !hayCambios)
                        ? null
                        : _confirmarGuardarCambios,
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: _guardando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_rounded,
                                  color: hayCambios
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  hayCambios
                                      ? 'Guardar Cambios'
                                      : 'Sin cambios',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hayCambios
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
