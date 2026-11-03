import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositorios/trazabilidad_repositorio.dart';
import '../../domain/modelos/trazabilidad.dart';

final trazabilidadRepositorioProvider = Provider<TrazabilidadRepositorio>(
  (ref) => TrazabilidadRepositorio(),
);
final instantaneasCierreProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) => ref.watch(trazabilidadRepositorioProvider).instantaneas(id),
    );
final cambiosProvider = FutureProvider.autoDispose
    .family<List<CambioMovimiento>, String?>(
      (ref, id) =>
          ref.watch(trazabilidadRepositorioProvider).cambios(movimientoId: id),
    );
final ajustesProvider = FutureProvider.autoDispose
    .family<List<AjusteMovimiento>, String?>(
      (ref, id) =>
          ref.watch(trazabilidadRepositorioProvider).ajustes(movimientoId: id),
    );
