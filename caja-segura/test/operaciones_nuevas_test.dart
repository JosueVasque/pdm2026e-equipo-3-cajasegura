import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caja_segura/data/base_datos/base_datos_local.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/cierre_repositorio.dart';
import 'package:caja_segura/data/repositorios/frecuente_repositorio.dart';
import 'package:caja_segura/data/repositorios/categoria_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/cierre_caja.dart';
import 'package:caja_segura/domain/modelos/movimiento_frecuente.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/casos_uso/resumir_retiros.dart';
import 'package:caja_segura/domain/casos_uso/generar_reporte.dart';
import 'soporte/esquema_anterior.dart';

void main() {
  sqfliteFfiInit();
  late Directory carpeta;
  late BaseDatosLocal base;
  late CajaRepositorio caja;
  late CierreRepositorio cierres;
  late FrecuenteRepositorio frecuentes;
  late MovimientoRepositorio movimientos;
  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('nuevas_operaciones_');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${carpeta.path}/caja.db',
    );
    caja = CajaRepositorio(baseDatos: base);
    cierres = CierreRepositorio(baseDatos: base);
    frecuentes = FrecuenteRepositorio(baseDatos: base);
    movimientos = MovimientoRepositorio(baseDatos: base);
  });
  tearDown(() async {
    await base.cerrar();
    await carpeta.delete(recursive: true);
  });

  MovimientoFrecuente plantilla({
    int? id,
    int? categoria,
    double monto = 50,
    String descripcion = 'Venta rápida',
  }) => MovimientoFrecuente(
    id: id,
    descripcion: descripcion,
    monto: monto,
    tipo: TipoMovimiento.ingreso,
    ambito: AmbitoMovimiento.empresa,
    categoriaId: categoria,
  );

  test(
    'frecuentes persisten y se editan sin afectar caja o movimientos; borrar conserva registros',
    () async {
      await frecuentes.guardar(plantilla());
      final id = (await frecuentes.listar()).single.id!;
      await frecuentes.guardar(
        plantilla(id: id, monto: 75, descripcion: 'Venta de agua'),
      );
      await base.cerrar();
      expect((await frecuentes.listar()).single.id, id);
      expect((await frecuentes.listar()).single.monto, 75);
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      expect(await movimientos.obtenerHistorial(), hasLength(8));
      await movimientos.registrarMovimiento(
        Movimiento(
          id: 'usado',
          descripcion: 'Venta de agua',
          monto: 75,
          tipo: TipoMovimiento.ingreso,
          ambito: AmbitoMovimiento.empresa,
          fecha: DateTime.now(),
        ),
      );
      await frecuentes.eliminar(id);
      expect(await frecuentes.listar(), isEmpty);
      expect(
        (await movimientos.obtenerHistorial()).any((m) => m.id == 'usado'),
        isTrue,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2575);
    },
  );

  test(
    'frecuentes validan importes y categorías y conservan plantilla si se elimina su categoría',
    () async {
      final categorias = CategoriaRepositorio(baseDatos: base);
      final id = await categorias.crear('Ventas');
      await frecuentes.guardar(plantilla(categoria: id));
      await categorias.archivar(id);
      await expectLater(
        frecuentes.guardar(plantilla(categoria: id)),
        throwsStateError,
      );
      await categorias.eliminar(id);
      expect((await frecuentes.listar()).single.categoriaId, isNull);
      for (final monto in [0.0, -1.0, double.nan, double.infinity]) {
        await expectLater(
          frecuentes.guardar(plantilla(monto: monto)),
          throwsArgumentError,
        );
      }
      expect(await frecuentes.listar(), hasLength(1));
    },
  );

  test(
    'cierre sin diferencia conserva reserva y no crea movimientos; se puede seguir operando',
    () async {
      await cierres.confirmar(
        id: 'exacto',
        esperado: 2500,
        contado: 2500,
        nota: '',
      );
      final cierre = (await cierres.listar()).single;
      expect(cierre.diferenciaCentavos, 0);
      expect(cierre.reservaCentavos, 120000);
      expect(await movimientos.obtenerHistorial(), hasLength(8));
      await movimientos.confirmarRetiro(100, 'retiro');
      expect((await caja.obtenerCaja()).efectivoTotal, 2400);
    },
  );

  test(
    'faltante y sobrante quedan auditados, persisten y no aparecen como ingresos o gastos',
    () async {
      await expectLater(
        cierres.confirmar(
          id: 'sin-nota',
          esperado: 2500,
          contado: 2400,
          nota: ' ',
        ),
        throwsArgumentError,
      );
      await cierres.confirmar(
        id: 'faltante',
        esperado: 2500,
        contado: 2400,
        nota: 'Compra no registrada',
      );
      expect((await caja.obtenerCaja()).reservaInsumos, 1200);
      await cierres.confirmar(
        id: 'sobrante',
        esperado: 2400,
        contado: 2450,
        nota: 'Efectivo encontrado',
      );
      await base.cerrar();
      final lista = await cierres.listar();
      expect(lista, hasLength(2));
      expect(
        lista.singleWhere((c) => c.id == 'faltante').diferenciaCentavos,
        -10000,
      );
      expect(
        lista.singleWhere((c) => c.id == 'sobrante').diferenciaCentavos,
        5000,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2450);
      expect(await movimientos.obtenerHistorial(), hasLength(8));
    },
  );

  test(
    'saldo obsoleto, ID duplicado e importes inválidos no dejan cierres parciales',
    () async {
      await cierres.confirmar(
        id: 'unico',
        esperado: 2500,
        contado: 2400,
        nota: 'Faltante',
      );
      await expectLater(
        cierres.confirmar(
          id: 'obsoleto',
          esperado: 2500,
          contado: 2000,
          nota: 'Otro',
        ),
        throwsA(isA<SaldoCambioException>()),
      );
      await expectLater(
        cierres.confirmar(
          id: 'unico',
          esperado: 2400,
          contado: 2000,
          nota: 'Duplicado',
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        cierres.confirmar(
          id: 'negativo',
          esperado: 2400,
          contado: -1,
          nota: 'Inválido',
        ),
        throwsArgumentError,
      );
      expect((await caja.obtenerCaja()).efectivoTotal, 2400);
      expect(await cierres.listar(), hasLength(1));
    },
  );

  test(
    'resumen usa la marca de retiro, respeta fechas y se actualiza al borrar y restaurar',
    () async {
      await movimientos.confirmarRetiro(100, 'retiro-real');
      final hoy = DateTime.now();
      final rango = RangoReporte(hoy, hoy);
      var lista = await movimientos.obtenerHistorial();
      final retiro = lista.singleWhere((m) => m.id == 'retiro-real');
      expect(retiro.esRetiro, isTrue);
      expect(resumirRetiros(lista, rango: rango).totalCentavos, 10000);
      await movimientos.eliminarMovimiento(retiro.id);
      expect(
        resumirRetiros(
          await movimientos.obtenerHistorial(),
          rango: rango,
        ).totalCentavos,
        0,
      );
      await movimientos.restaurarMovimiento(retiro);
      expect(
        resumirRetiros(
          await movimientos.obtenerHistorial(),
          rango: rango,
        ).totalCentavos,
        10000,
      );
      final personal = Movimiento(
        id: 'personal',
        descripcion: 'Retiro de sueldo',
        monto: 100,
        tipo: TipoMovimiento.ingreso,
        ambito: AmbitoMovimiento.personal,
        fecha: hoy,
      );
      expect(
        resumirRetiros([retiro, personal], rango: rango).totalCentavos,
        10000,
      );
      expect(resumirRetiros([personal], rango: rango).retiros, isEmpty);
    },
  );

  test(
    'migra v4 a v5 sin alterar saldo y reconoce solo salidas de sueldo anteriores',
    () async {
      final db = await base.database;
      await quitarTrazabilidad(db);
      await db.execute('DROP TABLE frecuentes');
      await db.execute('DROP TABLE cierres');
      await db.execute('ALTER TABLE movimientos DROP COLUMN es_retiro');
      await db.setVersion(4);
      await base.cerrar();
      expect((await caja.obtenerCaja()).efectivoTotal, 2500);
      expect(await (await base.database).getVersion(), 6);
      expect(await frecuentes.listar(), isEmpty);
      expect(await cierres.listar(), isEmpty);
      final lista = await movimientos.obtenerHistorial();
      expect(lista, hasLength(8));
      expect(lista.where((m) => m.esRetiro).map((m) => m.id), ['8']);
      expect(resumirRetiros(lista).totalCentavos, 60000);
    },
  );
}
