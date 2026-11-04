import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/modelos/cierre_caja.dart';
import '../providers/caja_provider.dart';
import '../providers/operaciones_provider.dart';
import '../providers/historial_provider.dart';
import '../providers/trazabilidad_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/importes.dart';
import '../widgets/formato.dart';
import '../widgets/alerta_reserva.dart';
import 'movimiento_form_screen.dart';

class CierreFormScreen extends ConsumerStatefulWidget {
  const CierreFormScreen({super.key});
  @override
  ConsumerState<CierreFormScreen> createState() => _CierreFormScreenState();
}

class _CierreFormScreenState extends ConsumerState<CierreFormScreen> {
  final _form = GlobalKey<FormState>();
  final _contado = TextEditingController();
  final _nota = TextEditingController();
  late final _id = 'cierre-${DateTime.now().microsecondsSinceEpoch}';
  bool _guardando = false;
  @override
  void dispose() {
    _contado.dispose();
    _nota.dispose();
    super.dispose();
  }

  Future<void> _confirmar(Caja caja) async {
    if (_guardando || !_form.currentState!.validate()) return;
    final contado = leerImporte(_contado.text)!;
    final diferencia =
        (contado * 100).round() - (caja.efectivoTotal * 100).round();
    setState(() => _guardando = true);
    try {
      final acepta = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmar cierre'),
          content: Text(
            'Saldo esperado: ${dineroCentavos((caja.efectivoTotal * 100).round())}\nEfectivo contado: ${dineroCentavos((contado * 100).round())}\nDiferencia: ${dineroCentavos(diferencia)}\n\nLa caja quedará con el efectivo contado. La reserva se conserva.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmar cierre'),
            ),
          ],
        ),
      );
      if (acepta != true || !mounted) return;
      await ref
          .read(cierreRepositorioProvider)
          .confirmar(
            id: _id,
            esperado: caja.efectivoTotal,
            contado: contado,
            nota: _nota.text,
          );
      if (!mounted) return;
      ref.invalidate(cajaProvider);
      ref.invalidate(cierresProvider);
      ref.invalidate(historialProvider);
      ref.invalidate(cambiosProvider);
      Navigator.pop(context, true);
    } on SaldoCambioException catch (e) {
      if (!mounted) return;
      ref.invalidate(cajaProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el cierre. Intenta nuevamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(cajaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cerrar caja')),
      body: SuperficieCaja(
        child: estado.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(cajaProvider),
              child: const Text('No se pudo leer la caja. Reintentar'),
            ),
          ),
          data: (caja) {
            final contado = leerImporte(_contado.text);
            final diferencia = contado == null
                ? null
                : (contado * 100).round() - (caja.efectivoTotal * 100).round();
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Cuenta. Compara.\nCierra con claridad.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cuenta solo el efectivo del negocio. Si olvidaste registrar una operación, puedes hacerlo antes de confirmar.',
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo esperado en la app'),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dineroCentavos(
                                (caja.efectivoTotal * 100).round(),
                              ),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contado,
                    enabled: !_guardando,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Efectivo contado',
                      prefixText: 'Q ',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => leerImporte(v ?? '') == null
                        ? 'Ingresa un importe no negativo con hasta 2 decimales'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (diferencia != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diferencia == 0
                                  ? 'La caja coincide'
                                  : diferencia < 0
                                  ? 'Faltante de efectivo'
                                  : 'Sobrante de efectivo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CajaEstilo.tinta,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dineroCentavos(diferencia),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: diferencia < 0
                                    ? CajaEstilo.peligro
                                    : CajaEstilo.verde,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AlertaReserva(
                      caja: Caja(
                        efectivoTotal: contado!,
                        reservaInsumos: caja.reservaInsumos,
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: _nota,
                    enabled: !_guardando,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: diferencia != null && diferencia != 0
                          ? 'Explicación de la diferencia'
                          : 'Nota (opcional)',
                    ),
                    validator: (v) =>
                        diferencia != null &&
                            diferencia != 0 &&
                            (v == null || v.trim().isEmpty)
                        ? 'Explica el faltante o sobrante'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _guardando
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MovimientoFormScreen(),
                              ),
                            );
                            if (mounted) ref.invalidate(cajaProvider);
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar operación olvidada'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El cierre conserva un registro del ajuste; no crea una venta, gasto o retiro. Podrás seguir registrando operaciones después.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _guardando ? null : () => _confirmar(caja),
                    child: Text(_guardando ? 'Guardando...' : 'Revisar cierre'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
