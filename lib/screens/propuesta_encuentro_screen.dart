import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/location_service.dart'; // Asegúrate de importar tu LocationServiceIQ

class PropuestaEncuentroScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const PropuestaEncuentroScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  State<PropuestaEncuentroScreen> createState() => _PropuestaEncuentroScreenState();
}

class _PropuestaEncuentroScreenState extends State<PropuestaEncuentroScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fecha;
  TimeOfDay? _hora;
  final TextEditingController _ubicacionCtrl = TextEditingController();
  final TextEditingController _detallesCtrl = TextEditingController();
  bool _isGettingLocation = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final pos = await LocationServiceIQ.getCurrentLocation();
      final addr = await LocationServiceIQ.getAddressFromCoordinates(pos.latitude, pos.longitude);
      setState(() => _ubicacionCtrl.text = addr);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo ubicación: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_fecha == null || _hora == null || _ubicacionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa fecha, hora y ubicación')),
      );
      return;
    }

    final horaStr = _hora!.format(context);

    try {
      await ChatService.instance.crearCita(
        chatId: widget.chatId,
        propuestoPor: ChatService.instance.supabase.auth.currentUser!.id,
        fecha: _fecha!,
        hora: horaStr,
        ubicacion: _ubicacionCtrl.text.trim(),
        detalles: _detallesCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta enviada')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar propuesta: $e')),
      );
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
    final fechaLabel = _fecha != null ? DateFormat.yMMMd().format(_fecha!) : 'Seleccionar fecha';
    final horaLabel = _hora != null ? _hora!.format(context) : 'Seleccionar hora';

    return Scaffold(
      appBar: AppBar(title: const Text('Proponer Encuentro')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(fechaLabel),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDate,
              ),
            ),
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(horaLabel),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _pickTime,
              ),
            ),
            TextFormField(
              controller: _ubicacionCtrl,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                suffixIcon: _isGettingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _useCurrentLocation,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _detallesCtrl,
              decoration: const InputDecoration(labelText: 'Detalles (opcional)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Enviar propuesta'),
            ),
          ],
        ),
      ),
    );
  }
}
