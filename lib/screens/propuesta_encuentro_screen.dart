import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/chat_service.dart';
import '../services/location_service.dart';

class PropuestaEncuentroScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const PropuestaEncuentroScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<PropuestaEncuentroScreen> createState() =>
      _PropuestaEncuentroScreenState();
}

class _PropuestaEncuentroScreenState extends State<PropuestaEncuentroScreen> {
  DateTime? _fecha;
  TimeOfDay? _hora;
  final _ubicacionCtrl = TextEditingController();
  final _detallesCtrl = TextEditingController();

  double? _lat;
  double? _lon;

  bool _isGettingLocation = false;
  bool _enviando = false;

  // Colores de marca
  final Color kPrimary = const Color(0xFFFF6B35);
  final Color kAccent = const Color(0xFF1E293B);
  final Color kBackground = const Color(0xFFF8F9FA);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: kPrimary)),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);
    FocusScope.of(context).unfocus();

    try {
      final position = await LocationServiceIQ.getCurrentLocation();
      final address = await LocationServiceIQ.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _ubicacionCtrl.text = address;
        _lat = position.latitude;
        _lon = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _abrirMapaPreview() async {
    if (_lat == null || _lon == null) return;
    final uri = LocationServiceIQ.getExternalMapUrl(_lat!, _lon!);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el mapa')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ubicacionCtrl.dispose();
    _detallesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final horaTexto = _hora == null
        ? '¿A qué hora?'
        : '${_hora!.hour}:${_hora!.minute.toString().padLeft(2, '0')}';
    final tieneCoordenadas = _lat != null && _lon != null;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: kAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Propuesta de Encuentro',
          style: TextStyle(
            color: kAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.calendar_month_rounded, "Fecha y Hora"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPickerCard(
                    label: _fecha == null
                        ? 'Día'
                        : DateFormat('d MMM', 'es_ES').format(_fecha!),
                    icon: Icons.today_rounded,
                    onTap: _pickDate,
                    isSelected: _fecha != null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerCard(
                    label: horaTexto,
                    icon: Icons.schedule_rounded,
                    onTap: _pickTime,
                    isSelected: _hora != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(Icons.location_on_rounded, "Lugar de reunión"),
            const SizedBox(height: 12),
            _buildLocationField(tieneCoordenadas),
            if (tieneCoordenadas) _buildMapLink(),
            const SizedBox(height: 28),
            _buildSectionHeader(Icons.notes_rounded, "Detalles o Notas"),
            const SizedBox(height: 12),
            _buildCustomTextField(
              controller: _detallesCtrl,
              hint: "Ej: Llevaré una camiseta roja para que me reconozcas...",
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            _buildSubmitButton(user),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kAccent.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? kPrimary : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kPrimary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(bool tieneCoordenadas) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _ubicacionCtrl,
        onChanged: (val) {
          if (_lat != null) {
            setState(() {
              _lat = null;
              _lon = null;
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Nombre del lugar o dirección...',
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          suffixIcon: _isGettingLocation
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    tieneCoordenadas ? Icons.gps_fixed : Icons.my_location,
                    color: tieneCoordenadas ? Colors.green : kPrimary,
                  ),
                  onPressed: _useCurrentLocation,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMapLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: InkWell(
        onTap: _abrirMapaPreview,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            const Text(
              "Ver en el mapa",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(User? user) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _enviando
            ? null
            : () async {
                if (user == null ||
                    _fecha == null ||
                    _hora == null ||
                    _ubicacionCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, completa los campos requeridos',
                      ),
                    ),
                  );
                  return;
                }

                setState(() => _enviando = true);

                final fechaCompleta = DateTime(
                  _fecha!.year,
                  _fecha!.month,
                  _fecha!.day,
                  _hora!.hour,
                  _hora!.minute,
                );

                try {
                  final mensajeReal = await ChatService.instance
                      .crearCitaYEnviarMensaje(
                        chatId: widget.chatId,
                        propuestoPor: user.id,
                        fecha: fechaCompleta,
                        ubicacion: _ubicacionCtrl.text.trim(),
                        lat: _lat,
                        lon: _lon,
                        detalles: _detallesCtrl.text.isEmpty
                            ? null
                            : _detallesCtrl.text.trim(),
                        fechaFormateada: DateFormat(
                          'dd MMMM yyyy • HH:mm',
                          'es_ES',
                        ).format(fechaCompleta),
                      );

                  if (mounted) Navigator.pop(context, mensajeReal);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _enviando = false);
                }
              },
        child: _enviando
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Enviar Propuesta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
