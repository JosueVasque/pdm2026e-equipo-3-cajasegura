import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/cierre_repositorio.dart';
import 'package:caja_segura/data/repositorios/frecuente_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/cierre_caja.dart';
import 'package:caja_segura/domain/modelos/movimiento_frecuente.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/presentation/pantallas/frecuentes_screen.dart';
import 'package:caja_segura/presentation/pantallas/cierres_screen.dart';
import 'package:caja_segura/presentation/pantallas/reportes_screen.dart';
import 'package:caja_segura/presentation/providers/caja_provider.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';
import 'package:caja_segura/presentation/providers/operaciones_provider.dart';
import 'package:caja_segura/presentation/providers/reportes_provider.dart';
import 'package:caja_segura/presentation/tema/caja_estilo.dart';

class _Caja extends CajaRepositorio {
  Caja valor = const Caja(efectivoTotal: 2500, reservaInsumos: 1200);
  @override
  Future<Caja> obtenerCaja() async => valor;
}

class _Frecuentes extends FrecuenteRepositorio {
  final lista = <MovimientoFrecuente>[];
  @override
  Future<List<MovimientoFrecuente>> listar() async => List.of(lista);
  @override
  Future<void> guardar(MovimientoFrecuente f) async {
    lista.add(
      MovimientoFrecuente(
        id: 1,
        descripcion: f.descripcion,
        monto: f.monto,
        tipo: f.tipo,
        ambito: f.ambito,
        categoriaId: f.categoriaId,
      ),
    );
  }
}

class _Movimientos extends MovimientoRepositorio {
  final lista = <Movimiento>[];
  @override
  Future<List<Movimiento>> obtenerHistorial() async => List.of(lista);
  @override
  Future<void> registrarMovimientoConReserva(
    Movimiento m, {
    bool autorizarReserva = false,
  }) async {
    lista.add(m);
  }
}

class _Cierres extends CierreRepositorio {
  _Cierres(this.caja);
  final _Caja caja;
  final lista = <CierreCaja>[];
  @override
  Future<List<CierreCaja>> listar() async => List.of(lista);
  @override
  Future<void> confirmar({
    required String id,
    required double esperado,
    required double contado,
    required String nota,
  }) async {
    lista.add(
      CierreCaja(
        id: id,
        fecha: DateTime.now(),
        esperadoCentavos: (esperado * 100).round(),
        contadoCentavos: (contado * 100).round(),
        reservaCentavos: 120000,
        nota: nota,
      ),
    );
    caja.valor = Caja(
      efectivoTotal: contado,
      reservaInsumos: caja.valor.reservaInsumos,
    );
  }
}

void main() {
  late _Caja caja;
  late _Frecuentes frecuentes;
  late _Movimientos movimientos;
  late _Cierres cierres;
  setUp(() {
    caja = _Caja();
    frecuentes = _Frecuentes();
    movimientos = _Movimientos();
    cierres = _Cierres(caja);
  });
  Future<void> abrir(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          cajaRepositorioProvider.overrideWithValue(caja),
          frecuenteRepositorioProvider.overrideWithValue(frecuentes),
          cierreRepositorioProvider.overrideWithValue(cierres),
          movimientoRepositorioProvider.overrideWithValue(movimientos),
          categoriasProvider.overrideWith((ref) async => []),
          relojReportesProvider.overrideWithValue(() => DateTime(2026, 11, 3)),
        ],
        child: MaterialApp(theme: CajaEstilo.tema, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    final finder = find.text(texto);
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'crear frecuente no registra dinero; usarlo precarga datos y permite modificar el monto',
    (tester) async {
      await abrir(tester, const FrecuentesScreen());
      await tester.tap(find.text('Nuevo frecuente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Venta rápida');
      await tester.enterText(find.byType(TextFormField).at(1), '50');
      await tocar(tester, 'Guardar frecuente');
      expect(frecuentes.lista, hasLength(1));
      expect(movimientos.lista, isEmpty);
      await tester.tap(find.text('Venta rápida'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text,
        'Venta rápida',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '50.00',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '75');
      await tocar(tester, 'Guardar movimiento');
      expect(movimientos.lista.single.monto, 75);
      expect(frecuentes.lista.single.monto, 50);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cierre requiere explicación, permite cancelar y registra el ajuste al confirmar',
    (tester) async {
      await abrir(tester, const CierresScreen());
      await tester.tap(find.text('Cerrar caja'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2400');
      await tester.pumpAndSettle();
      await tocar(tester, 'Revisar cierre');
      expect(cierres.lista, isEmpty);
      expect(find.text('Confirmar cierre'), findsNothing);
      final nota = find.widgetWithText(
        TextFormField,
        'Explicación de la diferencia',
      );
      await tester.scrollUntilVisible(
        nota,
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(nota, 'Compra no registrada');
      await tocar(tester, 'Revisar cierre');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(caja.valor.efectivoTotal, 2500);
      expect(cierres.lista, isEmpty);
      await tocar(tester, 'Revisar cierre');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar cierre'));
      await tester.pumpAndSettle();
      expect(caja.valor.efectivoTotal, 2400);
      expect(caja.valor.reservaInsumos, 1200);
      expect(cierres.lista.single.nota, 'Compra no registrada');
      expect(find.text('Compra no registrada'), findsOneWidget);
      expect(movimientos.lista, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resumen de retiros separa sueldo de ingresos personales y gastos normales',
    (tester) async {
      movimientos.lista.addAll([
        Movimiento(
          id: 'retiro',
          descripcion: 'Retiro de sueldo',
          monto: 100,
          tipo: TipoMovimiento.gasto,
          ambito: AmbitoMovimiento.empresa,
          fecha: DateTime(2026, 11, 2),
          esRetiro: true,
        ),
        Movimiento(
          id: 'personal',
          descripcion: 'Sueldo recibido',
          monto: 100,
          tipo: TipoMovimiento.ingreso,
          ambito: AmbitoMovimiento.personal,
          fecha: DateTime(2026, 11, 2),
        ),
        Movimiento(
          id: 'gasto',
          descripcion: 'Compra',
          monto: 50,
          tipo: TipoMovimiento.gasto,
          ambito: AmbitoMovimiento.empresa,
          fecha: DateTime(2026, 11, 2),
        ),
      ]);
      await abrir(tester, const ReportesScreen());
      await tester.tap(find.text('Retiros de sueldo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ambito-reporte')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Total retirado como sueldo'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Q100.00'), findsOneWidget);
      expect(find.text('1 retiro en el período'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
