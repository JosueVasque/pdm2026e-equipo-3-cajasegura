import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reconstruye el esquema previo para las pruebas de migración.
Future<void> quitarTrazabilidad(Database db) async {
  for (final tabla in [
    'auditoria',
    'ajustes_movimiento',
    'movimientos_conciliados',
    'cierres',
  ]) {
    for (final operacion in ['update', 'delete']) {
      await db.execute('DROP TRIGGER IF EXISTS ${tabla}_$operacion');
    }
  }
  await db.execute('DROP TRIGGER IF EXISTS movimientos_update_protegidos');
  await db.execute('DROP TRIGGER IF EXISTS movimientos_delete_protegidos');
  await db.execute('DROP TABLE ajustes_movimiento');
  await db.execute('DROP TABLE movimientos_conciliados');
  await db.execute('DROP TABLE auditoria');
}
