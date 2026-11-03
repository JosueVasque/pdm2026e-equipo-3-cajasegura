import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/modelos/caja.dart';
import '../providers/caja_provider.dart';
import '../providers/navegacion_provider.dart';
import 'retiro_personal_screen.dart';
import 'caja_form_screen.dart';
import '../tema/caja_estilo.dart';
import '../widgets/alerta_reserva.dart';
import 'frecuentes_screen.dart';
import 'cierres_screen.dart';

class CajaNegocioScreen extends ConsumerWidget {
  const CajaNegocioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cajaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            IconoCaja(Icons.shield_outlined, oscuro: true, tamano: 36),
            SizedBox(width: 10),
            Text('CajaSegura'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_horiz, color: CajaEstilo.menta),
            onSelected: (v) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => v == 'frecuentes'
                    ? const FrecuentesScreen()
                    : const CierresScreen(),
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'frecuentes',
                child: Text('Movimientos frecuentes'),
              ),
              PopupMenuItem(value: 'cierres', child: Text('Cierre de caja')),
            ],
          ),
          if (estado.hasValue)
            IconButton(
              tooltip: 'Editar caja y reserva',
              icon: const Icon(Icons.tune_rounded, color: CajaEstilo.menta),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CajaFormScreen(caja: estado.requireValue),
                ),
              ),
            ),
        ],
      ),
      // Los 4 estados: cargando, error (con Reintentar), vacío y datos.
      body: SuperficieCaja(
        child: estado.when(
          // Al reintentar, mostrar otra vez el indicador de carga.
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _EstadoError(),
          data: (caja) {
            if (caja.efectivoTotal <= 0) return _EstadoVacio(caja: caja);

            return _ResumenCaja(caja: caja);
          },
        ),
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
class _EstadoVacio extends ConsumerWidget {
  const _EstadoVacio({required this.caja});
  final Caja caja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlertaReserva(caja: caja),
            const Icon(Icons.savings_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Todavía no hay efectivo registrado en la caja.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.read(navegacionProvider.notifier).cambiar(1),
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
    final proporcion = (caja.reservaInsumos / caja.efectivoTotal).clamp(
      0.0,
      1.0,
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AlertaReserva(caja: caja),
                const Text(
                  'TU CAJA, BAJO CONTROL',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: CajaEstilo.gris,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu negocio crece.\nTu tranquilidad también.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Separa tu sueldo. Protege lo que sigue.'),
                const SizedBox(height: 24),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: CajaEstilo.gradiente,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -25,
                        child: ExcludeSemantics(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                                width: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Caja disponible',
                                  style: TextStyle(
                                    color: CajaEstilo.tinta,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: CajaEstilo.tinta,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Q${caja.efectivoTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  color: CajaEstilo.tinta,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 15,
                                  color: CajaEstilo.tinta,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Caja del Negocio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CajaEstilo.tinta,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'GTQ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: CajaEstilo.tinta,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, limites) {
                    final tarjetas = [
                      _TarjetaMonto(
                        titulo: 'Reserva protegida para insumos',
                        monto: caja.reservaInsumos,
                        icono: Icons.shield_outlined,
                        oscura: true,
                      ),
                      _TarjetaMonto(
                        titulo: 'Disponible para tu sueldo',
                        monto: caja.disponibleParaSueldo,
                        icono: Icons.savings_outlined,
                      ),
                    ];
                    if (limites.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                      return Column(
                        children: [
                          tarjetas[0],
                          const SizedBox(height: 12),
                          tarjetas[1],
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tarjetas[0]),
                          const SizedBox(width: 12),
                          Expanded(child: tarjetas[1]),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: CajaEstilo.verde,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caja.reservaInsumos > caja.efectivoTotal
                            ? 'Tu caja aún no cubre la reserva'
                            : 'Tu reserva tiene su lugar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CajaEstilo.tinta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: proporcion,
                    minHeight: 7,
                    color: CajaEstilo.verde,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(proporcion * 100).round()}% de tu efectivo está destinado a insumos',
                  style: const TextStyle(fontSize: 11, color: CajaEstilo.gris),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  icon: const Icon(Icons.north_east_rounded, size: 19),
                  label: const Text('Retirar mi sueldo'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RetiroPersonalScreen(caja: caja),
                      ),
                    );
                    if (context.mounted) ref.invalidate(cajaProvider);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Ver historial'),
                  onPressed: () =>
                      ref.read(navegacionProvider.notifier).cambiar(1),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Movimientos frecuentes'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FrecuentesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Cierre de caja'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CierresScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaMonto extends StatelessWidget {
  final String titulo;
  final double monto;
  final IconData icono;
  final bool oscura;

  const _TarjetaMonto({
    required this.titulo,
    required this.monto,
    required this.icono,
    this.oscura = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = oscura ? Colors.white : CajaEstilo.tinta;
    return Card(
      color: oscura ? CajaEstilo.tinta : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icono,
              color: oscura ? CajaEstilo.menta : CajaEstilo.verde,
              size: 22,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: color.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Q${monto.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
