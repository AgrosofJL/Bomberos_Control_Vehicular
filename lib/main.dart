// ESTO LO MODIFIQUE
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'loguer.dart'; 
import 'menu.dart'; 

void main() async {
  // 1. Siempre primero
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar motor SQLite Web sin Web Worker
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }

  // 3. Formato de fechas (Sin pasar null como segundo argumento para evitar el error de 'init' en JS)
  await initializeDateFormatting('es_ES');

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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tieneSesionActiva = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (tieneSesionActiva) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogueoPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF5A36),
          strokeWidth: 3,
        ),
      ),
    );
  }
}