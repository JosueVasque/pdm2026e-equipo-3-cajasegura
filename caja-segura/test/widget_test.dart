import 'dart:async';

import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/presentation/pantallas/caja_negocio_screen.dart';
import 'package:caja_segura/presentation/pantallas/historial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CajaPrueba extends CajaRepositorio {
  Future<Caja> Function() cargar = () async =>
      const Caja(efectivoTotal: 2500, reservaInsumos: 1200);

  @override
  Future<Caja> obtenerCaja() => cargar();
}

class _MovimientosPrueba extends MovimientoRepositorio {
  @override
  Future<List<Movimiento>> obtenerHistorial() async => [
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
}

void main() {
  testWidgets('carga caja y verifica el retiro con los datos obtenidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CajaNegocioScreen(repositorio: _CajaPrueba())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Q2500.00'), findsOneWidget);
    expect(find.text('Q1200.00'), findsOneWidget);
    expect(find.text('Q1300.00'), findsOneWidget);
    await tester.tap(find.text('Retirar mi sueldo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500');
    await tester.tap(find.text('Verificar si es seguro'));
    await tester.pumpAndSettle();
    expect(find.text('Retiro seguro'), findsOneWidget);
    expect(find.text('Q2000.00'), findsOneWidget);
  });

  testWidgets('muestra carga y permite reintentar una lectura fallida', (
    tester,
  ) async {
    final pendiente = Completer<Caja>();
    final repositorio = _CajaPrueba()..cargar = () => pendiente.future;
    await tester.pumpWidget(
      MaterialApp(home: CajaNegocioScreen(repositorio: repositorio)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.completeError(StateError('No se pudo abrir SQLite'));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar los datos guardados.'),
      findsOneWidget,
    );
    repositorio.cargar = () async =>
        const Caja(efectivoTotal: 100, reservaInsumos: 50);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Q100.00'), findsOneWidget);
  });

  testWidgets('historial conserva los filtros después de la carga asíncrona', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HistorialScreen(repositorio: _MovimientosPrueba())),
    );
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
