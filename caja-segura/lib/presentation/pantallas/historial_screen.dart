import 'package:flutter/material.dart';
import '../../data/repositorios/movimiento_repositorio.dart';
import '../../domain/modelos/movimiento.dart';
import '../widgets/carga_datos.dart';

enum _FiltroTipo { todos, ingresos, gastos }

enum _FiltroAmbito { todos, empresa, personal }

const _colorEmpresa = Colors.indigo;
const _colorPersonal = Colors.deepOrange;

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, this.repositorio});

  final MovimientoRepositorio? repositorio;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late final _repositorio = widget.repositorio ?? MovimientoRepositorio();
  late Future<List<Movimiento>> _historial = _repositorio.obtenerHistorial();
  _FiltroTipo _filtroTipo = _FiltroTipo.todos;
  _FiltroAmbito _filtroAmbito = _FiltroAmbito.todos;

  /// Movimientos del ámbito elegido (base para los totales).
  List<Movimiento> _porAmbito(List<Movimiento> movimientos) {
    switch (_filtroAmbito) {
      case _FiltroAmbito.empresa:
        return movimientos.where((m) => m.esEmpresa).toList();
      case _FiltroAmbito.personal:
        return movimientos.where((m) => !m.esEmpresa).toList();
      case _FiltroAmbito.todos:
        return movimientos;
    }
  }

  /// Movimientos del ámbito elegido y del tipo elegido (la lista visible).
  List<Movimiento> _filtrados(List<Movimiento> movimientos) {
    switch (_filtroTipo) {
      case _FiltroTipo.ingresos:
        return movimientos.where((m) => m.esIngreso).toList();
      case _FiltroTipo.gastos:
        return movimientos.where((m) => !m.esIngreso).toList();
      case _FiltroTipo.todos:
        return movimientos;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: CargaDatos<List<Movimiento>>(
        future: _historial,
        onReintentar: () => setState(() {
          _historial = _repositorio.obtenerHistorial();
        }),
        builder: (movimientos) {
          final porAmbito = _porAmbito(movimientos);
          final lista = _filtrados(porAmbito);
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
                      onSelected: (_) =>
                          setState(() => _filtroAmbito = _FiltroAmbito.todos),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.storefront, size: 18),
                      label: const Text('Empresa'),
                      selected: _filtroAmbito == _FiltroAmbito.empresa,
                      onSelected: (_) =>
                          setState(() => _filtroAmbito = _FiltroAmbito.empresa),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.person, size: 18),
                      label: const Text('Personal'),
                      selected: _filtroAmbito == _FiltroAmbito.personal,
                      onSelected: (_) => setState(
                        () => _filtroAmbito = _FiltroAmbito.personal,
                      ),
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
                  onSelectionChanged: (s) =>
                      setState(() => _filtroTipo = s.first),
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
                        itemBuilder: (_, i) => _FilaMovimiento(lista[i]),
                      ),
              ),
            ],
          );
        },
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
