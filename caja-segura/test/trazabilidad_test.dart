import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caja_segura/data/base_datos/base_datos_local.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/cierre_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/data/repositorios/trazabilidad_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/modelos/trazabilidad.dart';
import 'package:caja_segura/domain/casos_uso/evaluar_reserva.dart';
import 'package:caja_segura/domain/casos_uso/generar_reporte.dart';
import 'soporte/esquema_anterior.dart';

void main() {
  sqfliteFfiInit();
  late Directory carpeta;
  late BaseDatosLocal base;
  late CajaRepositorio caja;
  late MovimientoRepositorio movimientos;
  late CierreRepositorio cierres;
  late TrazabilidadRepositorio trazabilidad;
  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('trazabilidad_');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${carpeta.path}/caja.db',
    );
    caja = CajaRepositorio(baseDatos: base);
    movimientos = MovimientoRepositorio(baseDatos: base);
    cierres = CierreRepositorio(baseDatos: base);
    trazabilidad = TrazabilidadRepositorio(baseDatos: base);
  });
  tearDown(() async {
    await base.cerrar();
    await carpeta.delete(recursive: true);
  });
  Movimiento nuevo(
    String id, {
    double monto = 100,
    bool ingreso = true,
    bool personal = false,
    DateTime? fecha,
  }) => Movimiento(
    id: id,
    descripcion: 'Venta',
    monto: monto,
    tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
    ambito: personal ? AmbitoMovimiento.personal : AmbitoMovimiento.empresa,
    fecha: fecha ?? DateTime.now(),
  );
  Future<Movimiento> obtener(String id) async =>
      (await movimientos.obtenerHistorial()).singleWhere((m) => m.id == id);
  Movimiento corregido(
    Movimiento m,
    double monto, {
    String descripcion = 'Venta corregida',
    bool? personal,
  }) => Movimiento(
    id: m.id,
    descripcion: descripcion,
    monto: monto,
    tipo: m.tipo,
    ambito: personal == null
        ? m.ambito
        : personal
        ? AmbitoMovimiento.personal
        : AmbitoMovimiento.empresa,
    fecha: m.fecha,
    categoriaId: m.categoriaId,
    esRetiro: m.esRetiro,
    impactoCajaCentavos: m.impactoCajaCentavos,
  );
  Future<void> cerrar(String id) async {
    final saldo = (await caja.obtenerCaja()).efectivoTotal;
    await cierres.confirmar(
      id: id,
      esperado: saldo,
      contado: saldo,
      nota: 'Verificado',
    );
  }

  test(
    'editar antes del cierre ajusta solo diferencia y conserva datos anteriores y nuevos',
    () async {
      await movimientos.registrarMovimiento(nuevo('venta'));
      final original = await obtener('venta');
      await movimientos.actualizarMovimiento(
        original,
        corregido(original, 150),
        'Monto digitado incorrectamente',
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2650);
      final cambio = (await trazabilidad.cambios(movimientoId: 'venta')).first;
      expect(cambio.accion, 'correccion');
      expect(cambio.antes!['monto_centavos'], 10000);
      expect(cambio.despues!['monto_centavos'], 15000);
      expect(cambio.motivo, 'Monto digitado incorrectamente');
      await expectLater(
        movimientos.actualizarMovimiento(
          original,
          corregido(original, 200),
          'Otro',
        ),
        throwsStateError,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2650);
      await expectLater(
        movimientos.actualizarMovimiento(
          await obtener('venta'),
          corregido(await obtener('venta'), 200),
          ' ',
        ),
        throwsArgumentError,
      );
      expect(await trazabilidad.cambios(movimientoId: 'venta'), hasLength(2));
    },
  );

  test(
    'cambiar ámbito revierte efecto real; registros de demostración conservan efecto cero',
    () async {
      await movimientos.registrarMovimiento(nuevo('real'));
      final real = await obtener('real');
      await movimientos.actualizarMovimiento(
        real,
        corregido(real, 100, personal: true),
        'Era un ingreso personal',
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      final legado = await obtener('1');
      await movimientos.actualizarMovimiento(
        legado,
        corregido(legado, 900),
        'Corrección de demostración',
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      expect((await obtener('1')).impactoCajaCentavos, 0);
    },
  );

  test(
    'corrección que utiliza reserva pide consentimiento y errores no dejan datos parciales',
    () async {
      await movimientos.registrarMovimiento(nuevo('gasto', ingreso: false));
      final original = await obtener('gasto');
      await expectLater(
        movimientos.actualizarMovimiento(
          original,
          corregido(original, 1400),
          'Monto real',
        ),
        throwsA(isA<ReservaRequiereConfirmacion>()),
      );
      expect((await obtener('gasto')).monto, 100);
      await movimientos.actualizarMovimiento(
        original,
        corregido(original, 1400),
        'Monto real',
        autorizarReserva: true,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1100);
      final actual = await obtener('gasto');
      await expectLater(
        movimientos.actualizarMovimiento(
          actual,
          corregido(actual, 3000),
          'Error',
          autorizarReserva: true,
        ),
        throwsStateError,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1100);
      expect(await trazabilidad.cambios(movimientoId: 'gasto'), hasLength(2));
    },
  );

  test(
    'cerrar sella instantáneas y bloquea edición, categoría y borrado incluso por SQL directo',
    () async {
      await movimientos.registrarMovimiento(nuevo('sellado'));
      final original = await obtener('sellado');
      await cerrar('cierre');
      expect((await obtener('sellado')).conciliado, isTrue);
      await expectLater(
        movimientos.actualizarMovimiento(
          original,
          corregido(original, 150),
          'Intento posterior',
        ),
        throwsA(isA<MovimientoConciliadoException>()),
      );
      await expectLater(
        movimientos.eliminarMovimiento('sellado'),
        throwsA(isA<MovimientoConciliadoException>()),
      );
      await expectLater(
        movimientos.asignarCategoria('sellado', null),
        throwsA(isA<MovimientoConciliadoException>()),
      );
      final db = await base.database;
      await expectLater(
        db.update(
          'movimientos',
          {'monto_centavos': 999},
          where: 'id = ?',
          whereArgs: ['sellado'],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.delete('movimientos', where: 'id = ?', whereArgs: ['sellado']),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.update('cierres', {'contado_centavos': 0}),
        throwsA(isA<DatabaseException>()),
      );
      final foto = (await db.query(
        'movimientos_conciliados',
        where: 'movimiento_id = ?',
        whereArgs: ['sellado'],
      )).single;
      expect(
        (jsonDecode(foto['instantanea'] as String) as Map)['monto_centavos'],
        10000,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2600);
    },
  );

  test(
    'movimientos registrados después del cierre siguen editables aunque tengan fecha anterior',
    () async {
      await cerrar('primero');
      await movimientos.registrarMovimiento(
        nuevo('posterior', fecha: DateTime(2026, 1, 1)),
      );
      final posterior = await obtener('posterior');
      expect(posterior.conciliado, isFalse);
      await movimientos.actualizarMovimiento(
        posterior,
        corregido(posterior, 120),
        'Monto real',
      );
      await cerrar('segundo');
      expect((await obtener('posterior')).conciliado, isTrue);
      expect((await caja.obtenerCaja()).efectivoTotal, 2620);
    },
  );

  test(
    'ajuste conciliado modifica caja con vínculo y motivo sin reescribir movimiento, reporte ni cierre',
    () async {
      await movimientos.registrarMovimiento(nuevo('original'));
      await cerrar('cierre');
      final antes = generarReporte(
        await movimientos.obtenerHistorial(),
        [],
      ).balanceCentavos;
      await trazabilidad.ajustar(
        id: 'ajuste',
        movimientoId: 'original',
        deltaCentavos: -2000,
        motivo: 'Devolución de diferencia',
      );
      expect((await obtener('original')).monto, 100);
      expect((await cierres.listar()).single.contadoCentavos, 260000);
      expect((await caja.obtenerCaja()).efectivoTotal, 2580);
      expect(
        generarReporte(
          await movimientos.obtenerHistorial(),
          [],
        ).balanceCentavos,
        antes,
      );
      expect(
        (await trazabilidad.ajustes(movimientoId: 'original')).single.motivo,
        'Devolución de diferencia',
      );
      await expectLater(
        trazabilidad.ajustar(
          id: 'ajuste',
          movimientoId: 'original',
          deltaCentavos: -2000,
          motivo: 'Duplicado',
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2580);
      expect(await trazabilidad.ajustes(), hasLength(1));
    },
  );

  test(
    'ajustes exigen conciliación, motivo, saldo y consentimiento; aclaración personal no mueve caja',
    () async {
      await movimientos.registrarMovimiento(nuevo('personal', personal: true));
      await expectLater(
        trazabilidad.ajustar(
          id: 'a',
          movimientoId: 'personal',
          deltaCentavos: 0,
          motivo: 'Aclaración',
        ),
        throwsStateError,
      );
      await cerrar('cierre');
      await expectLater(
        trazabilidad.ajustar(
          id: 'a',
          movimientoId: 'personal',
          deltaCentavos: 100,
          motivo: 'Inválido',
        ),
        throwsArgumentError,
      );
      await expectLater(
        trazabilidad.ajustar(
          id: 'a',
          movimientoId: '1',
          deltaCentavos: -140000,
          motivo: 'Corrección',
        ),
        throwsA(isA<ReservaRequiereConfirmacion>()),
      );
      await trazabilidad.ajustar(
        id: 'a',
        movimientoId: '1',
        deltaCentavos: -140000,
        motivo: 'Corrección',
        autorizarReserva: true,
      );
      await expectLater(
        trazabilidad.ajustar(
          id: 'b',
          movimientoId: '1',
          deltaCentavos: -200000,
          motivo: 'Excesivo',
          autorizarReserva: true,
        ),
        throwsStateError,
      );
      await expectLater(
        trazabilidad.ajustar(
          id: 'b',
          movimientoId: '1',
          deltaCentavos: 0,
          motivo: '',
        ),
        throwsArgumentError,
      );
      await trazabilidad.ajustar(
        id: 'personal',
        movimientoId: 'personal',
        deltaCentavos: 0,
        motivo: 'La descripción correcta es aporte familiar',
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1100);
    },
  );

  test(
    'borrar y deshacer dejan trazabilidad persistente e inmutable; caja manual también se audita',
    () async {
      await movimientos.registrarMovimiento(nuevo('borrable'));
      final original = await obtener('borrable');
      await movimientos.eliminarMovimiento(original.id);
      expect(
        (await trazabilidad.cambios(
          movimientoId: original.id,
        )).first.antes!['monto_centavos'],
        10000,
      );
      await movimientos.restaurarMovimiento(original);
      await caja.guardarCajaConMotivo(
        const Caja(efectivoTotal: 2600, reservaInsumos: 1300),
        'Nueva meta de insumos',
      );
      await base.cerrar();
      expect(
        await trazabilidad.cambios(movimientoId: original.id),
        hasLength(3),
      );
      expect((await trazabilidad.cambios()).first.accion, 'caja');
      final db = await base.database;
      await expectLater(
        db.delete('auditoria'),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.update('auditoria', {'motivo': 'Ocultar'}),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'migración desde v5 con cierres protege conservadoramente lo existente sin cambiar saldos',
    () async {
      await cerrar('anterior');
      await movimientos.registrarMovimiento(nuevo('sin-membresia-previa'));
      final db = await base.database;
      await quitarTrazabilidad(db);
      await db.setVersion(5);
      await base.cerrar();
      expect((await caja.obtenerCaja()).efectivoTotal, 2600);
      expect(await (await base.database).getVersion(), 6);
      expect(
        (await movimientos.obtenerHistorial()).every((m) => m.conciliado),
        isTrue,
      );
      expect(
        (await trazabilidad.cambios()).single.accion,
        'proteccion_migracion',
      );
      await movimientos.registrarMovimiento(nuevo('nuevo'));
      expect((await obtener('nuevo')).conciliado, isFalse);
    },
  );
}
