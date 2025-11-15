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
  bool _isLoading = false;
  bool _emailSent = false;

  void _resetPassword() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await widget.authService.resetPassword(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_emailSent ? 'Correo Enviado' : 'Recuperar Contraseña'),
      content: _emailSent
          ? const Text(
              'Se ha enviado un enlace de recuperación a tu correo. '
              'Revisa tu bandeja de entrada.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu correo ESPOCH para recuperar tu contraseña:',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    labelStyle: TextStyle(color: Color(0xFFF6511E)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF6511E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFF6511E),
                        width: 2.0,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.endsWith('@espoch.edu.ec')) {
                      return 'Solo se permiten correos @espoch.edu.ec';
                    }
                    return null;
                  },
                ),
              ],
            ),
      actions: [
        if (!_emailSent) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6511E),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ],
    );
  }
}
