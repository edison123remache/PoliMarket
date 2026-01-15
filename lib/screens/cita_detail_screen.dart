// lib/widgets/cita_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/chat_service.dart';

class CitaMessageBubble extends StatefulWidget {
  final Map<String, dynamic> cita;
  final bool esPropietario;

  const CitaMessageBubble({
    super.key,
    required this.cita,
    required this.esPropietario,
  });

  @override
  State<CitaMessageBubble> createState() => _CitaMessageBubbleState();
}

class _CitaMessageBubbleState extends State<CitaMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final fecha = widget.cita['fecha'] as String? ?? 'Sin fecha';
    final ubicacion = widget.cita['ubicacion'] as String? ?? 'Sin ubicación';
    final detalles = widget.cita['detalles'] as String? ?? '';
    final estado = widget.cita['estado'] as String? ?? 'pendiente';
    final double lat = _parseCoordinate(widget.cita['lat']);
    final double lon = _parseCoordinate(widget.cita['lon']);

    // Configuración visual por estado
    Color colorPrincipal;
    Color colorFondo;
    Color colorBorde;
    String textoEstado;
    IconData iconoEstado;
    List<Color> gradienteEstado;

    switch (estado) {
      case 'aceptada':
        colorPrincipal = const Color(0xFF4CAF50);
        colorFondo = const Color(0xFFE8F5E9);
        colorBorde = const Color(0xFF81C784);
        textoEstado = 'Aceptada';
        iconoEstado = Icons.check_circle_rounded;
        gradienteEstado = [const Color(0xFF66BB6A), const Color(0xFF4CAF50)];
        break;
      case 'rechazada':
        colorPrincipal = const Color(0xFFE53935);
        colorFondo = const Color(0xFFFFEBEE);
        colorBorde = const Color(0xFFEF5350);
        textoEstado = 'Rechazada';
        iconoEstado = Icons.cancel_rounded;
        gradienteEstado = [const Color(0xFFEF5350), const Color(0xFFE53935)];
        break;
      default:
        colorPrincipal = const Color(0xFFFF6B00);
        colorFondo = const Color(0xFFFFF3E0);
        colorBorde = const Color(0xFFFFB74D);
        textoEstado = 'Pendiente';
        iconoEstado = Icons.access_time_rounded;
        gradienteEstado = [const Color(0xFFFFB74D), const Color(0xFFFF6B00)];
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Align(
          alignment: widget.esPropietario
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorBorde, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colorPrincipal.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con gradiente
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorFondo, colorFondo.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradienteEstado),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrincipal.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punto de Encuentro',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: colorPrincipal,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Propuesta de reunión',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorPrincipal.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradienteEstado),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrincipal.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconoEstado, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              textoEstado,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fecha
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Fecha',
                        value: fecha,
                        color: colorPrincipal,
                      ),
                      const SizedBox(height: 12),

                      // Ubicación clickeable
                      InkWell(
                        onTap: () async {
                          if (lat != 0 && lon != 0) {
                            final uri = LocationServiceIQ.getExternalMapUrl(
                              lat,
                              lon,
                            );
                            try {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('No se pudo abrir el mapa'),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Esta cita no tiene coordenadas GPS',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.map_rounded,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ubicación',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ubicacion,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.blue.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Detalles
                      if (detalles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorFondo.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                color: colorPrincipal,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DETALLES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      detalles,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Botones de acción
                      if (estado == 'pendiente' && !widget.esPropietario) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await ChatService.instance
                                      .actualizarEstadoCitaCompleto(
                                        widget.cita['id'],
                                        'rechazada',
                                      );
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text(
                                  'Rechazar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await ChatService.instance
                                      .actualizarEstadoCitaCompleto(
                                        widget.cita['id'],
                                        'aceptada',
                                      );
                                },
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text(
                                  'Aceptar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.green.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Mensaje final para el propietario
                      if ((estado == 'aceptada' || estado == 'rechazada') &&
                          widget.esPropietario) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: estado == 'aceptada'
                                  ? [
                                      Colors.green.shade50,
                                      Colors.green.shade100,
                                    ]
                                  : [Colors.red.shade50, Colors.red.shade100],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estado == 'aceptada'
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                estado == 'aceptada'
                                    ? Icons.celebration_rounded
                                    : Icons.info_outline_rounded,
                                color: estado == 'aceptada'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                estado == 'aceptada'
                                    ? '¡Cita Aceptada!'
                                    : 'Cita Rechazada',
                                style: TextStyle(
                                  color: estado == 'aceptada'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[600],
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
