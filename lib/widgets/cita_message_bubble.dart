// lib/widgets/cita_message_bubble.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class CitaMessageBubble extends StatelessWidget {
  final Map<String, dynamic> cita;
  final bool esPropietario; // true si el usuario actual propuso la cita

  const CitaMessageBubble({
    super.key,
    required this.cita,
    required this.esPropietario,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = cita['fecha'] as String? ?? 'Sin fecha';
    final ubicacion = cita['ubicacion'] as String? ?? 'Sin ubicaciÃ³n';
    final detalles = cita['detalles'] as String? ?? '';
    final estado = cita['estado'] as String? ?? 'pendiente';

    // Color y texto del estado
    Color colorEstado = Colors.orange;
    String textoEstado = 'Pendiente';
    if (estado == 'aceptada') {
      colorEstado = Colors.green;
      textoEstado = 'Aceptada';
    } else if (estado == 'rechazada') {
      colorEstado = Colors.red;
      textoEstado = 'Rechazada';
    }

    return Align(
      alignment: esPropietario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÃ­tulo
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange, size: 20),
                SizedBox(width: 6),
                Text(
                  'Punto de Encuentro',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const Divider(color: Colors.orange, thickness: 1),

            // InformaciÃ³n
            Text('Fecha: $fecha', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('UbicaciÃ³n: $ubicacion', style: const TextStyle(fontSize: 15)),
            if (detalles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Detalles: $detalles', style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
            const SizedBox(height: 10),

            // Estado
            Row(
              children: [
                const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    textoEstado,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),

            // Botones solo si estÃ¡ pendiente y NO es el propietario (el que recibe la propuesta)
            if (estado == 'pendiente' && !esPropietario) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      await ChatService.instance.actualizarEstadoCitaCompleto(cita['id'], 'rechazada');
                    },
                    child: const Text('Negar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      await ChatService.instance.actualizarEstadoCitaCompleto(cita['id'], 'aceptada');
                    },
                    child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],

            // Mensaje final solo para el que propuso (cuando ya fue respondida)
            if ((estado == 'aceptada' || estado == 'rechazada') && esPropietario)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  estado == 'aceptada' ? 'Â¡Aceptada!' : 'Rechazada',
                  style: TextStyle(
                    color: estado == 'aceptada' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}