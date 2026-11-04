import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/data/repositorios/trazabilidad_repositorio.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/modelos/trazabilidad.dart';
import 'package:caja_segura/presentation/pantallas/historial_screen.dart';
import 'package:caja_segura/presentation/pantallas/corregir_movimiento_screen.dart';
import 'package:caja_segura/presentation/pantallas/trazabilidad_screen.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';
import 'package:caja_segura/presentation/providers/trazabilidad_provider.dart';
import 'package:caja_segura/presentation/tema/caja_estilo.dart';

Movimiento _mov({bool cerrado = false}) => Movimiento(
  id: 'venta',
  descripcion: 'Venta de agua',
  monto: 100,
  tipo: TipoMovimiento.ingreso,
  ambito: AmbitoMovimiento.empresa,
  fecha: DateTime(2026, 11, 3),
  impactoCajaCentavos: 10000,
  conciliado: cerrado,
);

class _Movimientos extends MovimientoRepositorio {
  _Movimientos(this.valor);
  Movimiento valor;
  int borrados = 0;
  int correcciones = 0;
  String? motivo;
  @override
  Future<List<Movimiento>> obtenerHistorial() async => [valor];
  @override
  Future<void> eliminarMovimiento(String id) async {
    borrados++;
  }

  @override
  Future<void> actualizarMovimiento(
    Movimiento original,
    Movimiento nuevo,
    String motivo, {
    bool autorizarReserva = false,
  }) async {
    if (valor.conciliado) throw const MovimientoConciliadoException();
    correcciones++;
    valor = nuevo;
    this.motivo = motivo;
  }
}

class _Trazabilidad extends TrazabilidadRepositorio {
  final lista = <AjusteMovimiento>[];
  @override
  Future<List<AjusteMovimiento>> ajustes({String? movimientoId}) async =>
      List.of(lista);
  @override
  Future<void> ajustar({
    required String id,
    required String movimientoId,
    required int deltaCentavos,
    required String motivo,
    bool autorizarReserva = false,
  }) async {
    lista.add(
      AjusteMovimiento(
        id: id,
        movimientoId: movimientoId,
        fecha: DateTime.now(),
        deltaCentavos: deltaCentavos,
        motivo: motivo,
      ),
    );
  }

  @override
  Future<List<CambioMovimiento>> cambios({String? movimientoId}) async => [
    CambioMovimiento(
      fecha: DateTime(2026, 11, 3),
      accion: 'correccion',
      motivo: 'Monto digitado incorrectamente',
      movimientoId: 'venta',
      antes: {'descripcion': 'Venta', 'monto_centavos': 10000},
      despues: {'descripcion': 'Venta corregida', 'monto_centavos': 15000},
    ),
  ];
}

void main() {
  late _Movimientos movimientos;
  late _Trazabilidad trazabilidad;
  setUp(() {
    movimientos = _Movimientos(_mov());
    trazabilidad = _Trazabilidad();
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
          movimientoRepositorioProvider.overrideWithValue(movimientos),
          trazabilidadRepositorioProvider.overrideWithValue(trazabilidad),
          categoriasProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(theme: CajaEstilo.tema, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ver(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'movimiento conciliado no se desliza para borrar y admite solo ajuste con motivo',
    (tester) async {
      movimientos.valor = _mov(cerrado: true);
      await abrir(tester, const HistorialScreen());
      await ver(tester, find.byKey(const ValueKey('venta')));
      expect(
        tester
            .widget<Dismissible>(find.byKey(const ValueKey('venta')))
            .direction,
        DismissDirection.none,
      );
      await tester.drag(
        find.byKey(const ValueKey('venta')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(movimientos.borrados, 0);
      await tester.tap(find.text('Venta de agua'));
      await tester.pumpAndSettle();
      expect(find.text('Movimiento conciliado'), findsOneWidget);
      expect(find.text('Corregir monto y datos'), findsNothing);
      await tester.tap(find.text('Registrar ajuste'));
      await tester.pumpAndSettle();
      await ver(tester, find.widgetWithText(FilledButton, 'Registrar ajuste'));
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar ajuste'));
      await tester.pumpAndSettle();
      expect(trazabilidad.lista, isEmpty);
      final nota = find.byType(TextFormField);
      await tester.ensureVisible(nota);
      await tester.enterText(
        nota,
        'La descripción correcta era venta de filtros',
      );
      await ver(tester, find.widgetWithText(FilledButton, 'Registrar ajuste'));
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar ajuste'));
      await tester.pumpAndSettle();
      expect(trazabilidad.lista.single.deltaCentavos, 0);
      expect(movimientos.valor.descripcion, 'Venta de agua');
      expect(movimientos.valor.monto, 100);
    },
  );

  testWidgets('corrección de monto exige motivo antes de guardar', (
    tester,
  ) async {
    await abrir(
      tester,
      CorregirMovimientoScreen(movimiento: movimientos.valor),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto corregido'),
      '150',
    );
    await ver(tester, find.text('Guardar corrección'));
    await tester.tap(find.text('Guardar corrección'));
    await tester.pumpAndSettle();
    expect(movimientos.correcciones, 0);
    final motivo = find.widgetWithText(
      TextFormField,
      'Motivo de la corrección',
    );
    await tester.ensureVisible(motivo);
    await tester.enterText(motivo, 'Monto digitado incorrectamente');
    await ver(tester, find.text('Guardar corrección'));
    await tester.tap(find.text('Guardar corrección'));
    await tester.pumpAndSettle();
    expect(movimientos.correcciones, 1);
    expect(movimientos.valor.monto, 150);
    expect(movimientos.motivo, 'Monto digitado incorrectamente');
  });

  testWidgets('si se cierra mientras se corrige, el guardado es rechazado', (
    tester,
  ) async {
    final original = movimientos.valor;
    await abrir(tester, CorregirMovimientoScreen(movimiento: original));
    movimientos.valor = _mov(cerrado: true);
    final motivo = find.widgetWithText(
      TextFormField,
      'Motivo de la corrección',
    );
    await ver(tester, motivo);
    await tester.enterText(motivo, 'Corrección tardía');
    await ver(tester, find.text('Guardar corrección'));
    await tester.tap(find.text('Guardar corrección'));
    await tester.pumpAndSettle();
    expect(movimientos.correcciones, 0);
    expect(find.textContaining('incluido en un cierre'), findsWidgets);
  });

  testWidgets('trazabilidad muestra motivo y valores anteriores y nuevos', (
    tester,
  ) async {
    await abrir(tester, const TrazabilidadScreen(movimientoId: 'venta'));
    expect(find.text('Monto digitado incorrectamente'), findsOneWidget);
    expect(find.text('Antes'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);
    expect(find.text('Monto: Q100.00'), findsOneWidget);
    expect(find.text('Monto: Q150.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
