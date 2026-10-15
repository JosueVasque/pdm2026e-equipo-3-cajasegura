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
  return ref.watch(movimientoRepositorioProvider).obtenerHistorial();
});
