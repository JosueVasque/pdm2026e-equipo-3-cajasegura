import 'dart:async';
import 'package:caja_segura/main.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';

import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/presentation/pantallas/caja_negocio_screen.dart';
import 'package:caja_segura/presentation/providers/caja_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CajaPrueba extends CajaRepositorio {
  Future<Caja> Function() cargar = () async =>
      const Caja(efectivoTotal: 2500, reservaInsumos: 1200);

  @override
  Future<Caja> obtenerCaja() => cargar();
}

/// Pantalla de la caja con el repositorio sobrescrito y sin reintento
/// automático de Riverpod 3 (igual que en main.dart).
Widget _cajaCon(CajaRepositorio repositorio) => ProviderScope(
  retry: (_, _) => null,
  overrides: [cajaRepositorioProvider.overrideWithValue(repositorio)],
  child: const MaterialApp(home: CajaNegocioScreen()),
);

void main() {
  testWidgets('barra y Ver historial cambian de pestaña', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          cajaRepositorioProvider.overrideWithValue(_CajaPrueba()),
          historialProvider.overrideWith((ref) async => []),
        ],
        child: const MiApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver historial'));
    await tester.tap(find.text('Ver historial'));
    await tester.pumpAndSettle();
    expect(find.text('Ir a mi caja'), findsOneWidget);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Caja disponible'), findsOneWidget);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes: Próximamente'), findsOneWidget);
    await tester.tap(find.text('Historial').last);
    await tester.pumpAndSettle();
    expect(find.text('Ir a mi caja'), findsOneWidget);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Caja disponible'), findsOneWidget);
  });

  testWidgets('carga caja y verifica el retiro con los datos obtenidos', (
    tester,
  ) async {
    await tester.pumpWidget(_cajaCon(_CajaPrueba()));
    await tester.pumpAndSettle();
    expect(find.text('Q2500.00'), findsOneWidget);
    expect(find.text('Q1200.00'), findsOneWidget);
    expect(find.text('Q1300.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Retirar mi sueldo'));
    await tester.tap(find.text('Retirar mi sueldo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500');
    await tester.tap(find.text('Verificar si es seguro'));
    await tester.pumpAndSettle();
    expect(find.text('Retiro seguro'), findsOneWidget);
    expect(find.text('Q2000.00'), findsOneWidget);
  });

  testWidgets('estado de carga y de error con Reintentar', (tester) async {
    final pendiente = Completer<Caja>();
    final repositorio = _CajaPrueba()..cargar = () => pendiente.future;
    await tester.pumpWidget(_cajaCon(repositorio));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendiente.completeError(StateError('No se pudo abrir SQLite'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la caja.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    // El botón debe volver a pedir los datos, no solo existir.
    repositorio.cargar = () async =>
        const Caja(efectivoTotal: 100, reservaInsumos: 50);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la caja.'), findsNothing);
    expect(find.text('Q100.00'), findsOneWidget);
  });

  testWidgets('estado vacío cuando la caja no tiene efectivo', (tester) async {
    const vacia = Caja(efectivoTotal: 0, reservaInsumos: 0);
    final repositorio = _CajaPrueba()..cargar = () async => vacia;
    await tester.pumpWidget(_cajaCon(repositorio));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no hay efectivo registrado en la caja.'),
      findsOneWidget,
    );
    expect(find.text('Ver historial'), findsOneWidget);
  });
}
