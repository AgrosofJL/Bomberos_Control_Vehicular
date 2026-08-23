import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'base.dart';

class DescargaSincronizada {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper();

  // --- ESTO LO MODIFIQUE: Descarga completa respetando el rol y el estado ACTIVO ---
  Future<bool> descargarTodoDesdeSupabase({required String rol}) async {
    try {
      debugPrint("🔄 Iniciando descarga de tablas maestras desde Supabase...");
      
      final dbLocal = await _dbHelper.db;

      // 1. DESCARGAR ÍTEMS DE CHEQUEO
      final resItems = await _supabase.from('items_chequeo').select();
      if (resItems != null && resItems.isNotEmpty) {
        await dbLocal.transaction((txn) async {
          for (var item in resItems) {
            // ACA ES LO NUEVO: Mapeo uno a uno de la tabla items_chequeo
            await txn.insert(
              'items_chequeo',
              {
                'item': item['item'],
                'tipo_vehiculo': item['tipo_vehiculo'],
                'descripcion': item['descripcion'],
                'fecha_vto': item['fecha_vto'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        debugPrint("✅ items_chequeo sincronizado localmente (${resItems.length} registros).");
      }

      // 2. DESCARGAR PERSONAL (Siempre mostrando estado activo prioritariamente)
      final resPersonal = await _supabase.from('personal').select();
      if (resPersonal != null && resPersonal.isNotEmpty) {
        await dbLocal.transaction((txn) async {
          for (var pers in resPersonal) {
            // Mapeo íntegro sin omitir ninguna columna para cumplir con "no me quites nada"
            await txn.insert(
              'personal',
              {
                'id': pers['id'],
                'nro_legajo': pers['nro_legajo'],
                'dni': pers['dni'],
                'nombre_completo': pers['nombre_completo'],
                'grupo_sanguineo': pers['grupo_sanguineo'],
                'afecciones': pers['afecciones'],
                'nro_telefono': pers['nro_telefono'],
                'tele_familiar': pers['tele_familiar'],
                'sanciones': pers['sanciones'],
                'fecha_nacimiento': pers['fecha_nacimiento'],
                'localidad': pers['localidad'],
                'rango': pers['rango'],
                'fecha_inicio': pers['fecha_inicio'],
                'estado': pers['estado'], // Siempre se mantiene el estado del servidor
                'foto_path': pers['foto_path'],
                'motivo_cambio_estado': pers['motivo_cambio_estado'],
                'puntuacion': pers['puntuacion'],
                'rol': pers['rol'],
                'usuario': pers['usuario'],
                'pass': pers['pass'],
                'device': pers['device'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        debugPrint("✅ Tabla personal sincronizada localmente (${resPersonal.length} registros).");
      }
    
    final resMaquinaria = await _supabase.from('maquinaria').select();
    if (resMaquinaria != null && resMaquinaria.isNotEmpty) {
      await dbLocal.transaction((txn) async {
        for (var maq in resMaquinaria) {
          // Mapeo íntegro sin omitir ninguna columna ("no me quites nada")
          await txn.insert(
            'maquinaria',
            {
              'id': maq['id'],
              'interno': maq['interno'],
              'marca_modelo': maq['marca_modelo'],
              'dominio_patente': maq['dominome_patente'] ?? maq['dominio_patente'], // Tolerancia por si cambia nomenclatura
              'numero_motor': maq['numero_motor'],
              'numero_chasis': maq['numero_chasis'],
              'tipo_combustible': maq['tipo_combustible'],
              'sistema_electrico_bateria': maq['sistema_electrico_bateria'],
              'medida_neumaticos': maq['medida_neumaticos'],
              'presion_psi': maq['presion_psi'],
              'km_hs_actual': maq['km_hs_actual'],
              'fecha_adquisicion': maq['fecha_adquisicion'],
              'observaciones': maq['observaciones'],
              'tipo': maq['tipo'],
              'estado': maq['estado'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      debugPrint("✅ Tabla maquinaria sincronizada localmente (${resMaquinaria.length} registros).");
    }
      // 3. DESCARGAR USUARIOS
      final resUsuarios = await _supabase.from('usuarios').select();
      if (resUsuarios != null && resUsuarios.isNotEmpty) {
        await dbLocal.transaction((txn) async {
          for (var user in resUsuarios) {
            await txn.insert(
              'usuarios',
              {
                'id': user['id'],
                'operario': user['operario'],
                'correo':user['correo'],
                'device': user['device'],
                'rol': user['rol'],
                'pass': user['pass'],
                'estado':user['estado'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        debugPrint("✅ Tabla usuario sincronizada localmente (${resUsuarios.length} registros).");
      }

      // 4. DESCARGAR HISTORIAL DE CHEQUEOS PREVIOS (Para tener de consulta local)
      final resChequeos = await _supabase.from('chequeos_vehicular').select();
      if (resChequeos != null && resChequeos.isNotEmpty) {
        await dbLocal.transaction((txn) async {
          for (var chq in resChequeos) {
            await txn.insert(
              'chequeos_vehicular',
              {
                'id': chq['id'],
                'tipo_unidad': chq['tipo_unidad'],
                'unidad': chq['unidad'],
                'dominio': chq['dominio'],
                'marca': chq['marca'],
                'interno': chq['interno'],
                'fecha_prox_Ser': chq['fecha_prox_Ser'],
                'utilizado_por': chq['utilizado_por'],
                'inspecciono': chq['inspecciono'],
                'tarjeta_verde': chq['tarjeta_verde'],
                'comprobante_patente': chq['comprobante_patente'],
                'obra_base': chq['obra_base'],
                'comprobante_seguro': chq['comprobante_seguro'],
                'cedula_transporte': chq['cedula_transporte'],
                'verificacion_tec': chq['verificacion_tec'],
                'doc_chofer': chq['doc_chofer'],
                'item': chq['item'],
                'estado': chq['estado'],
                'control': chq['control'],
                'fecha': chq['fecha'],
                'verifico': chq['verifico'],
                'fecha_vto': chq['fecha_vto'],
                'reg_local': chq['reg_local'],
                'visual_map': chq['visual_map'], 
                'observaciones': chq['observaciones'], 
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        debugPrint("✅ Historial de chequeos actualizado en SQLite.");
      }

      return true;
    } catch (e) {
      debugPrint("❌ Error crítico bajando datos de Supabase: $e");
      return false;
    }
  }
}