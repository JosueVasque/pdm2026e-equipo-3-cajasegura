import 'dart:io';

import 'package:caja_segura/data/base_datos/base_datos_local.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directorio;
  late BaseDatosLocal base;
  late CajaRepositorio cajas;
  late MovimientoRepositorio movimientos;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('caja_segura_test_');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: path.join(directorio.path, 'prueba.db'),
    );
    cajas = CajaRepositorio(baseDatos: base);
    movimientos = MovimientoRepositorio(baseDatos: base);
  });
  tearDown(() async {
    await base.cerrar();
    await directorio.delete(recursive: true);
  });

  test('crea la caja y el historial en una conexión compartida', () async {
    final resultados = await Future.wait<Object>([
      cajas.obtenerCaja(),
      movimientos.obtenerHistorial(),
    ]);
    final caja = resultados[0] as Caja;
    final historial = resultados[1] as List<Movimiento>;
    expect(caja.efectivoTotal, 2500);
    expect(caja.reservaInsumos, 1200);
    expect(caja.disponibleParaSueldo, 1300);
    expect(historial, hasLength(8));
    expect(historial.first.descripcion, 'Venta de garrafones');
    expect(historial.first.fecha, DateTime(2026, 10, 7));
    expect(historial.first.tipo, TipoMovimiento.ingreso);
    expect(historial.first.ambito, AmbitoMovimiento.empresa);
    expect(historial.firstWhere((m) => m.id == '5').monto, 275.50);
  });

  test('conserva cambios al reabrir sin volver a sembrar datos', () async {
    await cajas.guardarCaja(
      const Caja(efectivoTotal: 2345.67, reservaInsumos: 1100.25),
    );
    final nuevo = Movimiento(
      id: 'nuevo',
      descripcion: 'Ingreso personal de prueba',
      monto: 100.15,
      tipo: TipoMovimiento.ingreso,
      ambito: AmbitoMovimiento.personal,
      fecha: DateTime(2026, 10, 15, 12, 30),
    );
    await movimientos.registrarMovimiento(nuevo);
    final ruta = (await base.database).path;
    await base.cerrar();
    base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    final caja = await CajaRepositorio(baseDatos: base).obtenerCaja();
    final historial = await MovimientoRepositorio(
      baseDatos: base,
    ).obtenerHistorial();
    expect(caja.efectivoTotal, 2345.67);
    expect(caja.reservaInsumos, 1100.25);
    expect(historial, hasLength(9));
    expect(historial.first.id, nuevo.id);
    expect(historial.first.monto, nuevo.monto);
    expect(historial.first.fecha, nuevo.fecha);
    expect(historial.first.ambito, nuevo.ambito);
  });

  test('rechaza importes inválidos sin cambiar los datos', () async {
    for (final monto in [-1.0, double.nan, double.infinity]) {
      await expectLater(
        cajas.guardarCaja(Caja(efectivoTotal: monto, reservaInsumos: 1200)),
        throwsArgumentError,
      );
    }
    await expectLater(
      movimientos.registrarMovimiento(
        Movimiento(
          id: 'invalido',
          descripcion: 'Prueba',
          monto: 0,
          tipo: TipoMovimiento.gasto,
          ambito: AmbitoMovimiento.empresa,
          fecha: DateTime(2026),
        ),
      ),
      throwsArgumentError,
    );
    expect((await cajas.obtenerCaja()).efectivoTotal, 2500);
    expect(await movimientos.obtenerHistorial(), hasLength(8));
  });

  test('un id duplicado no sobrescribe el movimiento existente', () async {
    final original = (await movimientos.obtenerHistorial()).first;
    await expectLater(
      movimientos.registrarMovimiento(original),
      throwsA(isA<DatabaseException>()),
    );
    expect(await movimientos.obtenerHistorial(), hasLength(8));
  });
}
