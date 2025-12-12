import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cita_service.dart';
import '../models/cita_model.dart';
import 'citas_detalles_dialog.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AgendaScreenState();
  }
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

      // Convertir a objetos Cita
      final citas = data
          .map((map) => Cita.fromMap(map, _currentUserId!))
          .toList();

      // Clasificar citas
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      _citasPasadas = citas.where((c) => c.fecha.isBefore(hoy)).toList();
      _citasHoy = citas.where((c) => c.fecha.isAtSameMomentAs(hoy)).toList();
      _citasFuturas = citas.where((c) => c.fecha.isAfter(hoy)).toList();

      // Ordenar cada categoría
      _citasPasadas.sort(
        (a, b) => b.fecha.compareTo(a.fecha),
      ); // Más reciente primero
      _citasHoy.sort((a, b) => a.hora.hour.compareTo(b.hora.hour));
      _citasFuturas.sort((a, b) => a.fecha.compareTo(b.fecha));

      // Obtener nombres de otros usuarios (si es necesario)
      await _obtenerNombresUsuarios();

      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando citas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar citas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _obtenerNombresUsuarios() async {
    for (var cita in _citas) {
      if (cita.otroUsuarioId != null) {
        try {
          final perfil = await Supabase.instance.client
              .from('perfiles')
              .select('nombre')
              .eq('id', cita.otroUsuarioId!)
              .single();

          // Actualizar el nombre en la cita
          final index = _citas.indexWhere((c) => c.id == cita.id);
          if (index != -1) {
            final citaActualizada = Cita(
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
            _citas[index] = citaActualizada;
          }
        } catch (e) {
          print('Error obteniendo nombre: $e');
        }
      }
    }
  }

  String _obtenerNombreDisplay(Cita cita) {
    // 1. Si hay nombre del otro usuario, usarlo
    if (cita.otroUsuarioNombre != null && cita.otroUsuarioNombre != 'Usuario') {
      return cita.otroUsuarioNombre!;
    }

    // 2. Si hay título del servicio, usarlo
    if (cita.servicioInfo != null && cita.servicioInfo!['titulo'] != null) {
      return cita.servicioInfo!['titulo'];
    }

    // 3. Nombre del perfil que propuso
    if (cita.perfilInfo != null && cita.perfilInfo!['nombre'] != null) {
      return cita.perfilInfo!['nombre'];
    }

    // 4. Por defecto
    return 'Cita';
  }

  void _mostrarDetallesCita(Cita cita) async {
    final detallesCompletos = await _citaService.getCitaDetallada(cita.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CitaDetallesDialog(cita: cita, detallesCompletos: detallesCompletos),
    );
  }

  Widget _buildSeccion(String titulo, List<Cita> citas, Color colorTitulo) {
    if (citas.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            '$titulo (${citas.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorTitulo,
            ),
          ),
        ),
        ...citas.map((cita) => _buildCitaItem(cita)),
      ],
    );
  }

  Widget _buildCitaItem(Cita cita) {
    final esPasada = cita.esPasada;

    return GestureDetector(
      onTap: () => _mostrarDetallesCita(cita),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: esPasada ? Colors.grey[100] : Colors.orange.shade50,
          border: Border.all(
            color: esPasada ? Colors.grey[400]! : Colors.orange,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Hora
            Container(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${cita.hora.hour}:${cita.hora.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: esPasada ? Colors.grey[600]! : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aceptada',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _obtenerNombreDisplay(cita),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: esPasada ? Colors.grey[700] : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: esPasada ? Colors.grey : Colors.grey[700],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cita.ubicacion,
                          style: TextStyle(
                            fontSize: 13,
                            color: esPasada
                                ? Colors.grey[600]
                                : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (cita.detalles != null && cita.detalles!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        cita.detalles!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: esPasada ? Colors.grey[500] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.chevron_right,
              color: esPasada ? Colors.grey : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _citas.isEmpty
                ? 'No tienes citas programadas'
                : 'No hay citas para hoy',
          ),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // Verificar si hay citas hoy
    if (_citasHoy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay citas para hoy'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    double calcularPosicionHoy() {
      double posicion = 0.0;
      const alturaSeccion = 40.0; // Altura del título de sección
      const alturaCita = 120.0; // Altura aproximada de cada cita

      if (_citasPasadas.isNotEmpty) {
        posicion += alturaSeccion + (_citasPasadas.length * alturaCita);
      }
      posicion += 20.0;

      return posicion;
    }

    _scrollController.animateTo(
      calcularPosicionHoy(),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tus citas'), centerTitle: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : _citas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No tienes citas aceptadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Las citas que aceptes aparecerán aquí',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarCitas,
              color: Colors.orange,
              child: ListView(
                controller: _scrollController,
                children: [
                  _buildSeccion('Pasadas', _citasPasadas, Colors.grey),
                  _buildSeccion('Hoy', _citasHoy, Colors.orange),
                  _buildSeccion('Próximas', _citasFuturas, Colors.green),
                  SizedBox(height: 20),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToToday,
        backgroundColor: Color(0xFFFF6B35),
        child: Icon(Icons.today, color: Colors.white),
      ),
    );
  }
}
