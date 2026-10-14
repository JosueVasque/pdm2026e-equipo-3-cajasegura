import 'package:flutter/material.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/casos_uso/verificar_retiro_seguro.dart';

class ImpactoCajaScreen extends StatelessWidget {
  final Caja caja;
  final ResultadoRetiro resultado;

  const ImpactoCajaScreen({
    super.key,
    required this.caja,
    required this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    final seguro = resultado.esSeguro;
    final color = seguro ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Impacto en Caja')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              seguro ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 80,
              color: color,
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
            _Fila('Caja actual', caja.efectivoTotal),
            _Fila('Retiro', -resultado.montoRetiro),
            const Divider(),
            _Fila('Caja restante', resultado.cajaRestante, destacado: true),
            _Fila('Reserva de insumos', resultado.reservaInsumos),
            const Spacer(),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cambiar monto'),
            ),
          ],
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
      fontSize: destacado ? 18 : 16,
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
    );
    final signo = monto < 0 ? '-' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: estilo),
          Text('${signo}Q${monto.abs().toStringAsFixed(2)}', style: estilo),
        ],
      ),
    );
  }
}