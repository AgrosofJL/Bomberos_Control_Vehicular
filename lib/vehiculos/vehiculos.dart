// ESTO LO MODIFIQUE
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../base.dart'; 
import 'chequeos.dart'; 
import 'reporte.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehiculosPage extends StatefulWidget {
  const VehiculosPage({super.key});

  @override
  State<VehiculosPage> createState() => _VehiculosPageState();
}

class _VehiculosPageState extends State<VehiculosPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _filtroSeleccionado = 'TODOS'; 
  List<Map<String, dynamic>> _vehiculos = [];
  bool _isLoading = false;

  // ===========================================================================
  // PALETA APPLE SOFT LIGHT - FORMATO INSTITUCIONAL CSS
  // ===========================================================================
  final Color _colorBg = const Color(0xFFF3F5F1);
  final Color _colorSurface = const Color(0xFFFFFFFF);
  final Color _colorText = const Color(0xFF1B231D);
  final Color _colorTextSecondary = const Color(0xFF5F6B62);
  final Color _colorAccent = const Color(0xFF1E6B4C);
  final Color _colorAccentDark = const Color(0xFF123F2C);
  final Color _colorAccentSoft = const Color(0x1A1E6B4C);
  final Color _colorGoldSoft = const Color(0x24B8862A);
  final Color _colorGoldText = const Color(0xFF8A6A1E);
  final Color _colorBorder = const Color(0x1A1B231D);
  final Color _colorOperativo = const Color(0xFF2FB344);
  final Color _colorNoOperativo = const Color(0xFFC0483C);

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.db;
    
    String query = '''
      SELECT 
        c.*,
        m.interno,
        m.marca_modelo AS marca,
        m.dominio_patente AS dominio,
        m.tipo AS tipo_unidad,
        COALESCE(c.estado, m.estado, 'NO') AS estado
      FROM maquinaria m
      LEFT JOIN (
        SELECT v1.* FROM chequeos_vehicular v1
        WHERE v1.reg_local = (
          SELECT v2.reg_local FROM chequeos_vehicular v2 
          WHERE v2.interno = v1.interno 
          ORDER BY v2.fecha DESC, v2.id DESC LIMIT 1
        )
        GROUP BY v1.interno
      ) c ON CAST(m.interno AS TEXT) = CAST(c.interno AS TEXT)
    ''';

    final List<Map<String, dynamic>> res = await db.rawQuery(query);
    
    setState(() {
      if (_filtroSeleccionado == 'TODOS') {
        _vehiculos = res;
      } else if (_filtroSeleccionado == 'PESADO') {
        _vehiculos = res.where((v) => (v['tipo_unidad'] ?? '').toString().toUpperCase() == 'PESADO').toList();
      } else if (_filtroSeleccionado == 'OTROS') {
        _vehiculos = res.where((v) => (v['tipo_unidad'] ?? '').toString().toUpperCase() != 'PESADO').toList();
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBg, 
      appBar: AppBar(
        backgroundColor: _colorSurface.withOpacity(0.92),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _colorBorder, height: 1.0),
        ),
        title: Text(
          "CENTRAL OPERATIVA",
          style: GoogleFonts.roboto(
            color: _colorText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _colorAccent, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                _buildFilterButton('TODOS'),
                const SizedBox(width: 8),
                _buildFilterButton('PESADO'),
                const SizedBox(width: 8),
                _buildFilterButton('OTROS'),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _colorAccent))
                : _vehiculos.isEmpty
                    ? Center(
                        child: Text(
                          "NO SE ENCONTRARON UNIDADES",
                          style: GoogleFonts.roboto(
                            color: _colorTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _vehiculos.length,
                        itemBuilder: (context, index) {
                          return _buildVehiculoCard(_vehiculos[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String tipo) {
    bool isSelected = _filtroSeleccionado == tipo;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _filtroSeleccionado = tipo);
            _cargarVehiculos();
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFFFFFDE7),
          highlightColor: const Color(0xFFFBC02D).withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _colorAccent : _colorSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _colorAccent : _colorBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF141E18).withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              tipo,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: isSelected ? Colors.white : _colorTextSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD DE VEHÍCULO CON ACCESO A AUDITORÍAS E INICIO DIRECTO
  // ===========================================================================
  Widget _buildVehiculoCard(Map<String, dynamic> vehiculo) {
    String estado = (vehiculo['estado'] ?? 'NO').toString().toUpperCase();
    bool isOperativo = estado == 'OPERATIVO' || estado == 'B' || estado == 'ACTIVO';
    String estadoVisual = isOperativo ? 'OPERATIVO' : 'NO OPERATIVO';
    String internoSanitizado = (vehiculo['interno'] ?? '-').toString().split('.')[0].trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _colorSurface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colorBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141E18).withOpacity(0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: () => _mostrarHistorialAgrupado(
                internoSanitizado,
                vehiculo['dominio'] ?? '',
                vehiculo['tipo_unidad'] ?? '',
              ),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _colorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _colorBorder, width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/catalogo/catalogo/$internoSanitizado.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Center(
                          child: Icon(
                            Icons.fire_truck_rounded,
                            color: _colorAccent.withOpacity(0.4),
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _colorAccentSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "INT $internoSanitizado",
                                style: GoogleFonts.roboto(
                                  color: _colorAccentDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isOperativo ? _colorOperativo : _colorNoOperativo).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                estadoVisual,
                                style: GoogleFonts.roboto(
                                  color: isOperativo ? const Color(0xFF1E7E34) : _colorNoOperativo,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${vehiculo['marca'] ?? 'SIN MARCA'}",
                          style: GoogleFonts.roboto(
                            color: _colorText,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "DOMINIO: ${vehiculo['dominio'] ?? '-'}",
                          style: GoogleFonts.roboto(
                            color: _colorTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            Divider(color: _colorBorder, thickness: 1.0, height: 1),
            const SizedBox(height: 10),

            // Acciones: Ver informes de la unidad + Iniciar Chequeo
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarHistorialAgrupado(
                      internoSanitizado,
                      vehiculo['dominio'] ?? '',
                      vehiculo['tipo_unidad'] ?? '',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _colorTextSecondary,
                      side: BorderSide(color: _colorBorder, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: Icon(Icons.history_edu_rounded, size: 16, color: _colorTextSecondary),
                    label: Text(
                      "INFORMES",
                      style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChequeosPage(vehiculoSeleccionado: vehiculo),
                          ),
                        ).then((_) => _cargarVehiculos()); 
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: const Color(0xFFFFFDE7),
                      highlightColor: const Color(0xFFFBC02D).withOpacity(0.2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _colorAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _colorAccent.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_task_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "NUEVO CHEQUEO",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL HISTORIAL DE INFORMES DE LA UNIDAD
  // ===========================================================================
  void _mostrarHistorialAgrupado(String interno, String dominio, String tipoUnidad) async {
    final db = await _dbHelper.db;
    final List<Map<String, dynamic>> historial = await db.rawQuery('''
      SELECT id, interno, dominio, fecha, inspecciono, estado, tipo_unidad, marca, unidad, reg_local 
      FROM chequeos_vehicular
      WHERE CAST(interno AS TEXT) = ? OR interno = ?
      GROUP BY reg_local
      ORDER BY fecha DESC, id DESC
    ''', [interno, interno]);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _colorSurface, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _colorBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HISTORIAL DE INFORMES",
                        style: GoogleFonts.roboto(
                          color: _colorTextSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Móvil Interno $interno",
                        style: GoogleFonts.roboto(
                          color: _colorText,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context); 
                        final Map<String, dynamic> vMap = {
                          'interno': interno,
                          'dominio': dominio,
                          'tipo_unidad': tipoUnidad,
                          'marca': historial.isNotEmpty ? historial.first['marca'] : '',
                          'unidad': historial.isNotEmpty ? historial.first['unidad'] : '',
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChequeosPage(vehiculoSeleccionado: vMap)),
                        ).then((_) => _cargarVehiculos());
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "+ NUEVO",
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: _colorBorder, thickness: 1.0, height: 1),
              const SizedBox(height: 10),

              Expanded(
                child: historial.isEmpty
                    ? Center(
                        child: Text(
                          "SIN INFORMES REGISTRADOS PARA ESTA UNIDAD",
                          style: GoogleFonts.roboto(
                            color: _colorTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: historial.length,
                        itemBuilder: (context, idx) {
                          final rev = historial[idx];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: _colorBg, 
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _colorBorder, width: 1.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _colorAccentSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.assignment_rounded, color: _colorAccentDark, size: 20),
                              ),
                              title: Text(
                                "FECHA: ${rev['fecha'] ?? '-'}",
                                style: GoogleFonts.roboto(
                                  color: _colorText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                              subtitle: Text(
                                "A cargo: ${rev['inspecciono'] ?? 'No especificado'}",
                                style: GoogleFonts.roboto(
                                  color: _colorTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _mostrarFormularioCompletoDialog(rev);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _colorSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _colorBorder, width: 1.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "DETALLE",
                                          style: GoogleFonts.roboto(
                                            color: _colorAccent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, color: _colorAccent, size: 11),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DETALLE COMPLETO DEL INFORME
  // ===========================================================================
  void _mostrarFormularioCompletoDialog(Map<String, dynamic> datos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colorSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _colorBorder, width: 1.2),
        ),
        title: Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: _colorAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              "DETALLE DE AUDITORÍA",
              style: GoogleFonts.roboto(fontWeight: FontWeight.w800, fontSize: 14, color: _colorText),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _colorAccentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "AUDITORÍA NRO ${datos['id']} • ${datos['fecha']}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontWeight: FontWeight.w800, fontSize: 11, color: _colorAccentDark),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildDatoItem("ID de Registro", datos['id']),
                _buildDatoItem("Clave Local", datos['reg_local']),
                _buildDatoItem("Tipo Unidad", datos['tipo_unidad']),
                _buildDatoItem("Móvil / Modelo", datos['unidad']),
                _buildDatoItem("Patente", datos['dominio']),
                _buildDatoItem("Marca", datos['marca']),
                _buildDatoItem("Interno", datos['interno']),
                _buildDatoItem("Próximo Service", datos['fecha_prox_Ser']),
                _buildDatoItem("Conductor", datos['utilizado_por']),
                _buildDatoItem("Inspección", datos['inspecciono']),
                _buildDatoItem("Tarjeta Verde", datos['tarjeta_verde']),
                _buildDatoItem("Comprobante Patente", datos['comprobante_patente']),
                _buildDatoItem("Obra Base / Destino", datos['obra_base']),
                _buildDatoItem("Seguro", datos['comprobante_seguro']),
                _buildDatoItem("Cédula Transporte", datos['cedula_transporte']),
                _buildDatoItem("VTI", datos['verificacion_tec']),
                _buildDatoItem("Doc Chofer", datos['doc_chofer']),
                _buildDatoItem("Fecha Vto Carga", datos['fecha_vto']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CERRAR",
              style: GoogleFonts.roboto(color: _colorAccent, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDatoItem(String etiqueta, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: GoogleFonts.roboto(color: _colorTextSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 1),
          Text(
            valor?.toString() ?? 'SIN REGISTRO',
            style: GoogleFonts.roboto(color: _colorText, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Divider(color: _colorBorder, thickness: 0.8),
        ],
      ),
    );
  }
}