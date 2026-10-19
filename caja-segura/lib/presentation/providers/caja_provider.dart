import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/caja_repositorio.dart';
import '../../domain/modelos/caja.dart';

/// Repositorio de la caja expuesto como provider.
/// En las pruebas se sobrescribe con un repositorio falso (`overrides`).
final cajaRepositorioProvider = Provider<CajaRepositorio>((ref) {
  return CajaRepositorio();
});

/// Caja leída de la base local. La pantalla la consume como `AsyncValue`
/// (cargando, error o datos) y la vuelve a pedir con `ref.invalidate`.
final cajaProvider = FutureProvider.autoDispose<Caja>((ref) {
  return ref.watch(cajaRepositorioProvider).obtenerCaja();
});
