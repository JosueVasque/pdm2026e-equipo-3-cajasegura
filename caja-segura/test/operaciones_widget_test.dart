import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/main.dart';
import 'package:caja_segura/data/repositorios/caja_repositorio.dart';
import 'package:caja_segura/data/repositorios/movimiento_repositorio.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/categoria.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';
import 'package:caja_segura/domain/casos_uso/evaluar_reserva.dart';
import 'package:caja_segura/presentation/providers/caja_provider.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';
import 'package:caja_segura/presentation/providers/historial_provider.dart';

class _Caja extends CajaRepositorio {
  Caja valor = const Caja(efectivoTotal: 2500, reservaInsumos: 1200);
  @override
  Future<Caja> obtenerCaja() async => valor;
  @override
  Future<void> guardarCaja(Caja caja) async {
    valor = caja;
  }

  @override
  Future<void> guardarCajaConMotivo(Caja caja, String motivo) =>
      guardarCaja(caja);
}

class _Movimientos extends MovimientoRepositorio {
  _Movimientos(this.caja);
  final _Caja caja;
  final lista = <Movimiento>[];
  int confirmaciones = 0;
  bool advertirReserva = false;
  Completer<void>? pendiente;
  @override
  Future<List<Movimiento>> obtenerHistorial() async => List.of(lista);
  @override
  Future<void> registrarMovimiento(Movimiento movimiento) async {
    lista.add(movimiento);
  }

  @override
  Future<void> registrarMovimientoConReserva(
    Movimiento movimiento, {
    bool autorizarReserva = false,
  }) async {
    if (advertirReserva && !autorizarReserva) {
      throw const ReservaRequiereConfirmacion(10000);
    }
    await registrarMovimiento(movimiento);
  }

  @override
  Future<void> asignarCategoria(String id, int? categoriaId) async {
    final index = lista.indexWhere((m) => m.id == id);
    final m = lista[index];
    lista[index] = Movimiento(
      id: m.id,
      descripcion: m.descripcion,
      monto: m.monto,
      tipo: m.tipo,
      ambito: m.ambito,
      fecha: m.fecha,
      categoriaId: categoriaId,
    );
  }

  @override
  Future<void> actualizarMovimiento(
    Movimiento original,
    Movimiento nuevo,
    String motivo, {
    bool autorizarReserva = false,
  }) async {
    lista[lista.indexWhere((m) => m.id == original.id)] = nuevo;
  }

  @override
  Future<void> confirmarRetiro(double monto, String id) async {
    confirmaciones++;
    if (pendiente != null) await pendiente!.future;
    caja.valor = Caja(
      efectivoTotal: caja.valor.efectivoTotal - monto,
      reservaInsumos: caja.valor.reservaInsumos,
    );
    lista.add(
      Movimiento(
        id: id,
        descripcion: 'Retiro de sueldo',
        monto: monto,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime.now(),
      ),
    );
  }
}

void main() {
  late _Caja caja;
  late _Movimientos movimientos;
  setUp(() {
    caja = _Caja();
    movimientos = _Movimientos(caja);
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          cajaRepositorioProvider.overrideWithValue(caja),
          movimientoRepositorioProvider.overrideWithValue(movimientos),
          categoriasProvider.overrideWith(
            (ref) async => [
              const Categoria(id: 1, nombre: 'Ventas'),
              const Categoria(id: 2, nombre: 'Antigua', archivada: true),
            ],
          ),
        ],
        child: const MiApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> verMovimiento(WidgetTester tester, String descripcion) async {
    final finder = find.text(descripcion);
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cancelar alerta conserva el formulario; confirmar registra el gasto',
    (tester) async {
      movimientos.advertirReserva = true;
      await abrir(tester);
      await tester.tap(find.text('Historial').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar movimiento'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Compra de insumos',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '1400');
      final tipo = find.byType(DropdownButtonFormField<TipoMovimiento>);
      await tester.ensureVisible(tipo);
      await tester.pumpAndSettle();
      await tester.tap(tipo);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gasto').last);
      await tester.pumpAndSettle();
      final guardar = find.text('Guardar movimiento');
      await tester.scrollUntilVisible(
        guardar,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(guardar), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(find.text('Este gasto utiliza tu reserva'), findsOneWidget);
      expect(find.textContaining('Q100.00'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(movimientos.lista, isEmpty);
      expect(find.text('Registrar movimiento'), findsOneWidget);
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar gasto'));
      await tester.pumpAndSettle();
      expect(movimientos.lista, hasLength(1));
      expect(movimientos.lista.single.tipo, TipoMovimiento.gasto);
      expect(movimientos.lista.single.descripcion, 'Compra de insumos');
    },
  );

  testWidgets(
    'confirma una sola vez, regresa al inicio y actualiza saldo e historial',
    (tester) async {
      movimientos.pendiente = Completer<void>();
      await abrir(tester);
      await tester.ensureVisible(find.text('Retirar mi sueldo'));
      await tester.tap(find.text('Retirar mi sueldo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.text('Verificar si es seguro'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirmar retiro'));
      await tester.tap(find.text('Confirmar retiro'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirmando...'),
            )
            .onPressed,
        isNull,
      );
      expect(movimientos.confirmaciones, 1);
      movimientos.pendiente!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Q2000.00'), findsOneWidget);
      await tester.tap(find.text('Historial').last);
      await tester.pumpAndSettle();
      await verMovimiento(tester, 'Retiro de sueldo');
      expect(find.text('Retiro de sueldo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edita caja vacía y reserva con validación de importes', (
    tester,
  ) async {
    caja.valor = const Caja(efectivoTotal: 0, reservaInsumos: 0);
    await abrir(tester);
    await tester.tap(find.byTooltip('Editar caja y reserva'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '-10');
    await tester.scrollUntilVisible(
      find.text('Guardar caja'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar caja'));
    await tester.pumpAndSettle();
    expect(caja.valor.efectivoTotal, 0);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Efectivo total'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Efectivo total'),
      '100,50',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reserva para insumos'),
      '25',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Motivo del cambio de caja'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motivo del cambio de caja'),
      'Conteo inicial',
    );
    await tester.ensureVisible(find.text('Guardar caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar caja'));
    await tester.pumpAndSettle();
    expect(find.text('Q100.50'), findsOneWidget);
    expect(find.text('Q75.50'), findsOneWidget);
  });

  testWidgets(
    'registra movimiento con categoría y permite quitarla desde el historial',
    (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Historial').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar movimiento'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Venta de agua');
      await tester.enterText(find.byType(TextFormField).at(1), '150,25');
      final selector = find.byType(DropdownButtonFormField<int>);
      await tester.scrollUntilVisible(
        selector,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(selector), alignment: 0.3);
      await tester.pumpAndSettle();
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(find.text('Antigua'), findsNothing);
      await tester.tap(find.text('Ventas').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar movimiento'));
      await tester.tap(find.text('Guardar movimiento'));
      await tester.pumpAndSettle();
      expect(movimientos.lista.single.monto, 150.25);
      expect(movimientos.lista.single.categoriaId, 1);
      await verMovimiento(tester, 'Venta de agua');
      expect(find.text('Ventas'), findsOneWidget);
      await tester.tap(find.text('Venta de agua'));
      await tester.pumpAndSettle();
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sin categoría').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motivo de la corrección'),
        'Corregir categoría',
      );
      await tester.ensureVisible(find.text('Guardar movimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar movimiento'));
      await tester.pumpAndSettle();
      expect(movimientos.lista.single.categoriaId, isNull);
      await verMovimiento(tester, 'Venta de agua');
      expect(find.text('Sin categoría'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
