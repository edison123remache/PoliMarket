import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tutorial_policies_screen.dart';

import '../services/location_service.dart';

class SubirServicioScreen extends StatefulWidget {
  const SubirServicioScreen({super.key});

  @override
  State<SubirServicioScreen> createState() => _SubirServicioScreenState();
}

class _SubirServicioScreenState extends State<SubirServicioScreen>
    with SingleTickerProviderStateMixin {
  final List<File> _fotos = [];
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  double? _lat;
  double? _lon;
  bool _isLoading = false;
  bool _obteniendoUbicacion = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos permitidas');
      return;
    }

    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (foto != null) {
        setState(() {
          _fotos.add(File(foto.path));
        });
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                const SizedBox(height: 28),
                const Text(
                  'Agregar Fotografías',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Selecciona cómo deseas añadir las imágenes',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                _buildOpcionFoto(
                  icon: Icons.photo_library_rounded,
                  titulo: 'Galería',
                  descripcion:
                      'Selecciona hasta ${3 - _fotos.length} fotos de tu dispositivo',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarFotos();
                  },
                ),
                const SizedBox(height: 16),
                _buildOpcionFoto(
                  icon: Icons.camera_alt_rounded,
                  titulo: 'Cámara',
                  descripcion: 'Toma una foto nueva ahora mismo',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8E53), Color(0xFFFFB088)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _tomarFoto();
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
            border: Border.all(
              color: const Color(0xFFFF6B35).withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
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

  Future<void> _seleccionarFotos() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos permitidas');
      return;
    }

    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (selectedImages.isNotEmpty) {
        int availableSlots = 3 - _fotos.length;
        int imagesToAdd = selectedImages.length > availableSlots
            ? availableSlots
            : selectedImages.length;

        for (int i = 0; i < imagesToAdd; i++) {
          _fotos.add(File(selectedImages[i].path));
        }

        setState(() {});
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imágenes: $e');
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  Future<void> _obtenerUbicacionAutomatica() async {
    setState(() => _obteniendoUbicacion = true);

    try {
      final position = await LocationServiceIQ.getCurrentLocation();
      final address = await LocationServiceIQ.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // 🔥 Verificar mounted antes de actualizar estado
      if (!mounted) return;

      setState(() {
        _ubicacionController.text = address;
        _lat = position.latitude;
        _lon = position.longitude;
      });

      _mostrarExito('Ubicación obtenida correctamente');
    } catch (e) {
      // 🔥 Verificar mounted antes de mostrar error
      if (!mounted) return;
      _mostrarError('Error al obtener ubicación: $e');
    } finally {
      // 🔥 Verificar mounted antes de actualizar estado
      if (mounted) {
        setState(() => _obteniendoUbicacion = false);
      }
    }
  }

  Future<List<String>> _subirFotos() async {
    List<String> fotoUrls = [];
    final supabase = Supabase.instance.client;

    for (var foto in _fotos) {
      final fileName =
          'servicios/${DateTime.now().millisecondsSinceEpoch}_${foto.path.split('/').last}';

      try {
        await supabase.storage.from('service-photos').upload(fileName, foto);

        final publicUrl = supabase.storage
            .from('service-photos')
            .getPublicUrl(fileName);

        fotoUrls.add(publicUrl);
      } catch (e) {
        throw Exception('Error al subir foto: $e');
      }
    }

    return fotoUrls;
  }

  Future<void> _guardarServicio() async {
    if (_fotos.isEmpty) {
      _mostrarError('Agrega al menos una foto');
      return;
    }

    if (_tituloController.text.trim().isEmpty) {
      _mostrarError('El título es requerido');
      return;
    }

    if (_descripcionController.text.trim().isEmpty) {
      _mostrarError('La descripción es requerida');
      return;
    }

    if (_ubicacionController.text.trim().isEmpty) {
      _mostrarError('La ubicación es requerida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fotoUrls = await _subirFotos();
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception('Usuario no autenticado');

      final servicioResponse = await supabase
          .from('servicios')
          .insert({
            'user_id': user.id,
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'ubicacion': _ubicacionController.text.trim(),
            'lat': _lat,
            'lon': _lon,
            'fotos': fotoUrls,
            'status': 'pendiente',
            'numero_de_reportes': 0,
          })
          .select('id')
          .single();

      final String serviceId = servicioResponse['id'];

      // 🔥 IMPORTANTE: No hacer await aquí para que no bloquee
      supabase.functions
          .invoke('notificar-servicio', body: {'service_id': serviceId})
          .catchError((error) {
            // Solo loguear el error, no mostrar al usuario
            debugPrint('Error al notificar servicio: $error');
          });

      // 🔥 Verificar mounted antes de mostrar mensaje
      if (!mounted) return;

      _mostrarExito(
        'Tu publicación ha sido enviada para revisión. '
        'Será aprobada por un administrador pronto.',
      );

      await Future.delayed(const Duration(seconds: 2));

      // 🔥 Verificar mounted antes de navegar
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error al guardar servicio: $e');

      // 🔥 Verificar mounted antes de mostrar error
      if (!mounted) return;
      _mostrarError('Error al guardar servicio: $e');
    } finally {
      // 🔥 Verificar mounted antes de actualizar estado
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarExito(String mensaje) {
    // 🔥 Verificar mounted antes de usar context
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    // 🔥 Verificar mounted antes de usar context
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _cancelar() {
    if (_fotos.isNotEmpty ||
        _tituloController.text.isNotEmpty ||
        _descripcionController.text.isNotEmpty ||
        _ubicacionController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[300]!, Colors.orange[500]!],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¿Descartar publicación?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Se perderá todo el contenido que has agregado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: Colors.grey[300]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Descartar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
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
    } else {
      Navigator.pop(context);
    }
  }

  void _verPoliticas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TutorialPoliciesScreen(
          // Cambié 'initialType' por 'type' para que coincida con tu clase
          type: TutorialPolicyType.politicasPublicacion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 18,
              ),
              onPressed: _cancelar,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
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
                    const Color(0xFFFF6B35).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8E53).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFFFF6B35),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Publicando tu servicio...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esto puede tardar unos momentos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildForm(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSeccionFotos(),
          const SizedBox(height: 28),
          _buildSeccionTitulo(),
          const SizedBox(height: 28),
          _buildSeccionDescripcion(),
          const SizedBox(height: 28),
          _buildSeccionUbicacion(),
          const SizedBox(height: 32),
          _buildTextoInformativo(),
          const SizedBox(height: 32),
          _buildBotones(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva Publicación',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.1,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Comparte tus servicios con la comunidad',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionFotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Fotografías',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.15),
                    const Color(0xFFFF8E53).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_fotos.length}/3',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B35),
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Agrega hasta 3 imágenes de alta calidad para mostrar tu servicio',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              ..._fotos.asMap().entries.map((entry) {
                final index = entry.key;
                final foto = entry.value;
                return _buildFotoCard(foto, index);
              }),
              if (_fotos.length < 3) _buildAgregarFotoCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoCard(File foto, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.file(foto, width: 140, height: 160, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _eliminarFoto(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarFotoCard() {
    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Container(
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            width: 2.5,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.15),
                    const Color(0xFFFF8E53).withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 36,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Agregar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF6B35),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo() {
    final longitudActual = _tituloController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Título',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: longitudActual >= 35
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: longitudActual >= 35
                      ? Colors.red.withOpacity(0.3)
                      : const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                '$longitudActual/40',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: longitudActual >= 35
                      ? Colors.red
                      : const Color(0xFFFF6B35),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Un título claro y descriptivo ayuda a destacar tu publicación',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _tituloController,
            maxLength: 40,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Reparación de computadoras a domicilio',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              counterText: '',
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionDescripcion() {
    final longitudActual = _descripcionController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: longitudActual >= 2000
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: longitudActual >= 2000
                      ? Colors.red.withOpacity(0.3)
                      : const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                '$longitudActual/2030',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: longitudActual >= 2000
                      ? Colors.red
                      : const Color(0xFFFF6B35),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Describe detalladamente tu servicio, incluye precios y condiciones',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _descripcionController,
            maxLength: 2030,
            maxLines: 6,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe tu servicio: experiencia, horarios, precios, método de pago, zona de cobertura, etc.',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              counterText: '',
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionUbicacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Obtén tu ubicación automáticamente con GPS',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _obteniendoUbicacion ? null : _obtenerUbicacionAutomatica,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[200]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _obteniendoUbicacion
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _ubicacionController.text.isEmpty
                        ? (_obteniendoUbicacion
                              ? 'Obteniendo ubicación...'
                              : 'Usar mi ubicación actual')
                        : _ubicacionController.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: _ubicacionController.text.isEmpty
                          ? Colors.grey[600]
                          : Colors.black87,
                      fontWeight: _ubicacionController.text.isEmpty
                          ? FontWeight.w600
                          : FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (!_obteniendoUbicacion)
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 22,
                    color: const Color(0xFFFF6B35),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextoInformativo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revisión Requerida',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu publicación será revisada según nuestras políticas (hasta 24h).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    final bool formularioCompleto =
        _fotos.isNotEmpty &&
        _tituloController.text.trim().isNotEmpty &&
        _descripcionController.text.trim().isNotEmpty &&
        _ubicacionController.text.trim().isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelar,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: BorderSide(color: Colors.grey[300]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: formularioCompleto
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        )
                      : LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: formularioCompleto
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton.icon(
                  onPressed: formularioCompleto ? _guardarServicio : null,
                  icon: Icon(
                    Icons.cloud_upload_rounded,
                    size: 24,
                    color: formularioCompleto ? Colors.white : Colors.grey[600],
                  ),
                  label: Text(
                    'Publicar Servicio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: formularioCompleto
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _verPoliticas,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Ver Política de Publicación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                    decoration: TextDecoration.underline,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
