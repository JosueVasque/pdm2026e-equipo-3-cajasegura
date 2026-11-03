import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/modelos/trazabilidad.dart';

Future<void> registrarCambio(
  DatabaseExecutor db, {
  String? movimientoId,
  required String accion,
  required String motivo,
  Map<String, Object?>? antes,
  Map<String, Object?>? despues,
}) async {
  if (motivo.trim().isEmpty) {
    throw ArgumentError('Explica el motivo de la corrección.');
  }
  await db.insert('auditoria', {
    'movimiento_id': movimientoId,
    'fecha': DateTime.now().millisecondsSinceEpoch,
    'accion': accion,
    'motivo': motivo.trim(),
    'antes': antes == null ? null : jsonEncode(antes),
    'despues': despues == null ? null : jsonEncode(despues),
  });
}

Future<void> exigirEditable(DatabaseExecutor db, String id) async {
  final filas = await db.query(
    'movimientos_conciliados',
    columns: ['movimiento_id'],
    where: 'movimiento_id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (filas.isNotEmpty) throw const MovimientoConciliadoException();
}

Future<void> sellarMovimientos(
  DatabaseExecutor db,
  String cierreId, {
  bool migracion = false,
}) async {
  final filas = await db.rawQuery(
    'SELECT m.*, c.nombre AS categoria_nombre FROM movimientos m LEFT JOIN categorias c ON c.id = m.categoria_id',
  );
  final batch = db.batch();
  for (final fila in filas) {
    batch.insert('movimientos_conciliados', {
      'cierre_id': cierreId,
      'movimiento_id': fila['id'],
      'instantanea': jsonEncode({...fila, 'capturada_en_migracion': migracion}),
    });
  }
  await batch.commit(noResult: true);
}

Future<void> crearTrazabilidad(DatabaseExecutor db) async {
  await db.execute('''CREATE TABLE movimientos_conciliados (
    cierre_id TEXT NOT NULL REFERENCES cierres(id) ON DELETE RESTRICT,
    movimiento_id TEXT NOT NULL REFERENCES movimientos(id) ON DELETE RESTRICT,
    instantanea TEXT NOT NULL,
    PRIMARY KEY(cierre_id, movimiento_id)
  )''');
  await db.execute(
    'CREATE INDEX conciliados_movimiento ON movimientos_conciliados(movimiento_id)',
  );
  await db.execute('''CREATE TABLE auditoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT, movimiento_id TEXT, fecha INTEGER NOT NULL,
    accion TEXT NOT NULL, motivo TEXT NOT NULL CHECK(length(trim(motivo)) > 0), antes TEXT, despues TEXT
  )''');
  await db.execute('''CREATE TABLE ajustes_movimiento (
    id TEXT PRIMARY KEY NOT NULL, movimiento_id TEXT NOT NULL REFERENCES movimientos(id) ON DELETE RESTRICT,
    fecha INTEGER NOT NULL, delta_centavos INTEGER NOT NULL,
    motivo TEXT NOT NULL CHECK(length(trim(motivo)) > 0)
  )''');
  for (final tabla in [
    'auditoria',
    'ajustes_movimiento',
    'movimientos_conciliados',
    'cierres',
  ]) {
    for (final operacion in ['UPDATE', 'DELETE']) {
      await db.execute(
        'CREATE TRIGGER ${tabla}_${operacion.toLowerCase()} BEFORE $operacion ON $tabla BEGIN SELECT RAISE(ABORT, \'REGISTRO_INMUTABLE\'); END',
      );
    }
  }
  for (final operacion in ['UPDATE', 'DELETE']) {
    await db.execute(
      'CREATE TRIGGER movimientos_${operacion.toLowerCase()}_protegidos BEFORE $operacion ON movimientos '
      'WHEN EXISTS(SELECT 1 FROM movimientos_conciliados WHERE movimiento_id = OLD.id) '
      'BEGIN SELECT RAISE(ABORT, \'MOVIMIENTO_CONCILIADO\'); END',
    );
  }
}
