import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';
import '../services/location_service.dart';
import 'profile_screen.dart';

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
  String? _mapaUrl;
  double? _latitud;
  double? _longitud;
  int _currentImageIndex = 0;

  // --- Paleta de colores naranja atractiva ---
  final Color _primaryColor = const Color(0xFFF5501D); // Naranja vibrante
  final Color _secondaryColor = const Color(0xFFFF6B35); // Naranja claro
  final Color _lightOrange = const Color(0xFFFFE8E0); // Naranja muy claro
  final Color _backgroundColor = const Color(0xFFFAFAFA); // Fondo blanco suave
  final Color _cardColor = Colors.white;
  final Color _textHeading = const Color(0xFF1A1A1A); // Negro suave
  final Color _textBody = const Color(0xFF5A5A5A); // Gris medio
  final Color _gradientStart = const Color(0xFFFF6B35);
  final Color _gradientEnd = const Color(0xFFF5501D);
  final Color _verifiedBlue = const Color(0xFF2196F3); // Azul para verificado

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final servicioData = await _supabase
          .from('servicios')
          .select()
          .eq('id', widget.servicioId)
          .single();

      final vendedorData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', servicioData['user_id'])
          .single();

      String? mapaUrlGenerado;
      double? lat, lon;

      if (servicioData['lat'] != null && servicioData['lon'] != null) {
        lat = (servicioData['lat'] is String)
            ? double.parse(servicioData['lat'])
            : (servicioData['lat'] as num).toDouble();

        lon = (servicioData['lon'] is String)
            ? double.parse(servicioData['lon'])
            : (servicioData['lon'] as num).toDouble();

        try {
          mapaUrlGenerado = LocationServiceIQ.getStaticMapUrl(lat, lon);
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _servicio = servicioData;
        _vendedor = UserModel.fromJson(vendedorData);
        _mapaUrl = mapaUrlGenerado;
        _latitud = lat;
        _longitud = lon;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE REPORTE Y MENÚ ---
  void _mostrarMenuOpciones() {
    if (_servicio == null) return;

    final currentUser = _authService.currentUser;
    // Si es mi publicación, ya tengo el botón grande de eliminar abajo.
    // Si NO es mi publicación, muestro la opción de reportar.
    if (currentUser?.id == _servicio!['user_id']) {
      _confirmarYEliminar();
    } else {
      _mostrarReporteDialog();
    }
  }

  void _mostrarReporteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReporteDialog(
        servicioId: widget.servicioId,
        primaryColor: _primaryColor,
        textHeading: _textHeading,
        onReportado: () {
          _mostrarSnackBar('Reporte enviado correctamente', Icons.check_circle);
        },
      ),
    );
  }
  // ---------------------------------

  Future<void> _contactarVendedor() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _mostrarSnackBar(
        "Inicia sesión para contactar",
        Icons.login,
        isError: true,
      );
      return;
    }
    final vendedorId = _servicio!['user_id'];
    if (currentUser.id == vendedorId) {
      _mostrarSnackBar(
        "Es tu propia publicación",
        Icons.info_outline,
        isError: true,
      );
      return;
    }
    try {
      final chatId = await ChatService.instance.getOrCreateChat(
        user1Id: currentUser.id,
        user2Id: vendedorId,
        serviceId: widget.servicioId,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: vendedorId,
            servicioId: _servicio!['id'],
            servicioTitulo: _servicio!['titulo'],
            servicioPrecio: '0',
            servicioFotoUrl: (_servicio!['fotos'] as List).isNotEmpty
                ? (_servicio!['fotos'] as List).first
                : null,
          ),
        ),
      );
    } catch (e) {
      _mostrarSnackBar("Error al chat", Icons.error, isError: true);
    }
  }

  Future<void> _confirmarYEliminar() async {
    final bool? confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 36,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const Text(
                  "Eliminar servicio",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "¿Estás seguro de que deseas eliminar este servicio? Esta acción no se puede deshacer.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tenga en cuenta:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• El servicio será eliminado permanentemente\n• Todas las imágenes se borrarán\n• No podrás recuperar esta información",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Eliminar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
      ),
    );

    if (confirmar != true) return;

    try {
      if (!mounted) return;

      // Intentar limpiar dependencias primero (Cascada manual)
      // Ignoramos errores aquí porque puede que no existan o no tengamos permisos,
      // pero intentamos limpiar lo que sea posible.
      try {
        await _supabase
            .from('reportes')
            .delete()
            .eq('service_id', widget.servicioId);
      } catch (_) {}

      try {
        await _supabase
            .from('chats')
            .delete()
            .eq('service_id', widget.servicioId);
      } catch (_) {}

      // Verificamos si hay otras tablas relacionadas comunes
      try {
        await _supabase
            .from('calificaciones')
            .delete()
            .eq('service_id', widget.servicioId);
      } catch (_) {}

      // Finalmente borramos el servicio
      await _supabase.from('servicios').delete().eq('id', widget.servicioId);

      if (!mounted) return;

      _mostrarSnackBar('Servicio eliminado exitosamente', Icons.check_circle);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      debugPrint('Error al eliminar: $e');
      _mostrarSnackBar('Error al eliminar: $e', Icons.error, isError: true);
    }
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _confirmarYEliminar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_outline, size: 22),
            SizedBox(width: 10),
            Text(
              "Eliminar publicación",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _irAlPerfil() {
    if (_vendedor == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: _vendedor!.id)),
    );
  }

  void _mostrarSnackBar(
    String mensaje,
    IconData icono, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : _primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: _primaryColor,
                backgroundColor: _primaryColor.withOpacity(0.1),
              ),
              const SizedBox(height: 20),
              Text(
                'Cargando servicio...',
                style: TextStyle(color: _textBody, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    if (_servicio == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Servicio no encontrado',
                style: TextStyle(
                  fontSize: 18,
                  color: _textBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<String> fotos = List<String>.from(_servicio!['fotos'] ?? []);
    final bool esMiPublicacion =
        _authService.currentUser?.id == _servicio!['user_id'];

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. APP BAR ATTRACTIVA CON GRADIENTE
              SliverAppBar(
                expandedHeight: 400.0,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading:
                    false, // Botón back eliminado de aquí
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCarruselFotos(fotos),
                      // Gradiente naranja sutil
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // INDICADORES FLOTANTES AGREGADOS
                      if (fotos.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: _buildImageIndicator(fotos.length),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. CONTENIDO PRINCIPAL ATTRACTIVO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de disponibilidad elegante
                      _buildAvailabilityBadge(),
                      const SizedBox(height: 16),

                      // Título con efecto de sombra suave
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _lightOrange.withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _servicio!['titulo'],
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textHeading,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tarjeta Vendedor elegante (solo con verificado)
                      _buildVendorCard(),

                      const SizedBox(height: 28),

                      // Sección Descripción minimalista
                      _buildSectionTitle("Descripción"),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(),

                      const SizedBox(height: 32),

                      // Sección Ubicación mejorada
                      _buildSectionTitle("Ubicación"),
                      const SizedBox(height: 12),
                      _buildLocationCard(),

                      // Espacio para publicaciones propias
                      if (esMiPublicacion) ...[
                        const SizedBox(height: 40),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 4. BOTONES FLOTANTES SUPERIORES (FIJOS)
          // Botón Atrás
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: _primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Botón Opciones (Solo si NO es mi publicación, ya que el dueño tiene botón abajo)
          if (!esMiPublicacion)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: _primaryColor),
                  onPressed: _mostrarMenuOpciones,
                ),
              ),
            ),

          // 3. BARRA INFERIOR ATTRACTIVA
          if (!esMiPublicacion)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildCarruselFotos(List<String> fotos) {
    if (fotos.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_lightOrange, _secondaryColor.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_rounded,
                size: 70,
                color: _primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin imágenes',
                style: TextStyle(
                  color: _primaryColor.withOpacity(0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: fotos.length,
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      itemBuilder: (context, index) {
        return Hero(
          tag: 'servicio_${_servicio!['id']}_$index',
          child: CachedNetworkImage(
            imageUrl: fotos[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_lightOrange, _primaryColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_lightOrange, Colors.grey[100]!],
                ),
              ),
              child: Icon(
                Icons.photo_rounded,
                size: 70,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      },
    );
  }

  // INDICADORES FLOTANTES AGREGADOS
  Widget _buildImageIndicator(int totalImages) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            totalImages,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentImageIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentImageIndex == index
                    ? _primaryColor
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor.withOpacity(0.9), _secondaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "DISPONIBLE AHORA",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textHeading,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _irAlPerfil,
          borderRadius: BorderRadius.circular(18),
          hoverColor: _primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar del vendedor con borde naranja
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryColor, width: 2),
                  ),
                  child: ClipOval(
                    child: _vendedor!.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _vendedor!.avatarUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color: _lightOrange,
                              child: Icon(
                                Icons.person_rounded,
                                color: _primaryColor,
                              ),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: _lightOrange,
                            child: Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: _primaryColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Información del vendedor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vendedor!.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textHeading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // SOLO VERIFICADO - sin 100+ likes
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _verifiedBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: _verifiedBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Usuario Verificado",
                                  style: TextStyle(
                                    color: _verifiedBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

                // Flecha indicadora
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lightOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOLO LA DESCRIPCIÓN - sin íconos adicionales
          Text(
            _servicio!['descripcion'] ?? 'No hay descripción disponible.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: _textBody,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = _latitud != null && _longitud != null;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado mejorado
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lightOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation
                            ? "Ubicación del servicio"
                            : "Ubicación no disponible",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textHeading,
                        ),
                      ),
                      if (hasLocation) const SizedBox(height: 4),
                      Text(
                        "Zona aproximada donde se ofrece el servicio",
                        style: TextStyle(color: _textBody, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mapa o placeholder
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _lightOrange.withOpacity(0.3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasLocation && _mapaUrl != null)
                  CachedNetworkImage(
                    imageUrl: _mapaUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryColor,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(color: _lightOrange),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 50,
                              color: _primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Error al cargar el mapa",
                              style: TextStyle(
                                color: _primaryColor.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(color: _lightOrange),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 60,
                            color: _primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Mapa no disponible",
                            style: TextStyle(
                              color: _primaryColor.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Botón para abrir Maps
                if (hasLocation)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Material(
                      borderRadius: BorderRadius.circular(30),
                      elevation: 4,
                      child: InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=$_latitud,$_longitud",
                          );
                          try {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {
                            _mostrarSnackBar(
                              "No se pudo abrir el mapa",
                              Icons.error,
                              isError: true,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 18,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Abrir en Maps",
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, -10),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ElevatedButton(
        onPressed: _contactarVendedor,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStart, _gradientEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            height: 62,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Contactar al vendedor",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- WIDGET DIALOGO DE REPORTE (Avanzado) -----------------
class _ReporteDialog extends StatefulWidget {
  final String servicioId;
  final VoidCallback onReportado;
  final Color primaryColor;
  final Color textHeading;

  const _ReporteDialog({
    required this.servicioId,
    required this.onReportado,
    required this.primaryColor,
    required this.textHeading,
  });

  @override
  State<_ReporteDialog> createState() => __ReporteDialogState();
}

class __ReporteDialogState extends State<_ReporteDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _enviandoReporte = false;
  String? _selectedReason;

  final List<String> _razones = [
    'Esta publicación es Estafa/Spam',
    'Esta publicación Tiene una Información Imprecisa',
    'Esta publicación restringe las Normas',
    'Esta publicación incita al Acoso, odio o Violencia',
    'Esta publicación contiene Desnudos o Actividad sexual',
  ];

  Future<void> _enviarReporte() async {
    if (_selectedReason == null) return;
    if (!mounted) return;
    setState(() => _enviandoReporte = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Enviar directamente la razón seleccionada (sin mapeo)
      await _supabase.from('reportes').insert({
        'reporter_id': user.id,
        'service_id': widget.servicioId,
        'razones': _selectedReason,
        'status': 'pendiente',
      });

      if (!mounted) return;
      widget.onReportado();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enviandoReporte = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Reportar publicación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: widget.textHeading,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _razones.length,
                separatorBuilder: (ctx, i) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final r = _razones[index];
                  return RadioListTile<String>(
                    value: r,
                    groupValue: _selectedReason,
                    onChanged: (val) => setState(() => _selectedReason = val),
                    activeColor: const Color(0xFFF5501D),
                    title: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (!_enviandoReporte && _selectedReason != null)
                          ? _enviarReporte
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        disabledBackgroundColor: widget.primaryColor
                            .withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _enviandoReporte
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enviar Reporte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
