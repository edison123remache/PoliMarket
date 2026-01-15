import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordDialog extends StatefulWidget {
  final AuthService authService;

  const ResetPasswordDialog({super.key, required this.authService});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  // Colores profesionales
  final Color primaryOrange = const Color(0xFFFF6B35);
  final Color textDark = const Color(0xFF1A1A1A);
  final Color textLight = const Color(0xFF757575);
  final Color successGreen = const Color(0xFF4CAF50);

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.authService.resetPassword(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono animado
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _emailSent
                            ? [
                                successGreen.withOpacity(0.2),
                                successGreen.withOpacity(0.1),
                              ]
                            : [
                                primaryOrange.withOpacity(0.2),
                                primaryOrange.withOpacity(0.1),
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _emailSent
                            ? successGreen.withOpacity(0.3)
                            : primaryOrange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _emailSent
                          ? Icons.mark_email_read_rounded
                          : Icons.lock_reset_rounded,
                      color: _emailSent ? successGreen : primaryOrange,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    _emailSent ? '¡Correo Enviado!' : 'Recuperar Contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    _emailSent
                        ? 'Te hemos enviado un enlace de recuperación a tu correo institucional. Revisa tu bandeja de entrada y sigue las instrucciones.'
                        : 'Ingresa tu correo institucional y te enviaremos un enlace seguro para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  if (!_emailSent) ...[
                    const SizedBox(height: 32),

                    // Campo de correo con diseño mejorado
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Correo Institucional',
                        labelStyle: TextStyle(color: textLight, fontSize: 14),
                        hintText: 'ejemplo@espoch.edu.ec',
                        hintStyle: TextStyle(
                          color: textLight.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.email_outlined,
                            color: primaryOrange,
                            size: 22,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: primaryOrange,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        if (!value.endsWith('@espoch.edu.ec')) {
                          return 'Debe ser un correo institucional (@espoch.edu.ec)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: textLight,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: primaryOrange.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Enviar Enlace',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 32),

                    // Mensaje de éxito con icono
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: successGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: successGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Si no recibes el correo, revisa tu carpeta de spam.',
                              style: TextStyle(
                                color: successGreen.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón de cerrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: successGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Entendido',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
