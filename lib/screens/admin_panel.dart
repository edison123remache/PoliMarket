import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'usuarios_admin_panel.dart';
import 'publicaciones_admin_panel.dart';
import 'reportes_admin_panel.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Variables para estadísticas (Inician en 0, sin ruedas de carga)
  int _totalUsuarios = 0;
  int _totalPublicaciones = 0;
  int _reportesPendientes = 0;
  int _publicacionesPendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  // Carga los datos en segundo plano y actualiza los números cuando termina
  Future<void> _cargarEstadisticas() async {
    try {
      final usuariosCount = await _supabase
          .from('perfiles')
          .count(CountOption.exact);

      final publicacionesCount = await _supabase
          .from('servicios')
          .count(CountOption.exact);

      final reportesCount = await _supabase
          .from('reportes')
          .count(CountOption.exact)
          .eq('status', 'pendiente');

      final pendientesCount = await _supabase
          .from('servicios')
          .count(CountOption.exact)
          .eq('status', 'pendiente');

      if (mounted) {
        setState(() {
          _totalUsuarios = usuariosCount;
          _totalPublicaciones = publicacionesCount;
          _reportesPendientes = reportesCount;
          _publicacionesPendientes = pendientesCount;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  // Función auxiliar para navegar
  void _irAPantalla(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    ).then((_) => _cargarEstadisticas());
  }

  @override
  Widget build(BuildContext context) {
    // Colores basados en tu imagen
    final Color colorBorde = const Color(0xFFFF6B35); // Naranja fuerte
    final Color colorFondoPendientes = const Color(
      0xFFD7CCC8,
    ); // Café/Rosado suave

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Panel administrativo'),
        actions: [
        ],
      ),
      // SafeArea evita que se solape con la barra de notificaciones
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TARJETAS SUPERIORES (Usuarios y Publicaciones)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      titulo: 'Total de\nUsuarios:',
                      cantidad: _totalUsuarios,
                      bordeColor: colorBorde,
                      onTap: () => _irAPantalla(const UsuariosAdminScreen()),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoCard(
                      titulo: 'Total de\nPublicaciones:',
                      cantidad: _totalPublicaciones,
                      bordeColor: colorBorde,
                      onTap: () =>
                          _irAPantalla(const PublicacionesAdminScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 3. SECCIÓN DE REPORTES PENDIENTES
              const Text(
                'Reportes Pendientes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // Botón Reportes Usuarios
              _buildPendienteButton(
                texto: 'Reportes de Usuarios',
                cantidad: _reportesPendientes,
                colorFondo: colorFondoPendientes,
                onTap: () => _irAPantalla(const ReportesAdminScreen()),
              ),

              const SizedBox(height: 15),

              // Botón Publicaciones Pendientes
              _buildPendienteButton(
                texto: 'Publicaciones Pendientes',
                cantidad: _publicacionesPendientes,
                colorFondo: colorFondoPendientes,
                onTap: () => _irAPantalla(const PublicacionesAdminScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET 1: Tarjetas cuadradas naranjas de arriba
  Widget _buildInfoCard({
    required String titulo,
    required int cantidad,
    required Color bordeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, // Altura fija para que sean cuadradas
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE), // Gris muy claro de fondo
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bordeColor,
            width: 3,
          ), // Borde grueso naranja
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            Text(
              cantidad.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET 2: Botones rectangulares de pendientes
  Widget _buildPendienteButton({
    required String texto,
    required int cantidad,
    required Color colorFondo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: colorFondo, // El color café/rosado de la imagen
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$texto ($cantidad)', // Muestra el texto y el número entre paréntesis
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
