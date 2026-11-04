import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/domain/casos_uso/generar_reporte.dart';
import 'package:caja_segura/domain/modelos/categoria.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/presentation/pantallas/reportes_screen.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';
import 'package:caja_segura/presentation/providers/reportes_provider.dart';
import 'package:caja_segura/presentation/tema/caja_estilo.dart';
import 'package:caja_segura/presentation/widgets/alerta_reserva.dart';

final _fecha = DateTime(2026, 11, 3);
final _movimientos = [
  Movimiento(
    id: '1',
    descripcion: 'Filtros',
    monto: 80,
    tipo: TipoMovimiento.gasto,
    ambito: AmbitoMovimiento.empresa,
    fecha: DateTime(2026, 10, 31),
    categoriaId: 1,
  ),
];
const _categorias = [Categoria(id: 1, nombre: 'Insumos', archivada: true)];

void main() {
  test(
    'filtros de reportes son independientes del historial y recargan después de escrituras',
    () async {
      var consultas = 0;
      var lista = _movimientos;
      final container = ProviderContainer(
        overrides: [
          historialProvider.overrideWith((ref) async {
            consultas++;
            return lista;
          }),
          categoriasProvider.overrideWith((ref) async => _categorias),
          relojReportesProvider.overrideWithValue(() => _fecha),
        ],
      );
      addTearDown(container.dispose);
      final suscripcion = container.listen(reporteProvider, (_, _) {});
      addTearDown(suscripcion.close);
      await container.read(historialProvider.future);
      await container.read(categoriasProvider.future);
      expect(container.read(reporteProvider).requireValue.movimientos, isEmpty);
      container
          .read(filtroReporteProvider.notifier)
          .periodo(PeriodoReporte.todo);
      expect(container.read(reporteProvider).requireValue.gastosCentavos, 8000);
      container
          .read(filtroHistorialProvider.notifier)
          .cambiar(const FiltroHistorial(tipo: TipoMovimiento.ingreso));
      expect(container.read(reporteProvider).requireValue.gastosCentavos, 8000);
      expect(consultas, 1);
      lista = [];
      container.invalidate(historialProvider);
      await container.read(historialProvider.future);
      expect(container.read(reporteProvider).requireValue.movimientos, isEmpty);
      expect(consultas, 2);
    },
  );

  testWidgets(
    'reportes permiten cambiar período sin recargar y muestran categorías archivadas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var consultas = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historialProvider.overrideWith((ref) async {
              consultas++;
              return _movimientos;
            }),
            categoriasProvider.overrideWith((ref) async => _categorias),
            relojReportesProvider.overrideWithValue(() => _fecha),
          ],
          child: MaterialApp(
            theme: CajaEstilo.tema,
            home: const ReportesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final periodo = find.byKey(const ValueKey('periodo-reporte'));
      await tester.tap(periodo);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todo el historial').last);
      await tester.pumpAndSettle();
      expect(consultas, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Insumos (archivada)'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Insumos (archivada)'), findsOneWidget);
      expect(find.text('100.0% de los gastos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('error de reportes permite reintentar', (tester) async {
    var falla = true;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          historialProvider.overrideWith((ref) async {
            if (falla) throw StateError('SQLite');
            return <Movimiento>[];
          }),
          categoriasProvider.overrideWith((ref) async => _categorias),
        ],
        child: MaterialApp(
          theme: CajaEstilo.tema,
          home: const ReportesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reintentar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    falla = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No hay movimientos en este período'), findsOneWidget);
  });

  testWidgets(
    'alerta muestra faltante incluso con caja vacía y desaparece al reponer',
    (tester) async {
      Future<void> mostrar(double saldo) => tester.pumpWidget(
        MaterialApp(
          theme: CajaEstilo.tema,
          home: Scaffold(
            body: AlertaReserva(
              caja: Caja(efectivoTotal: saldo, reservaInsumos: 1200),
            ),
          ),
        ),
      );
      await mostrar(0);
      expect(find.text('Reserva sin cubrir'), findsOneWidget);
      expect(find.textContaining('Q1200.00'), findsOneWidget);
      await mostrar(1200);
      expect(find.text('Sin margen para retiros'), findsOneWidget);
      await mostrar(1300);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    },
  );
}
