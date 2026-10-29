import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento.dart';
import '../providers/historial_provider.dart';
import '../providers/navegacion_provider.dart';

enum _FiltroTipo { todos, ingresos, gastos }

enum _FiltroAmbito { todos, empresa, personal }

const _colorEmpresa = Colors.indigo;
const _colorPersonal = Colors.deepOrange;

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  _FiltroTipo get _filtroTipo =>
      switch (ref.read(filtroHistorialProvider).tipo) {
        TipoMovimiento.ingreso => _FiltroTipo.ingresos,
        TipoMovimiento.gasto => _FiltroTipo.gastos,
        null => _FiltroTipo.todos,
      };
  _FiltroAmbito get _filtroAmbito =>
      switch (ref.read(filtroHistorialProvider).ambito) {
        AmbitoMovimiento.empresa => _FiltroAmbito.empresa,
        AmbitoMovimiento.personal => _FiltroAmbito.personal,
        null => _FiltroAmbito.todos,
      };
  void _cambiar({_FiltroTipo? tipo, _FiltroAmbito? ambito}) {
    final t = tipo ?? _filtroTipo;
    final a = ambito ?? _filtroAmbito;
    ref
        .read(filtroHistorialProvider.notifier)
        .cambiar(
          FiltroHistorial(
            tipo: t == _FiltroTipo.todos
                ? null
                : TipoMovimiento.values[t.index - 1],
            ambito: a == _FiltroAmbito.todos
                ? null
                : AmbitoMovimiento.values[a.index - 1],
          ),
        );
  }

  Future<bool> _borrar(Movimiento movimiento) async {
    final repositorio = ref.read(movimientoRepositorioProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // confirmDismiss espera a SQLite: si falla, la fila sigue visible.
      await repositorio.eliminarMovimiento(movimiento.id);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo borrar el movimiento.')),
        );
      }
      return false;
    }
    if (!mounted) return false;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Movimiento eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            try {
              await repositorio.registrarMovimiento(movimiento);
              if (mounted) ref.invalidate(historialProvider);
            } catch (_) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('No se pudo restaurar el movimiento.'),
                ),
              );
            }
          },
        ),
      ),
    );
    return true;
  }

  double _total(List<Movimiento> movimientos, bool ingresos) => movimientos
      .where((m) => m.esIngreso == ingresos)
      .fold<double>(0, (suma, m) => suma + m.monto);

  String get _etiquetaAmbito {
    switch (_filtroAmbito) {
      case _FiltroAmbito.empresa:
        return ' · Empresa';
      case _FiltroAmbito.personal:
        return ' · Personal';
      case _FiltroAmbito.todos:
        return '';
    }
  }

  /// Descarta el resultado anterior (el error) y vuelve a pedir el historial.
  void _reintentar() => ref.invalidate(historialProvider);

  @override
  Widget build(BuildContext context) {
    ref.watch(filtroHistorialProvider);
    final historial = ref.watch(historialProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      // Los 4 estados: cargando, error (con Reintentar), vacío y datos.
      body: historial.when(
        // Al reintentar, mostrar otra vez el indicador de carga.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _EstadoError(onReintentar: _reintentar),
        data: (movimientos) {
          if (movimientos.isEmpty &&
              _filtroTipo == _FiltroTipo.todos &&
              _filtroAmbito == _FiltroAmbito.todos) {
            return const _EstadoVacio();
          }

          final porAmbito = movimientos;
          final lista = movimientos;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TarjetaResumen(
                        titulo: 'Ingresos$_etiquetaAmbito',
                        monto: _total(porAmbito, true),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TarjetaResumen(
                        titulo: 'Gastos$_etiquetaAmbito',
                        monto: _total(porAmbito, false),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todo'),
                      selected: _filtroAmbito == _FiltroAmbito.todos,
                      onSelected: (_) => _cambiar(ambito: _FiltroAmbito.todos),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.storefront, size: 18),
                      label: const Text('Empresa'),
                      selected: _filtroAmbito == _FiltroAmbito.empresa,
                      onSelected: (_) =>
                          _cambiar(ambito: _FiltroAmbito.empresa),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.person, size: 18),
                      label: const Text('Personal'),
                      selected: _filtroAmbito == _FiltroAmbito.personal,
                      onSelected: (_) =>
                          _cambiar(ambito: _FiltroAmbito.personal),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SegmentedButton<_FiltroTipo>(
                  segments: const [
                    ButtonSegment(
                      value: _FiltroTipo.todos,
                      label: Text('Todos'),
                    ),
                    ButtonSegment(
                      value: _FiltroTipo.ingresos,
                      label: Text('Ingresos'),
                    ),
                    ButtonSegment(
                      value: _FiltroTipo.gastos,
                      label: Text('Gastos'),
                    ),
                  ],
                  selected: {_filtroTipo},
                  onSelectionChanged: (s) => _cambiar(tipo: s.first),
                ),
              ),
              Expanded(
                child: lista.isEmpty
                    ? const Center(
                        child: Text('No hay movimientos para mostrar'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => Dismissible(
                          key: ValueKey(lista[i].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) => _borrar(lista[i]),
                          onDismissed: (_) => ref.invalidate(historialProvider),
                          child: _FilaMovimiento(lista[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Estado de error: mensaje entendible y un botón para volver a intentar.
class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el historial.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: todavía no hay movimientos guardados en el teléfono.
class _EstadoVacio extends ConsumerWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48),
            const SizedBox(height: 12),
            const Text('Todavía no hay movimientos registrados.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.read(navegacionProvider.notifier).cambiar(0),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Ir a mi caja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;

  const _TarjetaResumen({
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Q${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distintivo que indica si el movimiento es de la empresa o personal.
class _Distintivo extends StatelessWidget {
  final bool esEmpresa;

  const _Distintivo({required this.esEmpresa});

  @override
  Widget build(BuildContext context) {
    final color = esEmpresa ? _colorEmpresa : _colorPersonal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esEmpresa ? Icons.storefront : Icons.person,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            esEmpresa ? 'Empresa' : 'Personal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  final Movimiento movimiento;

  const _FilaMovimiento(this.movimiento);

  String _fecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    return '$d/$m/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.esIngreso;
    final color = esIngreso ? Colors.green : Colors.red;
    final signo = esIngreso ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(movimiento.descripcion),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            _Distintivo(esEmpresa: movimiento.esEmpresa),
            const SizedBox(width: 8),
            Text(_fecha(movimiento.fecha)),
          ],
        ),
      ),
      trailing: Text(
        '${signo}Q${movimiento.monto.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
