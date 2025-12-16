import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart';


class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Validar que el email sea de ESPOCH
    if (!email.endsWith('@espoch.edu.ec')) {
      throw Exception('Solo se permiten correos institucionales de ESPOCH');
    }

    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': name, 'email': email},
      emailRedirectTo: 'com.grupo6.llamamarket://callback',
    );

    if (authResponse.user != null) {
      // Crear perfil en la tabla
      await _supabase.from('perfiles').insert({
        'id': authResponse.user!.id,
        'email': email,
        'nombre': name,
        'rol': 'user',
        //'is_verified': false,
      });
    }

    return authResponse;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (!email.endsWith('@espoch.edu.ec')) {
      throw Exception('Solo se permiten correos institucionales de ESPOCH');
    }

    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'yourapp://reset-password',
    );
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}