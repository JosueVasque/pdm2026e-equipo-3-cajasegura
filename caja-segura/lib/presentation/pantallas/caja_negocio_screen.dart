import 'package:flutter/material.dart';
import '../../data/repositorios/caja_repositorio.dart';
import '../../domain/modelos/caja.dart';
import '../widgets/carga_datos.dart';
import 'historial_screen.dart';
import 'retiro_personal_screen.dart';

class CajaNegocioScreen extends StatefulWidget {
  const CajaNegocioScreen({super.key, this.repositorio});

  final CajaRepositorio? repositorio;

  @override
  State<CajaNegocioScreen> createState() => _CajaNegocioScreenState();
}

class _CajaNegocioScreenState extends State<CajaNegocioScreen> {
  late final _repositorio = widget.repositorio ?? CajaRepositorio();
  late Future<Caja> _caja = _repositorio.obtenerCaja();

  void _recargar() {
    setState(() {
      _caja = _repositorio.obtenerCaja();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caja del Negocio')),
      body: CargaDatos<Caja>(
        future: _caja,
        onReintentar: _recargar,
        builder: (caja) => Padding(
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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.history),
                label: const Text('Ver historial'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistorialScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RetiroPersonalScreen(caja: caja),
                    ),
                  );
                  if (mounted) _recargar();
                },
                child: const Text('Retirar mi sueldo'),
              ),
            ],
          ),
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
