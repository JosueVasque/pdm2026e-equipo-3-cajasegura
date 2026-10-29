import '../../domain/modelos/movimiento.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';

class MovimientoRepositorio {
  MovimientoRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;

  final BaseDatosLocal _baseDatos;

  Future<List<Movimiento>> obtenerHistorial() async {
    final db = await _baseDatos.database;
    final filas = await db.query('movimientos', orderBy: 'fecha DESC, id DESC');
    return filas.map(movimientoDesdeFila).toList();
  }

  Future<void> eliminarMovimiento(String id) async {
    final db = await _baseDatos.database;
    await db.delete('movimientos', where: 'id = ?', whereArgs: [id]);
  }

  /// Guarda un registro del historial; no modifica el saldo de caja.
  Future<void> registrarMovimiento(Movimiento movimiento) async {
    final fila = movimientoAFila(movimiento);
    final db = await _baseDatos.database;
    await db.insert('movimientos', fila);
  }
}
