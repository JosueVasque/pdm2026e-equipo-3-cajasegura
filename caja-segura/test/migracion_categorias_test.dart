import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:caja_segura/data/base_datos/base_datos_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory directorio;
  late String ruta;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp(
      'caja_segura_migracion_',
    );
    ruta = '${directorio.path}${Platform.pathSeparator}migracion.db';
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(ruta);
    await directorio.delete(recursive: true);
  });

  test('migra de v1 a v3 conservando caja y movimientos', () async {
    // Simular una instalación antigua con esquema versión 1.
    final antigua = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE caja (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              efectivo_centavos INTEGER NOT NULL CHECK (efectivo_centavos >= 0),
              reserva_centavos INTEGER NOT NULL CHECK (reserva_centavos >= 0)
            )
          ''');

          await db.execute('''
            CREATE TABLE movimientos (
              id TEXT PRIMARY KEY NOT NULL,
              descripcion TEXT NOT NULL,
              monto_centavos INTEGER NOT NULL CHECK (monto_centavos > 0),
              tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
              ambito TEXT NOT NULL CHECK (ambito IN ('empresa', 'personal')),
              fecha INTEGER NOT NULL
            )
          ''');

          await db.execute(
            'CREATE INDEX movimientos_fecha ON movimientos (fecha DESC)',
          );
        },
      ),
    );

    await antigua.insert('caja', {
      'id': 1,
      'efectivo_centavos': 150000,
      'reserva_centavos': 25000,
    });

    await antigua.insert('movimientos', {
      'id': 'mov-antiguo-1',
      'descripcion': 'Venta anterior',
      'monto_centavos': 5000,
      'tipo': 'ingreso',
      'ambito': 'empresa',
      'fecha': 1700000000000,
    });

    await antigua.close();

    // Abrir la misma base con la implementación actual.
    final baseDatos = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);

    try {
      final db = await baseDatos.database;

      final version = await db.getVersion();
      expect(version, 3);

      final caja = await db.query('caja');
      expect(caja, hasLength(1));
      expect(caja.first['efectivo_centavos'], 150000);
      expect(caja.first['reserva_centavos'], 25000);

      final movimientos = await db.query('movimientos');
      expect(movimientos, hasLength(1));
      expect(movimientos.first['id'], 'mov-antiguo-1');
      expect(movimientos.first['descripcion'], 'Venta anterior');
      expect(movimientos.first['categoria_id'], isNull);

      final columnas = await db.rawQuery('PRAGMA table_info(movimientos)');
      expect(
        columnas.any((columna) => columna['name'] == 'categoria_id'),
        isTrue,
      );

      final categorias = await db.query('categorias');
      expect(categorias, isEmpty);
    } finally {
      await baseDatos.cerrar();
    }
  });
}
