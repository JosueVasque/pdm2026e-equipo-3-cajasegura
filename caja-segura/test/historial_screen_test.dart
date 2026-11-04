import 'dart:async';

import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/presentation/pantallas/historial_screen.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso: devuelve lo que indique [cargar] (datos o un error).
class _MovimientosPrueba extends MovimientoRepositorio {
  _MovimientosPrueba(this.cargar);

  Future<List<Movimiento>> Function() cargar;
  int consultas = 0;

  @override
  Future<List<Movimiento>> obtenerHistorial() {
    consultas++;
    return cargar();
  }

  @override
  Future<void> eliminarMovimiento(String id) async {
    final lista = await cargar();
    cargar = () async => lista.where((m) => m.id != id).toList();
  }

  @override
  Future<void> registrarMovimiento(Movimiento movimiento) async {
    final lista = await cargar();
    cargar = () async => [...lista, movimiento];
  }

  @override
  Future<void> restaurarMovimiento(Movimiento movimiento) =>
      registrarMovimiento(movimiento);
}

final _movimientos = [
  Movimiento(
    id: '1',
    descripcion: 'Venta',
    monto: 50,
    tipo: TipoMovimiento.ingreso,
    ambito: AmbitoMovimiento.empresa,
    fecha: DateTime(2026, 10, 15),
  ),
  Movimiento(
    id: '2',
    descripcion: 'Mercado',
    monto: 20,
    tipo: TipoMovimiento.gasto,
    ambito: AmbitoMovimiento.personal,
    fecha: DateTime(2026, 10, 14),
  ),
];

Future<List<Movimiento>> _falla() async => throw StateError('Sin SQLite');

/// Pantalla de historial con el repositorio sobrescrito y sin reintento
/// automático de Riverpod 3 (igual que en main.dart).
Widget _historialCon(MovimientoRepositorio repositorio) => ProviderScope(
  retry: (_, _) => null,
  overrides: [movimientoRepositorioProvider.overrideWithValue(repositorio)],
  child: const MaterialApp(home: HistorialScreen()),
);

Future<void> _ver(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('estado de error con Reintentar', (tester) async {
    final repositorio = _MovimientosPrueba(_falla);
    await tester.pumpWidget(_historialCon(repositorio));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el historial.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    // El botón debe volver a pedir los datos, no solo existir.
    repositorio.cargar = () async => _movimientos;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el historial.'), findsNothing);
    expect(find.text('Venta'), findsOneWidget);
  });

  testWidgets('estado de carga mientras llegan los datos', (tester) async {
    final pendiente = Completer<List<Movimiento>>();
    final repositorio = _MovimientosPrueba(() => pendiente.future);
    await tester.pumpWidget(_historialCon(repositorio));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendiente.complete(_movimientos);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Venta'), findsOneWidget);
  });

  testWidgets('estado vacío sin movimientos', (tester) async {
    final repositorio = _MovimientosPrueba(() async => []);
    await tester.pumpWidget(_historialCon(repositorio));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no hay movimientos registrados.'),
      findsOneWidget,
    );
    expect(find.text('Ir a mi caja'), findsOneWidget);
  });

  testWidgets('filtros del historial con datos', (tester) async {
    final repositorio = _MovimientosPrueba(() async => _movimientos);
    await tester.pumpWidget(_historialCon(repositorio));
    await tester.pumpAndSettle();

    await _ver(tester, find.text('Mercado'));
    expect(find.text('Venta'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    await _ver(tester, find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.pumpAndSettle();
    expect(find.text('Venta'), findsNothing);
    await _ver(tester, find.text('Mercado'));
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Q0.00'), findsOneWidget);
    expect(find.text('Q20.00'), findsOneWidget);
    await _ver(tester, find.text('Ingresos').last);
    await tester.tap(find.text('Ingresos').last);
    await tester.pumpAndSettle();
    expect(find.text('No hay movimientos para mostrar'), findsOneWidget);
  });

  testWidgets('cambiar filtros conserva los controles y no recarga SQLite', (
    tester,
  ) async {
    final repositorio = _MovimientosPrueba(() async => _movimientos);
    await tester.pumpWidget(_historialCon(repositorio));
    await tester.pumpAndSettle();
    final personal = find.widgetWithText(ChoiceChip, 'Personal');
    final controlOriginal = tester.element(personal);

    // Si el filtro intentara consultar de nuevo, quedaría cargando indefinidamente.
    final pendiente = Completer<List<Movimiento>>();
    repositorio.cargar = () => pendiente.future;
    await tester.tap(personal);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.element(personal), same(controlOriginal));
    await _ver(tester, find.text('Mercado'));
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Venta'), findsNothing);
    expect(find.text('Q20.00'), findsOneWidget);
    expect(repositorio.consultas, 1);

    await _ver(tester, find.text('Ingresos').last);
    await tester.tap(find.text('Ingresos').last);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No hay movimientos para mostrar'), findsOneWidget);
    expect(repositorio.consultas, 1);

    await tester.tap(find.text('Todos').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todo'));
    await tester.pumpAndSettle();
    await _ver(tester, find.text('Mercado'));
    expect(find.text('Venta'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(repositorio.consultas, 1);
    pendiente.complete(_movimientos);
  });
  testWidgets('borrar y deshacer conserva el movimiento completo', (
    tester,
  ) async {
    final repositorio = _MovimientosPrueba(() async => List.of(_movimientos));
    await tester.pumpWidget(_historialCon(repositorio));
    await tester.pumpAndSettle();
    await _ver(tester, find.byKey(const ValueKey('1')));
    await tester.drag(find.byKey(const ValueKey('1')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Venta'), findsNothing);
    expect((await repositorio.obtenerHistorial()).map((m) => m.id), ['2']);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    await _ver(tester, find.text('Venta'));
    expect(find.text('Venta'), findsOneWidget);
    final restaurado = (await repositorio.obtenerHistorial()).last;
    expect(identical(restaurado, _movimientos.first), isTrue);
  });

  testWidgets('si SQLite falla la fila permanece', (tester) async {
    await tester.pumpWidget(
      _historialCon(_FallaBorrado(() async => _movimientos)),
    );
    await tester.pumpAndSettle();
    await _ver(tester, find.byKey(const ValueKey('1')));
    await tester.drag(find.byKey(const ValueKey('1')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Venta'), findsOneWidget);
    expect(find.text('No se pudo borrar el movimiento.'), findsOneWidget);
  });
}

class _FallaBorrado extends _MovimientosPrueba {
  _FallaBorrado(super.cargar);
  @override
  Future<void> eliminarMovimiento(String id) async =>
      throw StateError('SQLite');
}
