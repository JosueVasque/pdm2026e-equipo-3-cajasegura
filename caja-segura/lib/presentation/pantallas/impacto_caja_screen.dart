import 'package:flutter/material.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/casos_uso/verificar_retiro_seguro.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/caja_provider.dart';
import '../providers/historial_provider.dart';
import '../tema/caja_estilo.dart';

class ImpactoCajaScreen extends ConsumerStatefulWidget {
  final Caja caja;
  final ResultadoRetiro resultado;

  const ImpactoCajaScreen({
    super.key,
    required this.caja,
    required this.resultado,
  });

  @override
  ConsumerState<ImpactoCajaScreen> createState() => _ImpactoCajaScreenState();
}

class _ImpactoCajaScreenState extends ConsumerState<ImpactoCajaScreen> {
  bool _guardando = false;
  late final String _id = 'retiro-${DateTime.now().microsecondsSinceEpoch}';
  Caja get caja => widget.caja;
  ResultadoRetiro get resultado => widget.resultado;

  Future<void> _confirmar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(movimientoRepositorioProvider)
          .confirmarRetiro(resultado.montoRetiro, _id);
      if (!mounted) return;
      ref.invalidate(cajaProvider);
      ref.invalidate(historialProvider);
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiro confirmado y registrado')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo confirmar el retiro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seguro = resultado.esSeguro;
    final color = seguro ? CajaEstilo.verde : CajaEstilo.peligro;

    return Scaffold(
      appBar: AppBar(title: const Text('Impacto en Caja')),
      body: SuperficieCaja(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      seguro
                          ? Icons.verified_user_outlined
                          : Icons.warning_amber_rounded,
                      size: 52,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  seguro ? 'Retiro seguro' : 'Retiro no recomendado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  seguro
                      ? 'Tu reserva de insumos queda protegida.'
                      : 'Este retiro deja la caja por debajo de la reserva para insumos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _Fila('Caja actual', caja.efectivoTotal),
                        _Fila('Retiro', -resultado.montoRetiro),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        _Fila(
                          'Caja restante',
                          resultado.cajaRestante,
                          destacado: true,
                        ),
                        _Fila('Reserva de insumos', resultado.reservaInsumos),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (seguro) ...[
                  const Text(
                    'Al confirmar se descontará de la caja y se registrará como gasto de empresa.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _guardando ? null : _confirmar,
                    child: Text(
                      _guardando ? 'Confirmando...' : 'Confirmar retiro',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _guardando ? null : () => Navigator.pop(context),
                  child: const Text('Cambiar monto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final double monto;
  final bool destacado;

  const _Fila(this.etiqueta, this.monto, {this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 17 : 14,
      color: CajaEstilo.tinta,
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
    );
    final signo = monto < 0 ? '-' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${signo}Q${monto.abs().toStringAsFixed(2)}',
                style: estilo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
