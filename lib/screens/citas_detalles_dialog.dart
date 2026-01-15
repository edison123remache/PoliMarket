import 'package:flutter/material.dart';
import '../models/cita_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class CitaDetallesDialog extends StatelessWidget {
  final Cita cita;
  final Map<String, dynamic>? detallesCompletos;

  const CitaDetallesDialog({
    super.key,
    required this.cita,
    this.detallesCompletos,
  });

  @override
  Widget build(BuildContext context) {
    // Colores basados en el tema de tu App
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fechaDia = DateFormat("d", 'es_ES').format(cita.fecha);
    final fechaMes = DateFormat(
      "MMMM",
      'es_ES',
    ).format(cita.fecha).toUpperCase();
    final horaCita = DateFormat.jm().format(
      DateTime(2024, 1, 1, cita.hora.hour, cita.hora.minute),
    );

    double lat =
        double.tryParse(detallesCompletos?['lat']?.toString() ?? '0') ?? 0.0;
    double lon =
        double.tryParse(detallesCompletos?['lon']?.toString() ?? '0') ?? 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Indicador de arrastre
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 10),
                    // Cabecera con Botón de Cierre
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CircleAvatar(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // Sección de Título Principal
                    Text(
                      'Detalles de Cita',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Tarjeta Principal (Hero Style)
                    _buildHeroCard(
                      context,
                      primaryColor,
                      fechaDia,
                      fechaMes,
                      horaCita,
                    ),

                    const SizedBox(height: 30),

                    // Sección de Información
                    _buildSectionLabel(context, 'UBICACIÓN'),
                    const SizedBox(height: 12),
                    _buildLocationTile(context, primaryColor, lat, lon),

                    const SizedBox(height: 25),

                    if (cita.detalles?.isNotEmpty ?? false) ...[
                      _buildSectionLabel(context, 'NOTAS ADICIONALES'),
                      const SizedBox(height: 12),
                      _buildNotesBox(context, cita.detalles!),
                      const SizedBox(height: 25),
                    ],

                    // Badge de Estado Final
                    _buildStatusBadge(primaryColor),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    Color color,
    String dia,
    String mes,
    String hora,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bloque de Fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  dia,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mes.substring(0, 3),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Bloque de Hora e Icono
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hora de encuentro',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  hora,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white38,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: Theme.of(context).primaryColor.withOpacity(0.7),
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    Color color,
    double lat,
    double lon,
  ) {
    bool canOpenMap = lat != 0 && lon != 0;

    return InkWell(
      onTap: canOpenMap
          ? () async {
              final uri = LocationServiceIQ.getExternalMapUrl(lat, lon);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.location_on, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita.ubicacion,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (canOpenMap)
                    Text(
                      'Toca para ver ruta',
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (canOpenMap)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: color.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String notas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text(
        notas,
        style: const TextStyle(
          height: 1.6,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          const Text(
            'CITA CONFIRMADA Y ASEGURADA',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
