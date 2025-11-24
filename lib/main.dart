import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/env.dart';
import 'app.dart';
import 'auth_wrapper.dart';
import 'screens/profile_screen.dart';
import 'services/location_service.dart';
import 'services/vista_mapa.dart';
import 'screens/subir_servicio_screen.dart';
import 'screens/search_screen.dart'; 
//import 'screens/info_servicio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await dotenv.load(fileName: ".env");
  String supabaseUrl = 'https://engsrmatiagwggnphlgu.supabase.co';
  String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuZ3NybWF0aWFnd2dnbnBobGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MTc1NjIsImV4cCI6MjA3NzA5MzU2Mn0.82f5h2SS-lhyyHKoO1POVvOwh1d6k6lqhw0Hjv11iy0';
  String locationIQApiKey = 'pk.aa6bf1b2a0d1de48465f4a014bfe49d2';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  LocationServiceIQ.initialize(locationIQApiKey);
  MapService.initialize(locationIQApiKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LlamaMarket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/SubirServ': (context) => const SubirServicioScreen(),
         '/search': (context) => const SearchScreen(),
        //'/VerServ': (context) => const DetalleServicioScreen(servicioId: servicio.id),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
