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

  @override
  Future<List<Movimiento>> obtenerHistorial() => cargar();
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

    expect(find.text('Venta'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.pumpAndSettle();
    expect(find.text('Venta'), findsNothing);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Q0.00'), findsOneWidget);
    expect(find.text('Q20.00'), findsOneWidget);
    await tester.tap(find.text('Ingresos').last);
    await tester.pumpAndSettle();
    expect(find.text('No hay movimientos para mostrar'), findsOneWidget);
  });
}
