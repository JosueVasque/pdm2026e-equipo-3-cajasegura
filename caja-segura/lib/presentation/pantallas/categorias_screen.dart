import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositorios/categoria_repositorio.dart';
import '../../domain/modelos/categoria.dart';
import '../providers/categoria_provider.dart';
import 'categoria_form_screen.dart';
import '../tema/caja_estilo.dart';

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
      body: SuperficieCaja(
        child: categorias.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Error al cargar categorías: $error')),
          data: (lista) {
            if (lista.isEmpty) {
              return const Center(child: Text('Todavía no hay categorías'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: lista.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IconoCaja(
                          Icons.grid_view_rounded,
                          oscuro: true,
                          tamano: 54,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Un lugar para\ncada movimiento.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${lista.where((c) => !c.archivada).length} categorías activas · Organiza tus ingresos y gastos.',
                        ),
                      ],
                    ),
                  );
                }
                final categoria = lista[index - 1];

                return Card(
                  child: ListTile(
                    title: Text(categoria.nombre),
                    subtitle: Text(
                      categoria.archivada ? 'Archivada' : 'Activa',
                    ),
                    leading: IconoCaja(
                      categoria.archivada
                          ? Icons.archive_outlined
                          : Icons.category_outlined,
                    ),
                    onTap: () =>
                        _abrirFormulario(context, categoria: categoria),
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
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
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
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'crear-categoria',
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
    );
  }
}
