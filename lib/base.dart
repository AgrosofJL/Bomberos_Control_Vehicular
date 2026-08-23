import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Buscamos la ruta interna del dispositivo para guardar la base de datos
    String path = join(await getDatabasesPath(), 'checklist_bomberos.db');
    
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
    );
  }

  // --- ACA ES LO NUEVO: Estructura espejo exacta de Supabase ---
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla Usuarios (Adaptada con soporte para tu LogueoPage)
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        operario TEXT,
        correo TEXT,
        device TEXT,
        rol TEXT,
        pass TEXT,
        estado TEXT
      )
    ''');
await db.execute('''
    CREATE TABLE maquinaria (
      id INTEGER PRIMARY KEY,
      interno INTEGER,
      marca_modelo TEXT,
      dominio_patente TEXT,
      numero_motor TEXT,
      numero_chasis TEXT,
      tipo_combustible TEXT,
      sistema_electrico_bateria TEXT,
      medida_neumaticos TEXT,
      presion_psi INTEGER,
      km_hs_actual REAL,
      fecha_adquisicion TEXT,
      observaciones TEXT,
      tipo TEXT,
      estado TEXT
    )
  ''');
    // 2. Tabla Personal (Mapeo completo sin quitar ninguna columna)
    await db.execute('''
      CREATE TABLE personal (
        id INTEGER PRIMARY KEY,
        nro_legajo INTEGER,
        dni INTEGER,
        nombre_completo TEXT,
        grupo_sanguineo TEXT,
        afecciones TEXT,
        nro_telefono TEXT,
        tele_familiar TEXT,
        sanciones TEXT,
        fecha_nacimiento TEXT,
        localidad TEXT,
        rango TEXT,
        fecha_inicio TEXT,
        estado TEXT,
        foto_path TEXT,
        motivo_cambio_estado TEXT,
        puntuacion REAL,
        rol TEXT,
        usuario TEXT,
        pass TEXT,
        device TEXT
      )
    ''');

    // 3. Tabla Ítems de Chequeo
    await db.execute('''
      CREATE TABLE items_chequeo (
        item INTEGER,
        tipo_vehiculo TEXT,
        descripcion TEXT,
        fecha_vto TEXT
      )
    ''');

    // 4. Tabla Chequeos Vehicular (Llave primaria compuesta id + reg_local)
    await db.execute('''
      CREATE TABLE chequeos_vehicular (
        id TEXT,
        tipo_unidad TEXT,
        unidad TEXT,
        dominio TEXT,
        marca TEXT,
        interno TEXT,
        fecha_prox_Ser TEXT,
        utilizado_por TEXT,
        inspecciono TEXT,
        tarjeta_verde TEXT,
        comprobante_patente TEXT,
        obra_base TEXT,
        comprobante_seguro TEXT,
        cedula_transporte TEXT,
        verificacion_tec TEXT,
        doc_chofer TEXT,
        item TEXT,
        estado TEXT,
        control TEXT,
        fecha TEXT,
        verifico TEXT,
        fecha_vto TEXT,
        visual_map TEXT,
        observaciones TEX,
        reg_local TEXT
      )
    ''');
    
    debugPrint("✅ Base de datos local inicializada con todas las tablas espejo.");
  }

  // --- ESTO LO MODIFIQUE: Lógica reglamentaria para cumplir con Max(registro)+1 ---
  Future<int> obtenerSiguienteIdChequeo() async {
    final database = await db;
    // Buscamos el ID máximo guardado localmente para autoincrementar de forma limpia
    final List<Map<String, dynamic>> resultado = await database.rawQuery(
      'SELECT MAX(CAST(id AS INTEGER)) as max_id FROM chequeos_vehicular'
    );
    
    int maxId = resultado.first['max_id'] ?? 0;
    return maxId + 1;
  }
}