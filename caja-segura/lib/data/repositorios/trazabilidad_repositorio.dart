import 'dart:convert';
import '../../domain/modelos/trazabilidad.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/trazabilidad_local.dart';

class TrazabilidadRepositorio {
  TrazabilidadRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;
  final BaseDatosLocal _baseDatos;
  Future<List<Map<String, dynamic>>> instantaneas(String cierreId) async {
    final db = await _baseDatos.database;
    final filas = await db.query(
      'movimientos_conciliados',
      where: 'cierre_id = ?',
      whereArgs: [cierreId],
      orderBy: 'movimiento_id',
    );
    return filas
        .map(
          (f) => jsonDecode(f['instantanea'] as String) as Map<String, dynamic>,
        )
        .toList();
  }

  Future<List<CambioMovimiento>> cambios({String? movimientoId}) async {
    final db = await _baseDatos.database;
    final filas = await db.query(
      'auditoria',
      where: movimientoId == null ? null : 'movimiento_id = ?',
      whereArgs: movimientoId == null ? null : [movimientoId],
      orderBy: 'fecha DESC, id DESC',
    );
    return filas
        .map(
          (f) => CambioMovimiento(
            fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
            accion: f['accion'] as String,
            motivo: f['motivo'] as String,
            movimientoId: f['movimiento_id'] as String?,
            antes: f['antes'] == null
                ? null
                : jsonDecode(f['antes'] as String) as Map<String, dynamic>,
            despues: f['despues'] == null
                ? null
                : jsonDecode(f['despues'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<AjusteMovimiento>> ajustes({String? movimientoId}) async {
    final db = await _baseDatos.database;
    final filas = await db.query(
      'ajustes_movimiento',
      where: movimientoId == null ? null : 'movimiento_id = ?',
      whereArgs: movimientoId == null ? null : [movimientoId],
      orderBy: 'fecha DESC, id DESC',
    );
    return filas
        .map(
          (f) => AjusteMovimiento(
            id: f['id'] as String,
            movimientoId: f['movimiento_id'] as String,
            fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
            deltaCentavos: f['delta_centavos'] as int,
            motivo: f['motivo'] as String,
          ),
        )
        .toList();
  }

  Future<void> ajustar({
    required String id,
    required String movimientoId,
    required int deltaCentavos,
    required String motivo,
    bool autorizarReserva = false,
  }) async {
    if (id.trim().isEmpty || motivo.trim().isEmpty) {
      throw ArgumentError('Explica el motivo del ajuste.');
    }
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      final filas = await txn.query(
        'movimientos',
        where: 'id = ?',
        whereArgs: [movimientoId],
      );
      if (filas.isEmpty) throw StateError('El movimiento ya no existe.');
      final cerrado = await txn.query(
        'movimientos_conciliados',
        where: 'movimiento_id = ?',
        whereArgs: [movimientoId],
        limit: 1,
      );
      if (cerrado.isEmpty) {
        throw StateError(
          'El movimiento aún es editable. Usa la corrección con motivo.',
        );
      }
      if (filas.single['ambito'] == 'personal' && deltaCentavos != 0) {
        throw ArgumentError(
          'Una aclaración personal no modifica el efectivo del negocio.',
        );
      }
      final caja = (await txn.query('caja', where: 'id = 1')).single;
      final saldo = (caja['efectivo_centavos'] as int) + deltaCentavos;
      if (saldo < 0) {
        throw StateError('El ajuste dejaría la caja con saldo negativo.');
      }
      if (deltaCentavos < 0 &&
          saldo < (caja['reserva_centavos'] as int) &&
          !autorizarReserva) {
        throw ReservaRequiereConfirmacion(
          (caja['reserva_centavos'] as int) - saldo,
        );
      }
      final ajuste = <String, Object?>{
        'id': id,
        'movimiento_id': movimientoId,
        'fecha': DateTime.now().millisecondsSinceEpoch,
        'delta_centavos': deltaCentavos,
        'motivo': motivo.trim(),
      };
      await txn.insert('ajustes_movimiento', ajuste);
      await txn.update('caja', {'efectivo_centavos': saldo}, where: 'id = 1');
      await registrarCambio(
        txn,
        movimientoId: movimientoId,
        accion: 'ajuste_conciliado',
        motivo: motivo,
        antes: {...caja, 'descripcion': filas.single['descripcion']},
        despues: {...caja, ...ajuste, 'efectivo_centavos': saldo},
      );
    });
  }
}
