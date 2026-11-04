import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../providers/trazabilidad_provider.dart';
import '../providers/caja_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/formato.dart';
import '../widgets/importes.dart';
import '../widgets/confirmar_reserva.dart';
import 'trazabilidad_screen.dart';

class MovimientoConciliadoScreen extends ConsumerWidget {
  const MovimientoConciliadoScreen({super.key, required this.movimiento});
  final Movimiento movimiento;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Movimiento conciliado')),
    body: SuperficieCaja(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: IconoCaja(
              Icons.lock_outline_rounded,
              oscuro: true,
              tamano: 54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            movimiento.descripcion,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '${dineroCentavos((movimiento.monto * 100).round())} · ${fechaHora(movimiento.fecha)}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Este registro está protegido por un cierre. No se puede editar ni borrar. Una corrección crea un ajuste nuevo y conserva el original y el cierre.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _AjusteScreen(movimiento: movimiento),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Registrar ajuste'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrazabilidadScreen(movimientoId: movimiento.id),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Ver trazabilidad'),
          ),
          const SizedBox(height: 28),
          Text(
            'Ajustes posteriores',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ref
              .watch(ajustesProvider(movimiento.id))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () =>
                      ref.invalidate(ajustesProvider(movimiento.id)),
                  child: const Text('Reintentar ajustes'),
                ),
                data: (lista) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lista.isEmpty) const Text('No hay ajustes vinculados.'),
                    for (final ajuste in lista)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fechaHora(ajuste.fecha)),
                              Text(
                                ajuste.deltaCentavos == 0
                                    ? 'Aclaración sin cambio de saldo'
                                    : 'Cambio en caja: ${dineroCentavos(ajuste.deltaCentavos)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CajaEstilo.tinta,
                                ),
                              ),
                              Text(ajuste.motivo),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}

class _AjusteScreen extends ConsumerStatefulWidget {
  const _AjusteScreen({required this.movimiento});
  final Movimiento movimiento;
  @override
  ConsumerState<_AjusteScreen> createState() => _AjusteScreenState();
}

class _AjusteScreenState extends ConsumerState<_AjusteScreen> {
  final _form = GlobalKey<FormState>();
  final _monto = TextEditingController();
  final _motivo = TextEditingController();
  late final _id = 'ajuste-${DateTime.now().microsecondsSinceEpoch}';
  int _efecto = 0;
  bool _guardando = false;
  @override
  void dispose() {
    _monto.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final repo = ref.read(trazabilidadRepositorioProvider);
      final delta = _efecto == 0
          ? 0
          : (leerImporte(_monto.text)! * 100).round() * _efecto;
      Future<void> registrar(bool autorizar) => repo.ajustar(
        id: _id,
        movimientoId: widget.movimiento.id,
        deltaCentavos: delta,
        motivo: _motivo.text,
        autorizarReserva: autorizar,
      );
      try {
        await registrar(false);
      } on ReservaRequiereConfirmacion catch (e) {
        if (!mounted ||
            !await confirmarReserva(context, e.faltanteCentavos) ||
            !mounted) {
          return;
        }
        await registrar(true);
      }
      if (!mounted) return;
      ref.invalidate(cajaProvider);
      ref.invalidate(ajustesProvider);
      ref.invalidate(cambiosProvider);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el ajuste: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajuste de corrección')),
    body: SuperficieCaja(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Un ajuste nuevo.\nEl original se conserva.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Vinculado a: ${widget.movimiento.descripcion}'),
            const SizedBox(height: 16),
            const Text(
              'Registra solo la diferencia o una aclaración. No repitas el monto completo del movimiento. Este ajuste no se contará como venta, gasto ni retiro nuevo.',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _efecto,
              decoration: const InputDecoration(labelText: 'Efecto del ajuste'),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Solo aclaración'),
                ),
                if (widget.movimiento.esEmpresa) ...[
                  const DropdownMenuItem(
                    value: 1,
                    child: Text('Aumentar efectivo'),
                  ),
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('Disminuir efectivo'),
                  ),
                ],
              ],
              onChanged: _guardando
                  ? null
                  : (v) => setState(() => _efecto = v!),
            ),
            if (_efecto != 0) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _monto,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto de la diferencia',
                  prefixText: 'Q ',
                ),
                validator: (v) => (leerImporte(v ?? '') ?? 0) <= 0
                    ? 'Ingresa un monto positivo con hasta 2 decimales'
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _motivo,
              enabled: !_guardando,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo y explicación de la corrección',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Explica la corrección'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando...' : 'Registrar ajuste'),
            ),
          ],
        ),
      ),
    ),
  );
}
