import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/caja.dart';
import '../providers/caja_provider.dart';
import 'historial_screen.dart';
import 'retiro_personal_screen.dart';

class CajaNegocioScreen extends ConsumerWidget {
  const CajaNegocioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cajaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Caja del Negocio')),
      // Los 4 estados: cargando, error (con Reintentar), vacío y datos.
      body: estado.when(
        // Al reintentar, mostrar otra vez el indicador de carga.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _EstadoError(),
        data: (caja) {
          if (caja.efectivoTotal <= 0) return const _EstadoVacio();

          return _ResumenCaja(caja: caja);
        },
      ),
    );
  }
}

/// Estado de error: mensaje entendible y un botón para volver a intentar.
class _EstadoError extends ConsumerWidget {
  const _EstadoError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('No se pudo cargar la caja.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              // Descarta el error y vuelve a pedir la caja.
              onPressed: () => ref.invalidate(cajaProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: la caja todavía no tiene efectivo registrado.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Todavía no hay efectivo registrado en la caja.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Ver historial'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado con datos: los montos de la caja y las acciones principales.
class _ResumenCaja extends ConsumerWidget {
  const _ResumenCaja({required this.caja});

  final Caja caja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
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
              if (context.mounted) ref.invalidate(cajaProvider);
            },
            child: const Text('Retirar mi sueldo'),
          ),
        ],
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
