import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento.dart';
import '../providers/historial_provider.dart';
import '../providers/navegacion_provider.dart';
import '../providers/caja_provider.dart';
import '../providers/categoria_provider.dart';
import 'movimiento_form_screen.dart';
import '../tema/caja_estilo.dart';
import 'frecuentes_screen.dart';
import '../widgets/filtro_fechas_historial.dart';
import 'movimiento_conciliado_screen.dart';
import 'trazabilidad_screen.dart';
import '../providers/trazabilidad_provider.dart';
import '../../domain/modelos/trazabilidad.dart';

enum _FiltroTipo { todos, ingresos, gastos }

enum _FiltroAmbito { todos, empresa, personal }

const _colorEmpresa = CajaEstilo.verde;
const _colorPersonal = CajaEstilo.gris;

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
    final actual = ref.read(filtroHistorialProvider);
    final t = tipo ?? _filtroTipo;
    final a = ambito ?? _filtroAmbito;
    ref
        .read(filtroHistorialProvider.notifier)
        .cambiar(
          FiltroHistorial(
            periodo: actual.periodo,
            personalizado: actual.personalizado,
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
      ref.invalidate(cajaProvider);
      ref.invalidate(cambiosProvider);
    } on MovimientoConciliadoException catch (e) {
      if (mounted) {
        ref.invalidate(historialProvider);
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return false;
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
              await repositorio.restaurarMovimiento(movimiento);
              if (mounted) {
                ref.invalidate(historialProvider);
                ref.invalidate(cajaProvider);
                ref.invalidate(cambiosProvider);
              }
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
    final filtro = ref.watch(filtroHistorialProvider);
    final historial = ref.watch(historialFiltradoProvider);
    final categorias = ref.watch(categoriasProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Trazabilidad',
            icon: const Icon(Icons.history_rounded, color: CajaEstilo.menta),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrazabilidadScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Movimientos frecuentes',
            icon: const Icon(Icons.bolt_outlined, color: CajaEstilo.menta),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FrecuentesScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'registrar-movimiento',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MovimientoFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Registrar movimiento'),
      ),
      // Los 4 estados: cargando, error (con Reintentar), vacío y datos.
      body: SuperficieCaja(
        child: historial.when(
          // Al reintentar, mostrar otra vez el indicador de carga.
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _EstadoError(onReintentar: _reintentar),
          data: (movimientos) {
            if (movimientos.isEmpty && !filtro.activo) {
              return const _EstadoVacio();
            }

            final porAmbito = movimientos;
            final lista = movimientos;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 26, 24, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cada movimiento cuenta.',
                            style: TextStyle(
                              fontSize: 23,
                              letterSpacing: -0.6,
                              fontWeight: FontWeight.w700,
                              color: CajaEstilo.tinta,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TarjetaResumen(
                                titulo: 'Ingresos$_etiquetaAmbito',
                                monto: _total(porAmbito, true),
                                color: CajaEstilo.verde,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TarjetaResumen(
                                titulo: 'Gastos$_etiquetaAmbito',
                                monto: _total(porAmbito, false),
                                color: CajaEstilo.peligro,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const FiltroFechasHistorial(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              labelStyle: TextStyle(
                                fontFamily: 'Roboto',
                                color: _filtroAmbito == _FiltroAmbito.todos
                                    ? Colors.white
                                    : CajaEstilo.gris,
                              ),
                              label: const Text('Todo'),
                              selected: _filtroAmbito == _FiltroAmbito.todos,
                              onSelected: (_) =>
                                  _cambiar(ambito: _FiltroAmbito.todos),
                            ),
                            ChoiceChip(
                              labelStyle: TextStyle(
                                fontFamily: 'Roboto',
                                color: _filtroAmbito == _FiltroAmbito.empresa
                                    ? Colors.white
                                    : CajaEstilo.gris,
                              ),
                              avatarBorder: const CircleBorder(),
                              avatar: Icon(
                                Icons.storefront,
                                size: 18,
                                color: _filtroAmbito == _FiltroAmbito.empresa
                                    ? CajaEstilo.menta
                                    : CajaEstilo.verde,
                              ),
                              label: const Text('Empresa'),
                              selected: _filtroAmbito == _FiltroAmbito.empresa,
                              onSelected: (_) =>
                                  _cambiar(ambito: _FiltroAmbito.empresa),
                            ),
                            ChoiceChip(
                              labelStyle: TextStyle(
                                fontFamily: 'Roboto',
                                color: _filtroAmbito == _FiltroAmbito.personal
                                    ? Colors.white
                                    : CajaEstilo.gris,
                              ),
                              avatar: Icon(
                                Icons.person,
                                size: 18,
                                color: _filtroAmbito == _FiltroAmbito.personal
                                    ? CajaEstilo.menta
                                    : CajaEstilo.verde,
                              ),
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
                          showSelectedIcon: false,
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
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Movimientos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CajaEstilo.tinta,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Desliza para borrar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: CajaEstilo.gris,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                lista.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No hay movimientos para mostrar'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList.separated(
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => Dismissible(
                            key: ValueKey(lista[i].id),
                            direction: lista[i].conciliado
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
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
                            onDismissed: (_) =>
                                ref.invalidate(historialProvider),
                            child: Card(
                              child: _FilaMovimiento(
                                lista[i],
                                categoria: lista[i].categoriaId == null
                                    ? 'Sin categoría'
                                    : categorias
                                              .where(
                                                (c) =>
                                                    c.id ==
                                                    lista[i].categoriaId,
                                              )
                                              .map(
                                                (c) =>
                                                    '${c.nombre}${c.archivada ? ' (archivada)' : ''}',
                                              )
                                              .firstOrNull ??
                                          'Categoría no disponible',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => lista[i].conciliado
                                        ? MovimientoConciliadoScreen(
                                            movimiento: lista[i],
                                          )
                                        : MovimientoFormScreen(
                                            movimiento: lista[i],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
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
      color: color == CajaEstilo.verde ? const Color(0xFFDDF9EA) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              color == CajaEstilo.verde
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              size: 21,
              color: color,
            ),
            const SizedBox(height: 14),
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Q${monto.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CajaEstilo.tinta,
                ),
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
  final String categoria;
  final VoidCallback onTap;

  const _FilaMovimiento(
    this.movimiento, {
    required this.categoria,
    required this.onTap,
  });

  String _fecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    return '$d/$m/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.esIngreso;
    final color = esIngreso ? CajaEstilo.verde : CajaEstilo.peligro;
    final signo = esIngreso ? '+' : '-';

    return ListTile(
      onTap: onTap,
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
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Distintivo(esEmpresa: movimiento.esEmpresa),
            Text(_fecha(movimiento.fecha)),
            Text(categoria),
            if (movimiento.conciliado)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 12),
                  SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      'Conciliado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
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
