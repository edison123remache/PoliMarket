import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:randimarket/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_wrapper.dart';
import 'services/location_service.dart';
import 'services/vista_mapa.dart';

import 'screens/profile_screen.dart';
import 'screens/subir_servicio_screen.dart';
import 'screens/search_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/cita_screen.dart';
import 'screens/admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.initialize("4cef4c15-0cd4-46eb-939e-8eecfee710b8");
  await OneSignal.Notifications.requestPermission(false);

  //  fecha
  await initializeDateFormatting('es_ES', null);

  //  Supabase
  String supabaseUrl = 'https://engsrmatiagwggnphlgu.supabase.co';
  String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuZ3NybWF0aWFnd2dnbnBobGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MTc1NjIsImV4cCI6MjA3NzA5MzU2Mn0.82f5h2SS-lhyyHKoO1POVvOwh1d6k6lqhw0Hjv11iy0';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // API de ubicación
  const String locationIQApiKey = 'pk.aa6bf1b2a0d1de48465f4a014bfe49d2';
  LocationServiceIQ.initialize(locationIQApiKey);
  MapService.initialize(locationIQApiKey);

  // Forzar logout (Pero solo si el JWT está vencido jeje)
  final supabase = Supabase.instance.client;
  try {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.auth.refreshSession();
    }
  } catch (_) {
    await supabase.auth.signOut();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llamamarket',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),

      // ✅ PANTALLA INICIAL
      home: const AuthWrapper(),

      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/SubirServ': (context) => const SubirServicioScreen(),
        '/search': (context) => const SearchScreen(),
        '/home': (context) => const HomeScreen(),
        '/chatList': (context) => const ChatListScreen(),
        '/citaList': (context) => const AgendaScreen(),
        '/admin': (context) => const AdminPanel(),
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
