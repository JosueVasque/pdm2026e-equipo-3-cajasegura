import '../../domain/modelos/caja.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';
import '../base_datos/trazabilidad_local.dart';

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

  Future<void> guardarCaja(Caja caja) =>
      guardarCajaConMotivo(caja, 'Actualización de caja');

  Future<void> guardarCajaConMotivo(Caja caja, String motivo) async {
    if (motivo.trim().isEmpty) {
      throw ArgumentError('Explica el motivo del cambio de caja.');
    }
    final fila = cajaAFila(caja);
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      final anterior = (await txn.query('caja', where: 'id = 1')).single;
      await txn.update('caja', fila, where: 'id = 1');
      await registrarCambio(
        txn,
        accion: 'caja',
        motivo: motivo,
        antes: anterior,
        despues: fila,
      );
    });
  }
}
