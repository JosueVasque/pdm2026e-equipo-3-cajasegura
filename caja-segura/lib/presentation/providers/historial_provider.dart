import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/movimiento_repositorio.dart';
import '../../domain/modelos/movimiento.dart';

/// Repositorio de movimientos expuesto como provider.
/// En las pruebas se sobrescribe con un repositorio falso (`overrides`).
final movimientoRepositorioProvider = Provider<MovimientoRepositorio>((ref) {
  return MovimientoRepositorio();
});

/// Historial leído de la base local. La pantalla lo consume como `AsyncValue`
/// (cargando, error o datos) y lo vuelve a pedir con `ref.invalidate`.
final historialProvider = FutureProvider.autoDispose<List<Movimiento>>((ref) {
  final filtro = ref.watch(filtroHistorialProvider);
  return ref
      .watch(movimientoRepositorioProvider)
      .obtenerHistorial()
      .then(
        (lista) => lista
            .where(
              (m) =>
                  (filtro.tipo == null || m.tipo == filtro.tipo) &&
                  (filtro.ambito == null || m.ambito == filtro.ambito),
            )
            .toList(),
      );
});

class FiltroHistorial {
  final TipoMovimiento? tipo;
  final AmbitoMovimiento? ambito;
  const FiltroHistorial({this.tipo, this.ambito});
}

class FiltroHistorialNotifier extends Notifier<FiltroHistorial> {
  @override
  FiltroHistorial build() => const FiltroHistorial();
  void cambiar(FiltroHistorial filtro) => state = filtro;
}

final filtroHistorialProvider =
    NotifierProvider<FiltroHistorialNotifier, FiltroHistorial>(
      FiltroHistorialNotifier.new,
    );
