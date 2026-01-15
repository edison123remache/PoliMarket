import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:randimarket/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth_wrapper.dart';
import 'services/location_service.dart';
import 'services/vista_mapa.dart';

import 'screens/profile_screen.dart';
import 'screens/subir_servicio_screen.dart';
import 'screens/search_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/cita_screen.dart';
import 'screens/admin_panel.dart';
import 'screens/ranking_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.initialize("4cef4c15-0cd4-46eb-939e-8eecfee710b8");
  await OneSignal.Notifications.requestPermission(false);

  await initializeDateFormatting('es_ES', null);

  String supabaseUrl = 'https://engsrmatiagwggnphlgu.supabase.co';
  String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuZ3NybWF0aWFnd2dnbnBobGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MTc1NjIsImV4cCI6MjA3NzA5MzU2Mn0.82f5h2SS-lhyyHKoO1POVvOwh1d6k6lqhw0Hjv11iy0';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  const String locationIQApiKey = 'pk.aa6bf1b2a0d1de48465f4a014bfe49d2';
  LocationServiceIQ.initialize(locationIQApiKey);
  MapService.initialize(locationIQApiKey);

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35), // Naranja moderno
          brightness: Brightness.light,
        ),

        // AppBar moderno
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2D3142),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),

        // Tarjetas con sombras sutiles
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Botones modernos
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input fields modernos
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),

        // Iconos
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),

        // Bottom Navigation Bar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          selectedItemColor: Color(0xFFFF6B35),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

        // FAB moderno
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      home: const AuthWrapper(),
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/SubirServ': (context) => const SubirServicioScreen(),
        '/search': (context) => const SearchScreen(),
        '/home': (context) => const HomeScreen(),
        '/chatList': (context) => const ChatListScreen(),
        '/citaList': (context) => const AgendaScreen(),
        '/admin': (context) => const AdminPanel(),
        '/ranking-servicios': (context) {
          final mode = ModalRoute.of(context)!.settings.arguments as String;
          return RankingServiciosScreen(mode: mode);
        },
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      debugShowCheckedModeBanner: false,
    );
  }
}
