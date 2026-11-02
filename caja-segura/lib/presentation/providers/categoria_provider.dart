import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/categoria_repositorio.dart';
import '../../domain/modelos/categoria.dart';

final categoriaRepositorioProvider = Provider<CategoriaRepositorio>((ref) {
  return CategoriaRepositorio();
});

final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final repositorio = ref.watch(categoriaRepositorioProvider);
  return repositorio.listar(incluirArchivadas: true);
});

final categoriaAccionesProvider = Provider<CategoriaAcciones>((ref) {
  return CategoriaAcciones(ref);
});

class CategoriaAcciones {
  CategoriaAcciones(this.ref);

  final Ref ref;

  Future<void> crear(String nombre) async {
    await ref.read(categoriaRepositorioProvider).crear(nombre);
    ref.invalidate(categoriasProvider);
  }

  Future<void> actualizar(int id, String nombre) async {
    await ref.read(categoriaRepositorioProvider).actualizar(id, nombre);
    ref.invalidate(categoriasProvider);
  }

  Future<void> eliminar(int id) async {
    await ref.read(categoriaRepositorioProvider).eliminar(id);
    ref.invalidate(categoriasProvider);
  }

  Future<void> archivar(int id) async {
    await ref.read(categoriaRepositorioProvider).archivar(id);
    ref.invalidate(categoriasProvider);
  }
}
