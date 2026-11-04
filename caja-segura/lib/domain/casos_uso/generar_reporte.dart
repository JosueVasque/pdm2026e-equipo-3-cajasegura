import '../modelos/categoria.dart';
import '../modelos/movimiento.dart';

enum PeriodoReporte { hoy, semana, mes, todo, personalizado }

class RangoReporte {
  RangoReporte(DateTime inicio, DateTime fin)
    : inicio = DateTime(inicio.year, inicio.month, inicio.day),
      finExclusivo = DateTime(fin.year, fin.month, fin.day + 1) {
    if (!this.inicio.isBefore(finExclusivo)) {
      throw ArgumentError(
        'La fecha inicial debe ser anterior o igual a la final.',
      );
    }
  }
  final DateTime inicio;
  final DateTime finExclusivo;
  DateTime get fin =>
      DateTime(finExclusivo.year, finExclusivo.month, finExclusivo.day - 1);
  bool contiene(DateTime fecha) =>
      !fecha.isBefore(inicio) && fecha.isBefore(finExclusivo);
}

RangoReporte? rangoParaPeriodo(PeriodoReporte periodo, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  return switch (periodo) {
    PeriodoReporte.hoy => RangoReporte(hoy, hoy),
    PeriodoReporte.semana => RangoReporte(
      DateTime(hoy.year, hoy.month, hoy.day - hoy.weekday + 1),
      hoy,
    ),
    PeriodoReporte.mes => RangoReporte(DateTime(hoy.year, hoy.month), hoy),
    PeriodoReporte.todo => null,
    PeriodoReporte.personalizado => throw ArgumentError(
      'Selecciona un rango personalizado.',
    ),
  };
}

class ResumenCategoria {
  const ResumenCategoria({
    required this.id,
    required this.nombre,
    required this.archivada,
    required this.ingresosCentavos,
    required this.gastosCentavos,
    required this.cantidad,
  });
  final int? id;
  final String nombre;
  final bool archivada;
  final int ingresosCentavos;
  final int gastosCentavos;
  final int cantidad;
}

class ReporteMovimientos {
  const ReporteMovimientos({
    required this.movimientos,
    required this.categorias,
    required this.ingresosCentavos,
    required this.gastosCentavos,
  });
  final List<Movimiento> movimientos;
  final List<ResumenCategoria> categorias;
  final int ingresosCentavos;
  final int gastosCentavos;
  int get balanceCentavos => ingresosCentavos - gastosCentavos;
}

ReporteMovimientos generarReporte(
  List<Movimiento> movimientos,
  List<Categoria> categorias, {
  RangoReporte? rango,
  AmbitoMovimiento? ambito = AmbitoMovimiento.empresa,
}) {
  final filtrados =
      movimientos
          .where(
            (m) =>
                (rango == null || rango.contiene(m.fecha)) &&
                (ambito == null || m.ambito == ambito),
          )
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
  final grupos = <int?, List<Movimiento>>{};
  var ingresos = 0;
  var gastos = 0;
  for (final m in filtrados) {
    final centavos = (m.monto * 100).round();
    if (m.esIngreso) {
      ingresos += centavos;
    } else {
      gastos += centavos;
    }
    grupos.putIfAbsent(m.categoriaId, () => []).add(m);
  }
  final nombres = {for (final c in categorias) c.id: c};
  final resumenes =
      grupos.entries.map((grupo) {
        final categoria = nombres[grupo.key];
        return ResumenCategoria(
          id: grupo.key,
          nombre: grupo.key == null
              ? 'Sin categoría'
              : categoria?.nombre ?? 'Categoría no disponible',
          archivada: categoria?.archivada ?? false,
          ingresosCentavos: grupo.value
              .where((m) => m.esIngreso)
              .fold<int>(0, (s, m) => s + (m.monto * 100).round()),
          gastosCentavos: grupo.value
              .where((m) => !m.esIngreso)
              .fold<int>(0, (s, m) => s + (m.monto * 100).round()),
          cantidad: grupo.value.length,
        );
      }).toList()..sort((a, b) {
        final orden = (b.gastosCentavos + b.ingresosCentavos).compareTo(
          a.gastosCentavos + a.ingresosCentavos,
        );
        return orden == 0 ? a.nombre.compareTo(b.nombre) : orden;
      });
  return ReporteMovimientos(
    movimientos: List.unmodifiable(filtrados),
    categorias: List.unmodifiable(resumenes),
    ingresosCentavos: ingresos,
    gastosCentavos: gastos,
  );
}
