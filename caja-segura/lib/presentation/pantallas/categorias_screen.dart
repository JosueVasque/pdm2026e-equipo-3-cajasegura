import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/categoria_repositorio.dart';
import '../../domain/modelos/categoria.dart';
import '../providers/categoria_provider.dart';
import 'categoria_form_screen.dart';

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  Future<void> _abrirFormulario(
    BuildContext context, {
    Categoria? categoria,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoriaFormScreen(categoria: categoria),
      ),
    );
  }

  Future<void> _archivar(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    try {
      await ref.read(categoriaAccionesProvider).archivar(categoria.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Categoría archivada')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(categoriaAccionesProvider).eliminar(categoria.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
    } on CategoriaEnUsoException {
      if (!context.mounted) return;

      final archivar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Categoría en uso'),
          content: const Text(
            'Esta categoría tiene movimientos asociados y no '
            'se puede eliminar. ¿Deseas archivarla?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Archivar'),
            ),
          ],
        ),
      );

      if (archivar == true && context.mounted) {
        await _archivar(context, ref, categoria);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: categorias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar categorías: $error')),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(child: Text('Todavía no hay categorías'));
          }

          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final categoria = lista[index];

              return ListTile(
                title: Text(categoria.nombre),
                subtitle: Text(categoria.archivada ? 'Archivada' : 'Activa'),
                leading: Icon(
                  categoria.archivada
                      ? Icons.archive_outlined
                      : Icons.category_outlined,
                ),
                onTap: () => _abrirFormulario(context, categoria: categoria),
                trailing: PopupMenuButton<String>(
                  onSelected: (accion) {
                    if (accion == 'editar') {
                      _abrirFormulario(context, categoria: categoria);
                    } else if (accion == 'archivar') {
                      _archivar(context, ref, categoria);
                    } else if (accion == 'eliminar') {
                      _eliminar(context, ref, categoria);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    if (!categoria.archivada)
                      const PopupMenuItem(
                        value: 'archivar',
                        child: Text('Archivar'),
                      ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
    );
  }
}
