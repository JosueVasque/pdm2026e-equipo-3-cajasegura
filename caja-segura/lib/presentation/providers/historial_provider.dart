import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/movimiento_repositorio.dart';
import '../../domain/modelos/movimiento.dart';
import '../../domain/casos_uso/generar_reporte.dart';

final relojHistorialProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Repositorio de movimientos expuesto como provider.
/// En las pruebas se sobrescribe con un repositorio falso (`overrides`).
final movimientoRepositorioProvider = Provider<MovimientoRepositorio>((ref) {
  return MovimientoRepositorio();
});

/// Historial leído de la base local. La pantalla lo consume como `AsyncValue`
/// (cargando, error o datos) y lo vuelve a pedir con `ref.invalidate`.
final historialProvider = FutureProvider.autoDispose<List<Movimiento>>((ref) {
  return ref.watch(movimientoRepositorioProvider).obtenerHistorial();
});

/// Filtrar es síncrono: conserva la carga original y no vuelve a leer SQLite
/// al cambiar tipo, ámbito o fechas. Las escrituras invalidan [historialProvider].
final historialFiltradoProvider =
    Provider.autoDispose<AsyncValue<List<Movimiento>>>((ref) {
      final filtro = ref.watch(filtroHistorialProvider);
      final rango = ref.watch(rangoHistorialProvider);
      return ref
          .watch(historialProvider)
          .whenData(
            (lista) => lista
                .where(
                  (m) =>
                      (filtro.tipo == null || m.tipo == filtro.tipo) &&
                      (filtro.ambito == null || m.ambito == filtro.ambito) &&
                      (rango == null || rango.contiene(m.fecha)),
                )
                .toList(),
          );
    });

class FiltroHistorial {
  final TipoMovimiento? tipo;
  final AmbitoMovimiento? ambito;
  final PeriodoReporte periodo;
  final RangoReporte? personalizado;
  const FiltroHistorial({
    this.tipo,
    this.ambito,
    this.periodo = PeriodoReporte.todo,
    this.personalizado,
  });
  bool get activo =>
      tipo != null || ambito != null || periodo != PeriodoReporte.todo;
}

class FiltroHistorialNotifier extends Notifier<FiltroHistorial> {
  @override
  FiltroHistorial build() => const FiltroHistorial();
  void cambiar(FiltroHistorial filtro) => state = filtro;
  void seleccionarPeriodo(PeriodoReporte periodo, {RangoReporte? rango}) {
    if (periodo == PeriodoReporte.personalizado && rango == null) return;
    state = FiltroHistorial(
      tipo: state.tipo,
      ambito: state.ambito,
      periodo: periodo,
      personalizado: rango,
    );
  }

  void limpiar() => state = const FiltroHistorial();
}

final filtroHistorialProvider =
    NotifierProvider<FiltroHistorialNotifier, FiltroHistorial>(
      FiltroHistorialNotifier.new,
    );

final rangoHistorialProvider = Provider<RangoReporte?>((ref) {
  final filtro = ref.watch(filtroHistorialProvider);
  return filtro.periodo == PeriodoReporte.personalizado
      ? filtro.personalizado
      : rangoParaPeriodo(filtro.periodo, ref.watch(relojHistorialProvider)());
});
