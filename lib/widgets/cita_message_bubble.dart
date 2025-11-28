// lib/widgets/cita_message_bubble.dart
import 'package:flutter/material.dart';

class CitaMessageBubble1 extends StatelessWidget {
  final Map<String, dynamic> cita;
  final bool esPropietario;

  const CitaMessageBubble1({
    super.key,
    required this.cita,
    required this.esPropietario,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = cita['fecha'] ?? 'Sin fecha';
    final ubicacion = cita['ubicacion'] ?? 'Sin ubicación';
    final detalles = cita['detalles'] ?? '';
    final estado = cita['estado'] ?? 'pendiente';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Propuesta de encuentro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Text('Fecha: $fecha', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Ubicación: $ubicacion'),
          if (detalles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Detalles: $detalles'),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (estado == 'pendiente' && !esPropietario)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Aceptar
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        // Rechazar
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Rechazar'),
                    ),
                  ],
                )
              else
                Text(
                  estado == 'aceptada' ? 'Aceptada' : estado == 'rechazada' ? 'Rechazada' : 'Tu propuesta',
                  style: TextStyle(color: estado == 'aceptada' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}