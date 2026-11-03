import 'package:flutter_test/flutter_test.dart';
import 'package:caja_segura/domain/casos_uso/generar_reporte.dart';
import 'package:caja_segura/domain/casos_uso/evaluar_reserva.dart';
import 'package:caja_segura/domain/modelos/caja.dart';
import 'package:caja_segura/domain/modelos/categoria.dart';
import 'package:caja_segura/domain/modelos/movimiento.dart';

Movimiento _mov(
  String id,
  DateTime fecha,
  double monto, {
  bool ingreso = false,
  AmbitoMovimiento ambito = AmbitoMovimiento.empresa,
  int? categoria,
}) => Movimiento(
  id: id,
  descripcion: id,
  monto: monto,
  tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
  ambito: ambito,
  fecha: fecha,
  categoriaId: categoria,
);

void main() {
  test(
    'rangos incluyen día completo y semana desde lunes, cruzando mes y año',
    () {
      final ahora = DateTime(2027, 1, 1, 15);
      final hoy = rangoParaPeriodo(PeriodoReporte.hoy, ahora)!;
      expect(hoy.contiene(DateTime(2027, 1, 1)), isTrue);
      expect(hoy.contiene(DateTime(2027, 1, 1, 23, 59, 59, 999, 999)), isTrue);
      expect(hoy.contiene(DateTime(2027, 1, 2)), isFalse);
      expect(
        rangoParaPeriodo(PeriodoReporte.semana, ahora)!.inicio,
        DateTime(2026, 12, 28),
      );
      expect(
        rangoParaPeriodo(PeriodoReporte.mes, ahora)!.inicio,
        DateTime(2027, 1, 1),
      );
      expect(rangoParaPeriodo(PeriodoReporte.todo, ahora), isNull);
      expect(
        RangoReporte(DateTime(2024, 2, 29), DateTime(2024, 2, 29)).finExclusivo,
        DateTime(2024, 3, 1),
      );
      expect(
        () => RangoReporte(DateTime(2026, 11, 4), DateTime(2026, 11, 3)),
        throwsArgumentError,
      );
    },
  );

  test(
    'reporte combina fechas y ámbito, agrupa archivadas y sin categoría en centavos',
    () {
      final movimientos = [
        _mov('antes', DateTime(2026, 10, 31), 999, ingreso: true),
        _mov(
          'venta',
          DateTime(2026, 11, 1),
          100.10,
          ingreso: true,
          categoria: 1,
        ),
        _mov('insumos', DateTime(2026, 11, 3, 23, 59), 30.20, categoria: 2),
        _mov('otro', DateTime(2026, 11, 2), 10),
        _mov(
          'personal',
          DateTime(2026, 11, 2),
          5,
          ambito: AmbitoMovimiento.personal,
        ),
        _mov('despues', DateTime(2026, 11, 4), 999),
      ];
      const categorias = [
        Categoria(id: 1, nombre: 'Ventas'),
        Categoria(id: 2, nombre: 'Insumos', archivada: true),
      ];
      final rango = RangoReporte(DateTime(2026, 11, 1), DateTime(2026, 11, 3));
      final reporte = generarReporte(movimientos, categorias, rango: rango);
      expect(reporte.ingresosCentavos, 10010);
      expect(reporte.gastosCentavos, 4020);
      expect(reporte.balanceCentavos, 5990);
      expect(reporte.movimientos, hasLength(3));
      expect(
        reporte.categorias.singleWhere((c) => c.id == 2).archivada,
        isTrue,
      );
      expect(
        reporte.categorias.singleWhere((c) => c.id == null).gastosCentavos,
        1000,
      );
      final personal = generarReporte(
        movimientos,
        categorias,
        rango: rango,
        ambito: AmbitoMovimiento.personal,
      );
      expect(personal.balanceCentavos, -500);
      expect(
        generarReporte(
          movimientos,
          categorias,
          rango: rango,
          ambito: null,
        ).gastosCentavos,
        4520,
      );
    },
  );

  test('vacío e ingresos sin gastos no generan valores indefinidos', () {
    expect(generarReporte([], []).balanceCentavos, 0);
    final r = generarReporte([
      _mov('a', DateTime(2026), 0.1, ingreso: true),
      _mov('b', DateTime(2026), 0.2, ingreso: true),
    ], []);
    expect(r.ingresosCentavos, 30);
    expect(r.gastosCentavos, 0);
    expect(r.categorias.single.nombre, 'Sin categoría');
  });

  test('evalúa reserva insuficiente, límite y reserva cero', () {
    final bajo = evaluarReserva(
      const Caja(efectivoTotal: 100.10, reservaInsumos: 120.30),
    );
    expect(bajo.estado, EstadoReserva.insuficiente);
    expect(bajo.faltanteCentavos, 2020);
    expect(
      evaluarReserva(
        const Caja(efectivoTotal: 1200, reservaInsumos: 1200),
      ).estado,
      EstadoReserva.sinMargen,
    );
    expect(
      evaluarReserva(
        const Caja(efectivoTotal: 0, reservaInsumos: 1200),
      ).faltanteCentavos,
      120000,
    );
    expect(
      evaluarReserva(const Caja(efectivoTotal: 0, reservaInsumos: 0)).estado,
      EstadoReserva.protegida,
    );
    expect(
      evaluarReserva(
        const Caja(efectivoTotal: 2500, reservaInsumos: 1200),
      ).estado,
      EstadoReserva.protegida,
    );
  });
}
