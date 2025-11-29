// lib/screens/propuesta_encuentro_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isGettingLocation = false;
  bool _enviando = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.orange),
        ),
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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationServiceIQ.getCurrentLocation();
      final address = await LocationServiceIQ.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _ubicacionCtrl.text = address;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error ubicación: $e')));
    } finally {
      setState(() => _isGettingLocation = false);
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
        ? 'Seleccionar hora'
        : _hora!.format(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CloseButton(color: Colors.black),
        title: const Text(
          'Programar Encuentro',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FECHA
              const Text(
                'Fecha:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fecha == null
                            ? 'Seleccionar fecha'
                            : DateFormat(
                                'dd MMMM yyyy',
                                'es_ES',
                              ).format(_fecha!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // HORA
              const Text(
                'Hora:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(horaTexto, style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.access_time, color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // UBICACIÓN + DETALLES (igual que antes)
              const Text(
                'Ubicación:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ubicacionCtrl,
                decoration: InputDecoration(
                  hintText: 'Escribe o usa tu ubicación',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _useCurrentLocation,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detalles adicionales (opcional):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(controller: _detallesCtrl, maxLines: 4),

              const SizedBox(height: 40),

              // BOTÓN ENVIAR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                                  'Completa fecha, hora y ubicación',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _enviando = true);

                          final _ = _hora!.format(
                            context,
                          ); // ej: 15:30
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
                                  detalles: _detallesCtrl.text.isEmpty
                                      ? null
                                      : _detallesCtrl.text.trim(),
                                  fechaFormateada: DateFormat(
                                    'dd MMMM yyyy • HH:mm',
                                    'es_ES',
                                  ).format(fechaCompleta),
                                );

                            // ← DEVOLVEMOS el mensaje real al chat
                            if (mounted) {
                              Navigator.pop(context, mensajeReal);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            setState(() => _enviando = false);
                          }
                        },
                  child: _enviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enviar Propuesta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
