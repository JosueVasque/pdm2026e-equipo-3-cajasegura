import '../../domain/modelos/movimiento.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../base_datos/trazabilidad_local.dart';

class MovimientoRepositorio {
  MovimientoRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;

  final BaseDatosLocal _baseDatos;

  Future<List<Movimiento>> obtenerHistorial() async {
    final db = await _baseDatos.database;
    final filas = await db.rawQuery(
      'SELECT m.*, EXISTS(SELECT 1 FROM movimientos_conciliados c WHERE c.movimiento_id = m.id) AS conciliado FROM movimientos m ORDER BY m.fecha DESC, m.id DESC',
    );
    return filas.map(movimientoDesdeFila).toList();
  }

  Future<void> eliminarMovimiento(String id) async {
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      await exigirEditable(txn, id);
      final filas = await txn.query(
        'movimientos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (filas.isEmpty) throw StateError('El movimiento ya no existe.');
      await _ajustarSaldo(txn, -(filas.single['impacto_caja_centavos'] as int));
      await txn.delete('movimientos', where: 'id = ?', whereArgs: [id]);
      await registrarCambio(
        txn,
        movimientoId: id,
        accion: 'eliminacion',
        motivo: 'Eliminación desde el historial antes de conciliar',
        antes: filas.single,
      );
    });
  }

  Future<void> registrarMovimiento(Movimiento movimiento) =>
      _registrarMovimiento(movimiento);

  Future<void> registrarMovimientoConReserva(
    Movimiento movimiento, {
    bool autorizarReserva = false,
  }) => _registrarMovimiento(
    movimiento,
    avisarReserva: true,
    autorizarReserva: autorizarReserva,
  );

  Future<void> _registrarMovimiento(
    Movimiento movimiento, {
    bool avisarReserva = false,
    bool autorizarReserva = false,
  }) async {
    if (movimiento.esRetiro) {
      throw ArgumentError('Usa la confirmación de retiro de sueldo.');
    }
    final fila = movimientoAFila(movimiento);
    final impacto = movimiento.esEmpresa
        ? (movimiento.esIngreso ? 1 : -1) * aCentavos(movimiento.monto)
        : 0;
    fila['impacto_caja_centavos'] = impacto;
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      await _validarCategoria(txn, movimiento.categoriaId);
      if (avisarReserva && !autorizarReserva && impacto < 0) {
        final caja = (await txn.query('caja', where: 'id = 1')).single;
        final restante = (caja['efectivo_centavos'] as int) + impacto;
        final reserva = caja['reserva_centavos'] as int;
        if (restante < 0) {
          throw StateError('El gasto supera el efectivo de la caja.');
        }
        if (restante < reserva) {
          throw ReservaRequiereConfirmacion(reserva - restante);
        }
      }
      await _ajustarSaldo(txn, impacto);
      await txn.insert('movimientos', fila);
      await registrarCambio(
        txn,
        movimientoId: movimiento.id,
        accion: 'alta',
        motivo: 'Registro de movimiento',
        despues: fila,
      );
    });
  }

  Future<void> restaurarMovimiento(Movimiento movimiento) async {
    final fila = movimientoAFila(movimiento);
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      await _ajustarSaldo(txn, movimiento.impactoCajaCentavos);
      await txn.insert('movimientos', fila);
      await registrarCambio(
        txn,
        movimientoId: movimiento.id,
        accion: 'restauracion',
        motivo: 'Deshacer eliminación',
        despues: fila,
      );
    });
  }

  Future<void> asignarCategoria(String id, int? categoriaId) async {
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      await exigirEditable(txn, id);
      final actual = await txn.query(
        'movimientos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (actual.isEmpty) throw StateError('El movimiento ya no existe.');
      if (actual.single['categoria_id'] != categoriaId) {
        await _validarCategoria(txn, categoriaId);
      }
      final filas = await txn.update(
        'movimientos',
        {'categoria_id': categoriaId},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (filas == 0) throw StateError('El movimiento ya no existe.');
      await registrarCambio(
        txn,
        movimientoId: id,
        accion: 'categoria',
        motivo: 'Cambio de categoría antes de conciliar',
        antes: actual.single,
        despues: {...actual.single, 'categoria_id': categoriaId},
      );
    });
  }

  Future<void> confirmarRetiro(double monto, String id) async {
    final centavos = aCentavos(monto);
    if (centavos <= 0) throw ArgumentError('Ingresa un monto mayor a cero.');
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      final caja = (await txn.query('caja', where: 'id = 1')).single;
      final restante = (caja['efectivo_centavos'] as int) - centavos;
      if (restante < (caja['reserva_centavos'] as int)) {
        throw StateError(
          'El saldo cambió o el retiro afecta la reserva. Revisa el monto.',
        );
      }
      await _ajustarSaldo(txn, -centavos);
      await txn.insert(
        'movimientos',
        movimientoAFila(
          Movimiento(
            id: id,
            descripcion: 'Retiro de sueldo',
            monto: centavos / 100,
            tipo: TipoMovimiento.gasto,
            ambito: AmbitoMovimiento.empresa,
            fecha: DateTime.now(),
            impactoCajaCentavos: -centavos,
            esRetiro: true,
          ),
        ),
      );
      final fila = (await txn.query(
        'movimientos',
        where: 'id = ?',
        whereArgs: [id],
      )).single;
      await registrarCambio(
        txn,
        movimientoId: id,
        accion: 'retiro',
        motivo: 'Retiro de sueldo confirmado',
        despues: fila,
      );
    });
  }

  Future<void> actualizarMovimiento(
    Movimiento original,
    Movimiento nuevo,
    String motivo, {
    bool autorizarReserva = false,
  }) async {
    if (original.id != nuevo.id || motivo.trim().isEmpty) {
      throw ArgumentError('Explica el motivo de la corrección.');
    }
    if (original.esRetiro != nuevo.esRetiro ||
        (original.esRetiro && (!nuevo.esEmpresa || nuevo.esIngreso))) {
      throw ArgumentError('Un retiro de sueldo debe conservar su naturaleza.');
    }
    final fila = movimientoAFila(nuevo);
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      await exigirEditable(txn, original.id);
      final filas = await txn.query(
        'movimientos',
        where: 'id = ?',
        whereArgs: [original.id],
      );
      if (filas.isEmpty) throw StateError('El movimiento ya no existe.');
      final antes = filas.single;
      final esperado = movimientoAFila(original);
      if (esperado.keys.any((k) => antes[k] != esperado[k])) {
        throw StateError(
          'El movimiento cambió. Vuelve a abrirlo antes de corregirlo.',
        );
      }
      if (antes['categoria_id'] != nuevo.categoriaId) {
        await _validarCategoria(txn, nuevo.categoriaId);
      }
      // Los movimientos históricos de demostración nunca afectaron la caja.
      final impacto = original.esEmpresa && original.impactoCajaCentavos == 0
          ? 0
          : nuevo.esEmpresa
          ? (nuevo.esIngreso ? 1 : -1) * aCentavos(nuevo.monto)
          : 0;
      final delta = impacto - (antes['impacto_caja_centavos'] as int);
      final caja = (await txn.query('caja', where: 'id = 1')).single;
      final saldo = (caja['efectivo_centavos'] as int) + delta;
      if (saldo < 0) {
        throw StateError('La corrección dejaría la caja con saldo negativo.');
      }
      if (delta < 0 && saldo < (caja['reserva_centavos'] as int)) {
        if (original.esRetiro) {
          throw StateError('La corrección del retiro afecta la reserva.');
        }
        if (!autorizarReserva) {
          throw ReservaRequiereConfirmacion(
            (caja['reserva_centavos'] as int) - saldo,
          );
        }
      }
      fila['impacto_caja_centavos'] = impacto;
      await _ajustarSaldo(txn, delta);
      await txn.update(
        'movimientos',
        fila,
        where: 'id = ?',
        whereArgs: [original.id],
      );
      await registrarCambio(
        txn,
        movimientoId: original.id,
        accion: 'correccion',
        motivo: motivo,
        antes: antes,
        despues: fila,
      );
    });
  }

  Future<void> _validarCategoria(Transaction txn, int? id) async {
    if (id == null) return;
    final filas = await txn.query(
      'categorias',
      where: 'id = ? AND archivada = 0',
      whereArgs: [id],
    );
    if (filas.isEmpty) throw StateError('Selecciona una categoría activa.');
  }

  Future<void> _ajustarSaldo(Transaction txn, int impacto) async {
    final filas = await txn.query('caja', where: 'id = 1');
    if (filas.isEmpty) throw StateError('No se encontró la caja.');
    final saldo = (filas.single['efectivo_centavos'] as int) + impacto;
    if (saldo < 0) {
      throw StateError('La operación dejaría la caja con saldo negativo.');
    }
    await txn.update('caja', {'efectivo_centavos': saldo}, where: 'id = 1');
  }
}
