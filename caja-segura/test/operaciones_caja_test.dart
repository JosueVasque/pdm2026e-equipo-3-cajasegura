import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caja_segura/data/base_datos/base_datos_local.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/categoria_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/casos_uso/evaluar_reserva.dart';
import 'soporte/esquema_anterior.dart';

void main() {
  sqfliteFfiInit();
  late Directory carpeta;
  late BaseDatosLocal base;
  late CajaRepositorio caja;
  late MovimientoRepositorio movimientos;
  late CategoriaRepositorio categorias;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('operaciones_caja_');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${carpeta.path}/caja.db',
    );
    caja = CajaRepositorio(baseDatos: base);
    movimientos = MovimientoRepositorio(baseDatos: base);
    categorias = CategoriaRepositorio(baseDatos: base);
  });
  tearDown(() async {
    await base.cerrar();
    await carpeta.delete(recursive: true);
  });

  Movimiento movimiento(
    String id, {
    double monto = 100,
    TipoMovimiento tipo = TipoMovimiento.ingreso,
    AmbitoMovimiento ambito = AmbitoMovimiento.empresa,
    int? categoria,
  }) => Movimiento(
    id: id,
    descripcion: 'Operación',
    monto: monto,
    tipo: tipo,
    ambito: ambito,
    fecha: DateTime(2026, 11, 3),
    categoriaId: categoria,
  );

  test(
    'gasto que usa reserva requiere consentimiento sin guardar cambios parciales',
    () async {
      final gasto = movimiento(
        'reserva',
        monto: 1400,
        tipo: TipoMovimiento.gasto,
      );
      await expectLater(
        movimientos.registrarMovimientoConReserva(gasto),
        throwsA(
          isA<ReservaRequiereConfirmacion>().having(
            (e) => e.faltanteCentavos,
            'faltante',
            10000,
          ),
        ),
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      expect(await movimientos.obtenerHistorial(), hasLength(8));
      await movimientos.registrarMovimientoConReserva(
        gasto,
        autorizarReserva: true,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1100);
      expect(await movimientos.obtenerHistorial(), hasLength(9));
      await expectLater(
        movimientos.registrarMovimientoConReserva(
          movimiento('excesivo', monto: 2000, tipo: TipoMovimiento.gasto),
          autorizarReserva: true,
        ),
        throwsStateError,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1100);
    },
  );

  test(
    'retiro, borrar y restaurar actualizan saldo e historial y persisten',
    () async {
      await movimientos.confirmarRetiro(500, 'retiro');
      expect((await caja.obtenerCaja()).efectivoTotal, 2000);
      final retiro = (await movimientos.obtenerHistorial()).firstWhere(
        (m) => m.id == 'retiro',
      );
      expect(retiro.impactoCajaCentavos, -50000);
      await movimientos.eliminarMovimiento('retiro');
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      await movimientos.restaurarMovimiento(retiro);
      await base.cerrar();
      expect((await caja.obtenerCaja()).efectivoTotal, 2000);
      expect(
        (await movimientos.obtenerHistorial()).where((m) => m.id == 'retiro'),
        hasLength(1),
      );
    },
  );

  test(
    'retiro consulta saldo vigente y protege reserva; duplicado revierte descuento',
    () async {
      await movimientos.confirmarRetiro(1000, 'retiro');
      await expectLater(
        movimientos.confirmarRetiro(500, 'otro'),
        throwsStateError,
      );
      await expectLater(
        movimientos.confirmarRetiro(100, 'retiro'),
        throwsA(isA<DatabaseException>()),
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 1500);
      expect(await movimientos.obtenerHistorial(), hasLength(9));
      await expectLater(
        movimientos.confirmarRetiro(double.nan, 'nan'),
        throwsArgumentError,
      );
    },
  );

  test(
    'empresa modifica saldo, personal no; asignar categoría no altera saldo',
    () async {
      final id = await categorias.crear('Ventas');
      await movimientos.registrarMovimiento(movimiento('venta', categoria: id));
      await movimientos.registrarMovimiento(
        movimiento('gasto', monto: 80, tipo: TipoMovimiento.gasto),
      );
      await movimientos.registrarMovimiento(
        movimiento(
          'personal',
          monto: 200,
          tipo: TipoMovimiento.gasto,
          ambito: AmbitoMovimiento.personal,
        ),
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2520);
      await movimientos.asignarCategoria('gasto', id);
      expect(
        (await movimientos.obtenerHistorial())
            .firstWhere((m) => m.id == 'gasto')
            .categoriaId,
        id,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2520);
      await categorias.archivar(id);
      await movimientos.asignarCategoria(
        'gasto',
        id,
      ); // Conservar clasificación histórica.
      await expectLater(
        movimientos.registrarMovimiento(movimiento('archivada', categoria: id)),
        throwsStateError,
      );
      await movimientos.asignarCategoria('gasto', null);
      await expectLater(
        categorias.eliminar(id),
        throwsA(isA<CategoriaEnUsoException>()),
      );
    },
  );

  test(
    'saldo insuficiente, categoría inválida y duplicado no dejan cambios parciales',
    () async {
      await expectLater(
        movimientos.registrarMovimiento(
          movimiento('grande', monto: 3000, tipo: TipoMovimiento.gasto),
        ),
        throwsStateError,
      );
      await expectLater(
        movimientos.registrarMovimiento(movimiento('invalida', categoria: 999)),
        throwsStateError,
      );
      await movimientos.registrarMovimiento(movimiento('unico'));
      await expectLater(
        movimientos.registrarMovimiento(movimiento('unico')),
        throwsA(isA<DatabaseException>()),
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2600);
      expect(await movimientos.obtenerHistorial(), hasLength(9));
    },
  );

  test(
    'borrar datos iniciales no cambia saldo; no se puede revertir un ingreso ya gastado',
    () async {
      await movimientos.eliminarMovimiento('1');
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      await movimientos.registrarMovimiento(movimiento('venta'));
      await caja.guardarCaja(
        const Caja(efectivoTotal: 0, reservaInsumos: 1200),
      );
      await expectLater(
        movimientos.eliminarMovimiento('venta'),
        throwsStateError,
      );
      expect(
        (await movimientos.obtenerHistorial()).any((m) => m.id == 'venta'),
        isTrue,
      );
    },
  );

  test(
    'migración v3 conserva saldo e historial sin aplicar efectos retroactivos',
    () async {
      final db = await base.database;
      await quitarTrazabilidad(db);
      await db.execute('DROP TABLE frecuentes');
      await db.execute('DROP TABLE cierres');
      await db.execute('ALTER TABLE movimientos DROP COLUMN es_retiro');
      await db.execute(
        'ALTER TABLE movimientos DROP COLUMN impacto_caja_centavos',
      );
      await db.setVersion(3);
      await base.cerrar();
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      expect(await (await base.database).getVersion(), 6);
      expect(
        (await movimientos.obtenerHistorial()).every(
          (m) => m.impactoCajaCentavos == 0,
        ),
        isTrue,
      );
      await movimientos.eliminarMovimiento('1');
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
    },
  );
}
