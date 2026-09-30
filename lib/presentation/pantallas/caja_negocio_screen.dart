import 'package:flutter/material.dart';
import '../../data/repositorios/caja_repositorio.dart';
import 'retiro_personal_screen.dart';

class CajaNegocioScreen extends StatelessWidget {
  const CajaNegocioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caja = CajaRepositorio().obtenerCaja();

    return Scaffold(
      appBar: AppBar(title: const Text('Caja del Negocio')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TarjetaMonto(
              titulo: 'Caja disponible',
              monto: caja.efectivoTotal,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _TarjetaMonto(
              titulo: 'Reserva protegida para insumos',
              monto: caja.reservaInsumos,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _TarjetaMonto(
              titulo: 'Disponible para tu sueldo',
              monto: caja.disponibleParaSueldo,
              color: Colors.green,
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RetiroPersonalScreen(caja: caja),
                  ),
                );
              },
              child: const Text('Retirar mi sueldo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMonto extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;

  const _TarjetaMonto({
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Q${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
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