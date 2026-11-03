import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento_frecuente.dart';
import '../../domain/modelos/movimiento.dart';
import '../providers/operaciones_provider.dart';
import '../tema/caja_estilo.dart';
import 'movimiento_form_screen.dart';

class FrecuentesScreen extends ConsumerWidget {
  const FrecuentesScreen({super.key});
  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    MovimientoFrecuente f,
  ) async {
    final acepta = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar frecuente'),
        content: Text(
          '¿Eliminar la plantilla "${f.descripcion}"? Los movimientos registrados se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (acepta != true || !context.mounted) return;
    try {
      await ref.read(frecuenteRepositorioProvider).eliminar(f.id!);
      ref.invalidate(frecuentesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el frecuente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(frecuentesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos frecuentes')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo-frecuente',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MovimientoFormScreen(configurarFrecuente: true),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo frecuente'),
      ),
      body: SuperficieCaja(
        child: estado.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(frecuentesProvider),
              child: const Text('No se pudieron cargar. Reintentar'),
            ),
          ),
          data: (lista) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
            children: [
              Text(
                'Menos pasos,\nmismo control.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Toca una plantilla para revisar sus datos y registrar un movimiento. No se registra nada automáticamente.',
              ),
              const SizedBox(height: 24),
              if (lista.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no hay frecuentes. Crea uno o guarda un movimiento del historial como plantilla.',
                    ),
                  ),
                ),
              for (final f in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const IconoCaja(Icons.bolt_rounded),
                      title: Text(f.descripcion),
                      subtitle: Text(
                        '${f.tipo == TipoMovimiento.ingreso ? 'Ingreso' : 'Gasto'} · ${f.ambito == AmbitoMovimiento.empresa ? 'Empresa' : 'Personal'}\nQ${f.monto.toStringAsFixed(2)}',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovimientoFormScreen(frecuente: f),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'editar') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovimientoFormScreen(
                                  frecuente: f,
                                  configurarFrecuente: true,
                                ),
                              ),
                            );
                          }
                          if (v == 'eliminar') {
                            _eliminar(context, ref, f);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'eliminar',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
