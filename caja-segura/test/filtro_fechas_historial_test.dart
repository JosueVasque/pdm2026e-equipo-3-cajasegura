import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/domain/casos_uso/generar_reporte.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';
import 'package:caja_segura/presentation/pantallas/historial_screen.dart';
import 'package:caja_segura/presentation/tema/caja_estilo.dart';

final _ahora = DateTime(2026, 11, 3, 14);
Movimiento _mov(
  String id,
  DateTime fecha,
  double monto, {
  bool ingreso = false,
  bool personal = false,
}) => Movimiento(
  id: id,
  descripcion: id,
  monto: monto,
  fecha: fecha,
  tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
  ambito: personal ? AmbitoMovimiento.personal : AmbitoMovimiento.empresa,
);
final _lista = [
  _mov('Anterior', DateTime(2026, 10, 31, 23, 59), 90),
  _mov('Venta de hoy', DateTime(2026, 11, 3), 50.10, ingreso: true),
  _mov(
    'Personal de hoy',
    DateTime(2026, 11, 3, 23, 59, 59, 999, 999),
    20,
    personal: true,
  ),
  _mov('Gasto del lunes', DateTime(2026, 11, 2), 60),
  _mov('Día siguiente', DateTime(2026, 11, 4), 15),
];

void main() {
  test(
    'fechas se combinan con tipo y ámbito sin consultas adicionales y limpiar restablece todo',
    () async {
      var consultas = 0;
      final container = ProviderContainer(
        overrides: [
          relojHistorialProvider.overrideWithValue(() => _ahora),
          historialProvider.overrideWith((ref) async {
            consultas++;
            return _lista;
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        historialFiltradoProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(historialProvider.future);
      final acciones = container.read(filtroHistorialProvider.notifier);
      List<String> ids() => container
          .read(historialFiltradoProvider)
          .requireValue
          .map((m) => m.id)
          .toList();
      expect(
        container.read(filtroHistorialProvider).periodo,
        PeriodoReporte.todo,
      );
      expect(ids(), hasLength(5));
      acciones.seleccionarPeriodo(PeriodoReporte.hoy);
      expect(ids(), ['Venta de hoy', 'Personal de hoy']);
      acciones.seleccionarPeriodo(PeriodoReporte.semana);
      expect(ids(), ['Venta de hoy', 'Personal de hoy', 'Gasto del lunes']);
      acciones.seleccionarPeriodo(PeriodoReporte.mes);
      expect(ids(), hasLength(3));
      acciones.cambiar(
        FiltroHistorial(
          tipo: TipoMovimiento.gasto,
          ambito: AmbitoMovimiento.empresa,
          periodo: PeriodoReporte.personalizado,
          personalizado: RangoReporte(
            DateTime(2026, 11, 2),
            DateTime(2026, 11, 3),
          ),
        ),
      );
      expect(ids(), ['Gasto del lunes']);
      acciones.seleccionarPeriodo(PeriodoReporte.hoy);
      expect(ids(), isEmpty);
      expect(
        container.read(filtroHistorialProvider).ambito,
        AmbitoMovimiento.empresa,
      );
      acciones.limpiar();
      expect(ids(), hasLength(5));
      expect(container.read(filtroHistorialProvider).activo, isFalse);
      expect(consultas, 1);
    },
  );

  Future<ProviderContainer> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relojHistorialProvider.overrideWithValue(() => _ahora),
          historialProvider.overrideWith((ref) async => _lista),
          categoriasProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: CajaEstilo.tema,
          home: const HistorialScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(HistorialScreen)),
    );
  }

  Future<void> periodo(WidgetTester tester, String opcion) async {
    final selector = find.byKey(const ValueKey('periodo-historial'));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'fecha conserva controles, totales y período al cambiar ámbito; limpiar recupera datos',
    (tester) async {
      final container = await abrir(tester);
      await periodo(tester, 'Hoy');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('03/11/2026 – 03/11/2026 · Fechas incluidas'),
        findsOneWidget,
      );
      expect(find.text('Q50.10'), findsOneWidget);
      expect(find.text('Q20.00'), findsOneWidget);
      final personal = find.widgetWithText(ChoiceChip, 'Personal');
      await tester.ensureVisible(personal);
      await tester.pumpAndSettle();
      await tester.tap(personal);
      await tester.pumpAndSettle();
      expect(
        container.read(filtroHistorialProvider).periodo,
        PeriodoReporte.hoy,
      );
      expect(find.text('Q0.00'), findsOneWidget);
      await tester.ensureVisible(find.text('Ingresos').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresos').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('periodo-historial')), findsOneWidget);
      expect(container.read(historialFiltradoProvider).requireValue, isEmpty);
      await tester.ensureVisible(find.byTooltip('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(
        container.read(historialFiltradoProvider).requireValue,
        hasLength(5),
      );
      expect(container.read(filtroHistorialProvider).activo, isFalse);
    },
  );

  testWidgets(
    'cancelar fechas conserva el período; un rango sin resultados mantiene los filtros',
    (tester) async {
      final container = await abrir(tester);
      await periodo(tester, 'Hoy');
      await periodo(tester, 'Elegir fechas');
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      // Cerrar el selector sin aplicar no modifica la selección anterior.
      Navigator.of(tester.element(find.byType(DateRangePickerDialog))).pop();
      await tester.pumpAndSettle();
      expect(
        container.read(filtroHistorialProvider).periodo,
        PeriodoReporte.hoy,
      );
      container
          .read(filtroHistorialProvider.notifier)
          .seleccionarPeriodo(
            PeriodoReporte.personalizado,
            rango: RangoReporte(DateTime(2026, 10, 1), DateTime(2026, 10, 2)),
          );
      await tester.pumpAndSettle();
      expect(
        find.text('01/10/2026 – 02/10/2026 · Fechas incluidas'),
        findsOneWidget,
      );
      expect(find.byTooltip('Limpiar filtros'), findsOneWidget);
      expect(
        find.text('Todavía no hay movimientos registrados.'),
        findsNothing,
      );
      expect(container.read(historialFiltradoProvider).requireValue, isEmpty);
    },
  );
}
