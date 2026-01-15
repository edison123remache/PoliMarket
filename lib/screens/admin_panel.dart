import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:randimarket/services/api_service.dart';

// Importaciones de tus pantallas (asumiendo que los nombres son correctos)
import 'usuarios_admin_panel.dart';
import 'publicaciones_admin_panel.dart';
import 'reportes_admin_panel.dart';
import 'publicaciones_rechazadas_admin_panel.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _totalUsuarios = 0;
  int _totalPublicaciones = 0;
  int _reportesPendientes = 0;
  int _publicacionesPendientes = 0;
  int _publicacionesRechazadas = 0;
  bool _isDownloading = false;

  // Colores Premium
  final Color primaryColor = const Color(0xFFFF6B35); // Naranja vibrante
  final Color accentColor = const Color(0xFF6A4FB3); // Morado profundo
  final Color bgColor = const Color(0xFFF8F9FD); // Blanco azulado suave

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final u = await _supabase.from('perfiles').count(CountOption.exact);
      final p = await _supabase
          .from('servicios')
          .count(CountOption.exact)
          .eq('status', 'activa');
      final r = await _supabase
          .from('reportes')
          .count(CountOption.exact)
          .eq('status', 'pendiente');
      final pen = await _supabase
          .from('servicios')
          .count(CountOption.exact)
          .eq('status', 'pendiente');
      final rec = await _supabase
          .from('servicios')
          .count(CountOption.exact)
          .eq('status', 'rechazada');

      if (mounted) {
        setState(() {
          _totalUsuarios = u;
          _totalPublicaciones = p;
          _reportesPendientes = r;
          _publicacionesPendientes = pen;
          _publicacionesRechazadas = rec;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _irAPantalla(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) => _cargarEstadisticas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Panel de Control',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildWelcomeHeader(),
            const SizedBox(height: 25),

            // Sección de Estadísticas Principales
            Row(
              children: [
                _buildMainStatCard(
                  'Usuarios',
                  _totalUsuarios.toString(),
                  Icons.group_rounded,
                  Colors.blue.shade400,
                  () => _irAPantalla(const UsuariosAdminScreen()),
                ),
                const SizedBox(width: 15),
                _buildMainStatCard(
                  'Activas',
                  _totalPublicaciones.toString(),
                  Icons.auto_awesome_mosaic_rounded,
                  primaryColor,
                  () => _irAPantalla(const PublicacionesAdminScreen()),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              'Gestión de Pendientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 15),

            // Lista de acciones de gestión
            _buildActionTile(
              title: 'Reportes de Usuarios',
              subtitle: 'Conflictos y denuncias',
              count: _reportesPendientes,
              icon: Icons.flag_rounded,
              color: Colors.red.shade400,
              onTap: () => _irAPantalla(const ReportesAdminScreen()),
            ),
            _buildActionTile(
              title: 'Aprobaciones Pendientes',
              subtitle: 'Nuevas publicaciones por revisar',
              count: _publicacionesPendientes,
              icon: Icons.pending_actions_rounded,
              color: Colors.amber.shade700,
              onTap: () => _irAPantalla(const PublicacionesAdminScreen()),
            ),
            _buildActionTile(
              title: 'Historial de Rechazos',
              subtitle: 'Publicaciones no aprobadas',
              count: _publicacionesRechazadas,
              icon: Icons.unpublished_rounded,
              color: Colors.grey.shade600,
              onTap: () =>
                  _irAPantalla(const PublicacionesRechazadasAdminScreen()),
            ),

            const SizedBox(height: 40),

            // Botón de Reporte PDF
            _buildDownloadButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, Administrador 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const Text(
          'Aquí tienes el resumen de hoy.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMainStatCard(
    String title,
    String val,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 15),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: count > 0 ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: count > 0 ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    // Definimos el color naranja de tu marca para asegurar consistencia
    final Color brandOrange = const Color(0xFFFF6B35);

    return SizedBox(
      width: double.infinity,
      height: 58, // Altura optimizada para accesibilidad táctil
      child: ElevatedButton.icon(
        onPressed: _isDownloading ? null : _downloadAndOpenPdf,
        icon: _isDownloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.document_scanner_outlined,
                color: Colors.white,
                size: 22,
              ),
        label: Text(
          _isDownloading ? 'GENERANDO...' : 'DESCARGAR REPORTE PDF',
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w800, // Fuente más gruesa para un look profesional
            color: Colors.white,
            letterSpacing: 1.2, // Espaciado moderno entre letras
          ),
        ),
        style:
            ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: brandOrange.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Bordes suavizados
              ),
              elevation: 0, // Diseño plano y limpio (Flat Design)
              shadowColor: brandOrange.withOpacity(0.3),
            ).copyWith(
              // Añade un efecto de elevación sutil solo cuando se presiona
              elevation: WidgetStateProperty.resolveWith<double>(
                (states) => states.contains(WidgetState.pressed) ? 4 : 0,
              ),
            ),
      ),
    );
  }

  Future<void> _downloadAndOpenPdf() async {
    setState(() => _isDownloading = true);

    try {
      final path = await ApiService.downloadPdf();
      setState(() => _isDownloading = false);

      if (path != null) {
        await OpenFile.open(path);
      } else {
        _showErrorSnackBar('No se pudo localizar el archivo generado.');
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      _showErrorSnackBar('Error de conexión al servidor.');
    }
  }

  // Función auxiliar para mantener el código limpio
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
