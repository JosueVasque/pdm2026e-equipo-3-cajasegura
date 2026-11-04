import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositorios/frecuente_repositorio.dart';
import '../../data/repositorios/cierre_repositorio.dart';
import '../../domain/modelos/movimiento_frecuente.dart';
import '../../domain/modelos/cierre_caja.dart';

final frecuenteRepositorioProvider = Provider<FrecuenteRepositorio>(
  (ref) => FrecuenteRepositorio(),
);
final frecuentesProvider =
    FutureProvider.autoDispose<List<MovimientoFrecuente>>(
      (ref) => ref.watch(frecuenteRepositorioProvider).listar(),
    );
final cierreRepositorioProvider = Provider<CierreRepositorio>(
  (ref) => CierreRepositorio(),
);
final cierresProvider = FutureProvider.autoDispose<List<CierreCaja>>(
  (ref) => ref.watch(cierreRepositorioProvider).listar(),
);
