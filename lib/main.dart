// ESTO LO MODIFIQUE
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart'; 
// ACA ES LO NUEVO: Importación nativa de almacenamiento local
import 'package:shared_preferences/shared_preferences.dart';

import 'loguer.dart'; 
import 'menu.dart'; 

void main() async {
  // 1. Siempre primero
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar motor SQLite Web si corre en navegador
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // 3. Formato de fechas
  await initializeDateFormatting('es_ES', null);

  // 4. Conexión a Supabase
  await Supabase.initialize(
    url: 'https://axmwslbcchqpcglxdzip.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4bXdzbGJjY2hxcGNnbHhkemlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyOTIwNTksImV4cCI6MjA5Njg2ODA1OX0.m6m88jGRGwsb81glmyvmVkDM3cfROdVZ4EmgobPy5Xo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist Vehicular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const CheckAuthPage(),
    );
  }
}

// =============================================================================
// ACA ES LO NUEVO: Pantalla de ruteo controlada 100% por SharedPreferences
// =============================================================================
class CheckAuthPage extends StatefulWidget {
  const CheckAuthPage({super.key});

  @override
  State<CheckAuthPage> createState() => _CheckAuthPageState();
}

class _CheckAuthPageState extends State<CheckAuthPage> {
  @override
  void initState() {
    super.initState();
    _evaluarPreferenciaDeSesion();
  }


  Future<void> _evaluarPreferenciaDeSesion() async {
    // Abrimos la instancia del almacenamiento local
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Leemos la bandera booleana de login
    bool tieneSesionActiva = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (tieneSesionActiva) {
      // Si la preferencia es verdadera, entra directo al menú sin escalas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
      );
    } else {
      // Si es falso o nulo, lo frena en el Logueo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogueoPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6F9), // Estética Apple Soft Light
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5A36), // Tu naranja de bomberos
          strokeWidth: 3,
        ),
      ),
    );
  }
}