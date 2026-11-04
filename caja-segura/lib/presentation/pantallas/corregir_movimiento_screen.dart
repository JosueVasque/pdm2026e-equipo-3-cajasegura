import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../providers/historial_provider.dart';
import '../providers/caja_provider.dart';
import '../providers/categoria_provider.dart';
import '../providers/trazabilidad_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/importes.dart';
import '../widgets/confirmar_reserva.dart';

class CorregirMovimientoScreen extends ConsumerStatefulWidget {
  const CorregirMovimientoScreen({super.key, required this.movimiento});
  final Movimiento movimiento;
  @override
  ConsumerState<CorregirMovimientoScreen> createState() =>
      _CorregirMovimientoScreenState();
}

class _CorregirMovimientoScreenState
    extends ConsumerState<CorregirMovimientoScreen> {
  final _form = GlobalKey<FormState>();
  late final _descripcion = TextEditingController(
    text: widget.movimiento.descripcion,
  );
  late final _monto = TextEditingController(
    text: widget.movimiento.monto.toStringAsFixed(2),
  );
  final _motivo = TextEditingController();
  late TipoMovimiento _tipo = widget.movimiento.tipo;
  late AmbitoMovimiento _ambito = widget.movimiento.ambito;
  late DateTime _fecha = widget.movimiento.fecha;
  late int? _categoria = widget.movimiento.categoriaId;
  bool _guardando = false;
  @override
  void dispose() {
    _descripcion.dispose();
    _monto.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    final original = widget.movimiento;
    final nuevo = Movimiento(
      id: original.id,
      descripcion: _descripcion.text.trim(),
      monto: leerImporte(_monto.text)!,
      tipo: _tipo,
      ambito: _ambito,
      fecha: _fecha,
      categoriaId: _categoria,
      esRetiro: original.esRetiro,
      impactoCajaCentavos: original.impactoCajaCentavos,
    );
    try {
      final repo = ref.read(movimientoRepositorioProvider);
      try {
        await repo.actualizarMovimiento(original, nuevo, _motivo.text);
      } on ReservaRequiereConfirmacion catch (e) {
        if (!mounted ||
            !await confirmarReserva(context, e.faltanteCentavos) ||
            !mounted) {
          return;
        }
        await repo.actualizarMovimiento(
          original,
          nuevo,
          _motivo.text,
          autorizarReserva: true,
        );
      }
      if (!mounted) return;
      ref.invalidate(historialProvider);
      ref.invalidate(cajaProvider);
      ref.invalidate(cambiosProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo corregir: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(categoriasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Corregir movimiento')),
      body: SuperficieCaja(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Corrige sin perder\nla historia.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Se conservarán los datos anteriores, los nuevos y el motivo. Si el movimiento ya fue incluido en un cierre, la corrección será rechazada.',
              ),
              if (widget.movimiento.esEmpresa &&
                  widget.movimiento.impactoCajaCentavos == 0)
                const Text(
                  'Este registro histórico no afectó la caja; su corrección tampoco cambiará el saldo.',
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcion,
                enabled: !_guardando,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa una descripción'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monto,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto corregido',
                  prefixText: 'Q ',
                ),
                validator: (v) => (leerImporte(v ?? '') ?? 0) <= 0
                    ? 'Ingresa un monto positivo con hasta 2 decimales'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoMovimiento>(
                isExpanded: true,
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: TipoMovimiento.ingreso,
                    child: Text('Ingreso'),
                  ),
                  DropdownMenuItem(
                    value: TipoMovimiento.gasto,
                    child: Text('Gasto'),
                  ),
                ],
                onChanged: _guardando || widget.movimiento.esRetiro
                    ? null
                    : (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AmbitoMovimiento>(
                isExpanded: true,
                initialValue: _ambito,
                decoration: const InputDecoration(labelText: 'Ámbito'),
                items: const [
                  DropdownMenuItem(
                    value: AmbitoMovimiento.empresa,
                    child: Text('Empresa'),
                  ),
                  DropdownMenuItem(
                    value: AmbitoMovimiento.personal,
                    child: Text('Personal'),
                  ),
                ],
                onChanged: _guardando || widget.movimiento.esRetiro
                    ? null
                    : (v) => setState(() => _ambito = v!),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                ),
                onPressed: _guardando
                    ? null
                    : () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDate: _fecha.isAfter(DateTime.now())
                              ? DateTime.now()
                              : _fecha,
                        );
                        if (fecha != null && mounted) {
                          setState(() => _fecha = fecha);
                        }
                      },
              ),
              categorias.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(categoriasProvider),
                  child: const Text('Reintentar categorías'),
                ),
                data: (lista) => DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    for (final c in lista.where(
                      (c) =>
                          !c.archivada || c.id == widget.movimiento.categoriaId,
                    ))
                      DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                  ],
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _categoria = v),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _motivo,
                enabled: !_guardando,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la corrección',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Explica por qué necesitas corregirlo'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _guardando || !categorias.hasValue ? null : _guardar,
                child: Text(_guardando ? 'Guardando...' : 'Guardar corrección'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
