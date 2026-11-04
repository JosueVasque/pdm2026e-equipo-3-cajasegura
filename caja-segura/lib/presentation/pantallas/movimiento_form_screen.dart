import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/movimiento.dart';
import '../../domain/modelos/movimiento_frecuente.dart';
import '../providers/operaciones_provider.dart';
import '../providers/caja_provider.dart';
import '../providers/categoria_provider.dart';
import '../providers/historial_provider.dart';
import '../widgets/importes.dart';
import '../tema/caja_estilo.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../providers/trazabilidad_provider.dart';
import 'corregir_movimiento_screen.dart';
import 'trazabilidad_screen.dart';

/// Un movimiento existente permite reclasificarlo sin alterar su importe.
class MovimientoFormScreen extends ConsumerStatefulWidget {
  const MovimientoFormScreen({
    super.key,
    this.movimiento,
    this.frecuente,
    this.configurarFrecuente = false,
  });
  final Movimiento? movimiento;
  final MovimientoFrecuente? frecuente;
  final bool configurarFrecuente;

  @override
  ConsumerState<MovimientoFormScreen> createState() =>
      _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends ConsumerState<MovimientoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  late final _descripcion = TextEditingController(
    text: widget.frecuente?.descripcion ?? '',
  );
  late final _monto = TextEditingController(
    text: widget.frecuente?.monto.toStringAsFixed(2) ?? '',
  );
  late final String _id = 'mov-${DateTime.now().microsecondsSinceEpoch}';
  late TipoMovimiento _tipo = widget.frecuente?.tipo ?? TipoMovimiento.ingreso;
  late AmbitoMovimiento _ambito =
      widget.frecuente?.ambito ?? AmbitoMovimiento.empresa;
  DateTime _fecha = DateTime.now();
  late int? _categoriaId =
      widget.movimiento?.categoriaId ?? widget.frecuente?.categoriaId;
  bool _guardando = false;
  bool get _edicion => widget.movimiento != null;

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
    try {
      final categorias = ref.read(categoriasProvider).requireValue;
      final categoriaId =
          !_edicion &&
              !categorias.any((c) => c.id == _categoriaId && !c.archivada)
          ? null
          : _categoriaId;
      if (widget.configurarFrecuente) {
        await ref
            .read(frecuenteRepositorioProvider)
            .guardar(
              MovimientoFrecuente(
                id: widget.frecuente?.id,
                descripcion: _descripcion.text.trim(),
                monto: leerImporte(_monto.text)!,
                tipo: _tipo,
                ambito: _ambito,
                categoriaId: categoriaId,
              ),
            );
        if (!mounted) return;
        ref.invalidate(frecuentesProvider);
        Navigator.pop(context, true);
        return;
      }
      final repo = ref.read(movimientoRepositorioProvider);
      if (_edicion) {
        final anterior = widget.movimiento!;
        await repo.actualizarMovimiento(
          anterior,
          Movimiento(
            id: anterior.id,
            descripcion: anterior.descripcion,
            monto: anterior.monto,
            tipo: anterior.tipo,
            ambito: anterior.ambito,
            fecha: anterior.fecha,
            categoriaId: _categoriaId,
            impactoCajaCentavos: anterior.impactoCajaCentavos,
            esRetiro: anterior.esRetiro,
          ),
          _motivo.text,
        );
      } else {
        final movimiento = Movimiento(
          id: _id,
          descripcion: _descripcion.text.trim(),
          monto: leerImporte(_monto.text)!,
          tipo: _tipo,
          ambito: _ambito,
          fecha: _fecha,
          categoriaId: categoriaId,
        );
        try {
          await repo.registrarMovimientoConReserva(movimiento);
        } on ReservaRequiereConfirmacion catch (alerta) {
          if (!mounted) return;
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: CajaEstilo.peligro,
              ),
              title: const Text('Este gasto utiliza tu reserva'),
              content: Text(
                'Después de este gasto faltarán Q${(alerta.faltanteCentavos / 100).toStringAsFixed(2)} para cubrir tus insumos. ¿Deseas registrarlo de todos modos?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Registrar gasto'),
                ),
              ],
            ),
          );
          if (confirmar != true || !mounted) return;
          await repo.registrarMovimientoConReserva(
            movimiento,
            autorizarReserva: true,
          );
        }
      }
      if (!mounted) return;
      ref.invalidate(historialProvider);
      ref.invalidate(cajaProvider);
      ref.invalidate(cambiosProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el movimiento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(categoriasProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.configurarFrecuente
              ? 'Configurar frecuente'
              : _edicion
              ? 'Asignar categoría'
              : 'Registrar movimiento',
        ),
      ),
      body: SuperficieCaja(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconoCaja(
                  _edicion ? Icons.grid_view_rounded : Icons.swap_vert_rounded,
                  oscuro: true,
                  tamano: 54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.configurarFrecuente
                    ? 'Tu próxima vez,\nmás fácil.'
                    : _edicion
                    ? 'Todo en su lugar.'
                    : 'Registra lo que mueve\ntu negocio.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (widget.configurarFrecuente)
                const Text(
                  'Guarda una plantilla para reutilizar sus datos. Guardarla no cambia la caja ni el historial.',
                ),
              if (widget.frecuente != null && !widget.configurarFrecuente)
                const Text(
                  'Revisa los datos de tu frecuente antes de registrar. La fecha es de hoy; una categoría archivada se reemplaza por Sin categoría.',
                ),
              if (_edicion)
                Text(
                  widget.movimiento!.descripcion,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!_edicion) ...[
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
                    labelText: 'Monto',
                    prefixText: 'Q ',
                  ),
                  validator: (v) {
                    final monto = leerImporte(v ?? '');
                    return monto == null || monto <= 0
                        ? 'Ingresa un monto positivo con hasta 2 decimales'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<TipoMovimiento>(
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
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _tipo = v!),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<AmbitoMovimiento>(
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
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _ambito = v!),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.configurarFrecuente
                      ? 'Al usar esta plantilla podrás cambiar el monto y los demás datos.'
                      : _ambito == AmbitoMovimiento.empresa
                      ? 'Este movimiento actualizará el efectivo del negocio. Los gastos pueden usar la reserva; no se permite saldo negativo.'
                      : 'Este movimiento es personal y no cambia la caja del negocio.',
                ),
                if (!widget.configurarFrecuente)
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                    ),
                    onPressed: _guardando
                        ? null
                        : () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fecha,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null && mounted) {
                              setState(() => _fecha = fecha);
                            }
                          },
                  ),
              ],
              const SizedBox(height: 16),
              categorias.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(categoriasProvider),
                  child: const Text(
                    'No se pudieron cargar categorías. Reintentar',
                  ),
                ),
                data: (lista) {
                  final opciones = lista
                      .where(
                        (c) =>
                            !c.archivada ||
                            c.id == widget.movimiento?.categoriaId,
                      )
                      .toList();
                  return DropdownButtonFormField<int>(
                    initialValue: opciones.any((c) => c.id == _categoriaId)
                        ? _categoriaId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Categoría (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Sin categoría'),
                      ),
                      for (final c in opciones)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.nombre}${c.archivada ? ' (archivada)' : ''}',
                          ),
                        ),
                    ],
                    onChanged: _guardando
                        ? null
                        : (v) => setState(() => _categoriaId = v),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_edicion) ...[
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
                      ? 'Explica la corrección'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _guardando || !categorias.hasValue ? null : _guardar,
                child: Text(
                  _guardando
                      ? 'Guardando...'
                      : widget.configurarFrecuente
                      ? 'Guardar frecuente'
                      : 'Guardar movimiento',
                ),
              ),
              if (_edicion) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () async {
                          final corregido = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CorregirMovimientoScreen(
                                movimiento: widget.movimiento!,
                              ),
                            ),
                          );
                          if (corregido == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                  child: const Text('Corregir monto y datos'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrazabilidadScreen(
                        movimientoId: widget.movimiento!.id,
                      ),
                    ),
                  ),
                  child: const Text('Ver trazabilidad'),
                ),
              ],
              if (_edicion && !widget.movimiento!.esRetiro) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovimientoFormScreen(
                              configurarFrecuente: true,
                              frecuente: MovimientoFrecuente(
                                descripcion: widget.movimiento!.descripcion,
                                monto: widget.movimiento!.monto,
                                tipo: widget.movimiento!.tipo,
                                ambito: widget.movimiento!.ambito,
                                categoriaId: _categoriaId,
                              ),
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Guardar como frecuente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
