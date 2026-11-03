import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/casos_uso/generar_reporte.dart';
import '../../domain/modelos/movimiento.dart';
import '../../domain/casos_uso/resumir_retiros.dart';
import 'categoria_provider.dart';
import 'historial_provider.dart';

final relojReportesProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class FiltroReporte {
  const FiltroReporte({
    this.periodo = PeriodoReporte.mes,
    this.ambito = AmbitoMovimiento.empresa,
    this.personalizado,
  });
  final PeriodoReporte periodo;
  final AmbitoMovimiento? ambito;
  final RangoReporte? personalizado;
}

class FiltroReporteNotifier extends Notifier<FiltroReporte> {
  @override
  FiltroReporte build() => const FiltroReporte();
  void periodo(PeriodoReporte periodo, {RangoReporte? rango}) {
    if (periodo == PeriodoReporte.personalizado && rango == null) return;
    state = FiltroReporte(
      periodo: periodo,
      ambito: state.ambito,
      personalizado: rango,
    );
  }

  void ambito(AmbitoMovimiento? ambito) {
    state = FiltroReporte(
      periodo: state.periodo,
      ambito: ambito,
      personalizado: state.personalizado,
    );
  }
}

final filtroReporteProvider =
    NotifierProvider<FiltroReporteNotifier, FiltroReporte>(
      FiltroReporteNotifier.new,
    );

final rangoReporteProvider = Provider<RangoReporte?>((ref) {
  final filtro = ref.watch(filtroReporteProvider);
  return filtro.periodo == PeriodoReporte.personalizado
      ? filtro.personalizado
      : rangoParaPeriodo(filtro.periodo, ref.watch(relojReportesProvider)());
});

final reporteProvider = Provider<AsyncValue<ReporteMovimientos>>((ref) {
  final historial = ref.watch(historialProvider);
  final categorias = ref.watch(categoriasProvider);
  final filtro = ref.watch(filtroReporteProvider);
  final rango = ref.watch(rangoReporteProvider);
  if (historial.hasError) {
    return AsyncError(historial.error!, historial.stackTrace!);
  }
  if (categorias.hasError) {
    return AsyncError(categorias.error!, categorias.stackTrace!);
  }
  if (historial.isLoading || categorias.isLoading) return const AsyncLoading();
  return AsyncData(
    generarReporte(
      historial.requireValue,
      categorias.requireValue,
      rango: rango,
      ambito: filtro.ambito,
    ),
  );
});

final resumenRetirosProvider = Provider<AsyncValue<ResumenRetiros>>((ref) {
  final rango = ref.watch(rangoReporteProvider);
  return ref
      .watch(historialProvider)
      .whenData((lista) => resumirRetiros(lista, rango: rango));
});

class VistaReporteNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void seleccionar(bool retiros) => state = retiros;
}

final vistaRetirosProvider = NotifierProvider<VistaReporteNotifier, bool>(
  VistaReporteNotifier.new,
);
