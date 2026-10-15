import '../../domain/modelos/caja.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';

class CajaRepositorio {
  CajaRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;

  final BaseDatosLocal _baseDatos;

  Future<Caja> obtenerCaja() async {
    final db = await _baseDatos.database;
    final filas = await db.query('caja', where: 'id = ?', whereArgs: [1]);
    if (filas.isEmpty) {
      throw StateError('No se encontró la caja del negocio');
    }
    return cajaDesdeFila(filas.single);
  }

  Future<void> guardarCaja(Caja caja) async {
    final fila = cajaAFila(caja);
    final db = await _baseDatos.database;
    await db.update('caja', fila, where: 'id = ?', whereArgs: [1]);
  }
}
