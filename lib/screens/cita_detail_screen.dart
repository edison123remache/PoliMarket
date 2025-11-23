import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class CitaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cita;
  const CitaDetailScreen({super.key, required this.cita});

  @override
  State<CitaDetailScreen> createState() => _CitaDetailScreenState();
}

class _CitaDetailScreenState extends State<CitaDetailScreen> {
  final ChatService _chatService = ChatService.instance;

  Future<void> _updateEstado(String estado) async {
    await _chatService.actualizarEstadoCita(widget.cita['id'], estado);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cita $estado')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fecha = widget.cita['fecha'] ?? '';
    final hora = widget.cita['hora'] ?? '';
    final ubicacion = widget.cita['ubicacion'] ?? '';
    final detalles = widget.cita['detalles'] ?? '';
    final estado = widget.cita['estado'] ?? 'pendiente';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Propuesta')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: $fecha'),
            const SizedBox(height: 6),
            Text('Hora: $hora'),
            const SizedBox(height: 6),
            Text('Ubicación: $ubicacion'),
            const SizedBox(height: 6),
            Text('Detalles: $detalles'),
            const SizedBox(height: 12),
            Text('Estado: $estado'),
            const SizedBox(height: 20),
            if (estado == 'pendiente') Row(
              children: [
                ElevatedButton(onPressed: () => _updateEstado('aceptada'), child: const Text('Aceptar')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () => _updateEstado('rechazada'), child: const Text('Rechazar')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
