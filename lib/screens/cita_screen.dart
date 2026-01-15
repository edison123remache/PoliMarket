import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cita_model.dart';
import '../services/cita_service.dart';
import 'citas_detalles_dialog.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final CitaService _citaService = CitaService();
  final ScrollController _scrollController = ScrollController();

  List<Cita> _citas = [];
  List<Cita> _citasPasadas = [];
  List<Cita> _citasHoy = [];
  List<Cita> _citasFuturas = [];

  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    _currentUserId = user?.id;

    if (_currentUserId != null) {
      _cargarCitas();
    }
  }

  Future<void> _cargarCitas() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await _citaService.getCitasAceptadas();

      final citas = data
          .map((map) => Cita.fromMap(map, _currentUserId!))
          .toList();

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      // Mantenemos tu lógica exacta de filtrado
      _citasPasadas = citas.where((c) => c.fecha.isBefore(hoy)).toList();
      _citasHoy = citas
          .where(
            (c) =>
                c.fecha.year == hoy.year &&
                c.fecha.month == hoy.month &&
                c.fecha.day == hoy.day,
          )
          .toList();
      _citasFuturas = citas.where((c) => c.fecha.isAfter(hoy)).toList();

      _citasPasadas.sort((a, b) => b.fecha.compareTo(a.fecha));
      _citasHoy.sort((a, b) => a.hora.hour.compareTo(b.hora.hour));
      _citasFuturas.sort((a, b) => a.fecha.compareTo(b.fecha));

      setState(() {
        _citas = citas;
      });

      await _obtenerNombresUsuarios();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando citas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al sincronizar con el servidor'),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _obtenerNombresUsuarios() async {
    for (final cita in _citas) {
      if (cita.otroUsuarioId == null) continue;

      try {
        final perfil = await Supabase.instance.client
            .from('perfiles')
            .select('nombre')
            .eq('id', cita.otroUsuarioId!)
            .single();

        final index = _citas.indexWhere((c) => c.id == cita.id);

        if (index != -1) {
          setState(() {
            _citas[index] = Cita(
              id: cita.id,
              chatId: cita.chatId,
              propuestoPor: cita.propuestoPor,
              fecha: cita.fecha,
              hora: cita.hora,
              ubicacion: cita.ubicacion,
              detalles: cita.detalles,
              estado: cita.estado,
              creadoEn: cita.creadoEn,
              chatInfo: cita.chatInfo,
              perfilInfo: cita.perfilInfo,
              servicioInfo: cita.servicioInfo,
              esPropietario: cita.esPropietario,
              otroUsuarioId: cita.otroUsuarioId,
              otroUsuarioNombre: perfil['nombre'] ?? 'Usuario',
            );
          });
        }
      } catch (e) {
        debugPrint('Error obteniendo nombre: $e');
      }
    }
  }

  String _obtenerNombreDisplay(Cita cita) {
    if (cita.otroUsuarioNombre != null && cita.otroUsuarioNombre != 'Usuario') {
      return cita.otroUsuarioNombre!;
    }
    if (cita.servicioInfo != null && cita.servicioInfo!['titulo'] != null) {
      return cita.servicioInfo!['titulo'];
    }
    if (cita.perfilInfo != null && cita.perfilInfo!['nombre'] != null) {
      return cita.perfilInfo!['nombre'];
    }
    return 'Cita Pendiente';
  }

  void _mostrarDetallesCita(Cita cita) async {
    final detallesCompletos = await _citaService.getCitaDetallada(cita.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CitaDetallesDialog(cita: cita, detallesCompletos: detallesCompletos),
    );
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients || _citasHoy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay citas programadas para hoy'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double posicion = 0;
    if (_citasPasadas.isNotEmpty) {
      // Cálculo aproximado basado en la nueva altura de las tarjetas
      posicion += 60 + (_citasPasadas.length * 110);
    }

    _scrollController.animateTo(
      posicion,
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Mi Agenda',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cargarCitas,
            icon: const Icon(Icons.sync, color: Colors.orange),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 2,
              ),
            )
          : _citas.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              color: Colors.orange,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                children: [
                  _buildSeccion('PASADAS', _citasPasadas, Colors.grey),
                  _buildSeccion('PARA HOY', _citasHoy, Colors.orange),
                  _buildSeccion(
                    'PRÓXIMAS',
                    _citasFuturas,
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scrollToToday,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 4,
        icon: const Icon(Icons.today_rounded, color: Colors.white),
        label: const Text(
          'Ir a hoy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No hay citas agendadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tus citas aceptadas aparecerán aquí',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Cita> citas, Color colorTema) {
    if (citas.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: colorTema,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(color: colorTema.withOpacity(0.2), thickness: 1),
              ),
              const SizedBox(width: 10),
              Text(
                '${citas.length}',
                style: TextStyle(
                  color: colorTema.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...citas.map((cita) => _buildCitaCard(cita)),
      ],
    );
  }

  Widget _buildCitaCard(Cita cita) {
    final bool esPasada = cita.esPasada;
    final String horaStr =
        '${cita.hora.hour}:${cita.hora.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _mostrarDetallesCita(cita),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de Hora
                Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: esPasada
                        ? Colors.grey.shade50
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        horaStr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: esPasada
                              ? Colors.grey
                              : Colors.orange.shade800,
                        ),
                      ),
                      const Text(
                        'AM/PM',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _obtenerNombreDisplay(cita),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: esPasada
                              ? Colors.grey
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cita.ubicacion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cita.detalles != null &&
                          cita.detalles!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          cita.detalles!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange.shade300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Botón de estado
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
