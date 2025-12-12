import 'package:flutter/material.dart';
import '../models/cita_model.dart';
import 'package:intl/intl.dart';

class CitaDetallesDialog extends StatelessWidget {
  final Cita cita;
  final Map<String, dynamic>? detallesCompletos;

  const CitaDetallesDialog({
    Key? key,
    required this.cita,
    this.detallesCompletos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = DateFormat(
      "EEEE d 'de' MMMM, yyyy",
      'es_ES',
    ).format(cita.fecha);
    final horaFormateada =
        '${cita.hora.hour}:${cita.hora.minute.toString().padLeft(2, '0')}';
    final esPasada = cita.esPasada;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Encabezado
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detalles de la Cita',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de información principal
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: esPasada
                              ? Colors.grey[100]
                              : Colors.orange.shade50,
                          border: Border.all(
                            color: esPasada ? Colors.grey[400]! : Colors.orange,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Punto de Encuentro',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            Divider(color: Colors.orange, thickness: 1),

                            _buildInfoItem(
                              icon: Icons.calendar_today,
                              label: 'Fecha:',
                              value: fechaFormateada,
                              esPasada: esPasada,
                            ),

                            _buildInfoItem(
                              icon: Icons.access_time,
                              label: 'Hora:',
                              value: horaFormateada,
                              esPasada: esPasada,
                            ),

                            _buildInfoItem(
                              icon: Icons.location_pin,
                              label: 'Ubicación:',
                              value: cita.ubicacion,
                              esPasada: esPasada,
                            ),

                            if (cita.detalles != null &&
                                cita.detalles!.isNotEmpty)
                              _buildInfoItem(
                                icon: Icons.description,
                                label: 'Detalles:',
                                value: cita.detalles!,
                                esPasada: esPasada,
                              ),

                            SizedBox(height: 16),

                            // Estado
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Estado: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: esPasada
                                        ? Colors.grey[700]
                                        : Colors.black,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Text(
                                    'ACEPTADA',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Información del servicio
                      if (cita.servicioInfo != null &&
                          cita.servicioInfo!['titulo'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicio relacionado:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cita.servicioInfo!['titulo'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (cita.servicioInfo!['descripcion'] != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        cita.servicioInfo!['descripcion'],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 20),

                      // Nota informativa
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Esta cita ha sido aceptada por ambos participantes y no puede ser modificada.',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool esPasada,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: esPasada ? Colors.grey : Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: esPasada ? Colors.grey[700] : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: esPasada ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
