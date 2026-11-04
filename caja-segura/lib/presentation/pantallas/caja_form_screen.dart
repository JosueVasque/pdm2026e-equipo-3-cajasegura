import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/caja.dart';
import '../providers/caja_provider.dart';
import '../widgets/importes.dart';
import '../tema/caja_estilo.dart';
import '../providers/trazabilidad_provider.dart';

class CajaFormScreen extends ConsumerStatefulWidget {
  const CajaFormScreen({super.key, required this.caja});
  final Caja caja;

  @override
  ConsumerState<CajaFormScreen> createState() => _CajaFormScreenState();
}

class _CajaFormScreenState extends ConsumerState<CajaFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _efectivo = TextEditingController(
    text: widget.caja.efectivoTotal.toStringAsFixed(2),
  );
  late final _reserva = TextEditingController(
    text: widget.caja.reservaInsumos.toStringAsFixed(2),
  );
  bool _guardando = false;
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _efectivo.dispose();
    _reserva.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(cajaRepositorioProvider)
          .guardarCajaConMotivo(
            Caja(
              efectivoTotal: leerImporte(_efectivo.text)!,
              reservaInsumos: leerImporte(_reserva.text)!,
            ),
            _motivo.text,
          );
      if (!mounted) return;
      ref.invalidate(cajaProvider);
      ref.invalidate(cambiosProvider);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la caja. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar caja y reserva')),
    body: SuperficieCaja(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const IconoCaja(
              Icons.account_balance_wallet_outlined,
              oscuro: true,
              tamano: 56,
            ),
            const SizedBox(height: 20),
            Text(
              'Tus números, al día.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ajusta el efectivo al dinero real del negocio. Este ajuste reemplaza el saldo actual; no registra un ingreso ni un gasto. La reserva es una meta protegida y puede superar el efectivo disponible.',
            ),
            const SizedBox(height: 24),
            for (final campo in [
              (_efectivo, 'Efectivo total'),
              (_reserva, 'Reserva para insumos'),
            ]) ...[
              TextFormField(
                controller: campo.$1,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: campo.$2,
                  prefixText: 'Q ',
                ),
                validator: (v) => leerImporte(v ?? '') == null
                    ? 'Ingresa un importe no negativo con hasta 2 decimales'
                    : null,
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _motivo,
              enabled: !_guardando,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo del cambio de caja',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Explica el cambio de saldo o reserva'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('guardar-caja'),
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando...' : 'Guardar caja'),
            ),
          ],
        ),
      ),
    ),
  );
}
