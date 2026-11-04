import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/historial_provider.dart';
import '../providers/reportes_provider.dart';
import '../tema/caja_estilo.dart';
import 'formato.dart';

class ResumenRetirosSeccion extends ConsumerWidget {
  const ResumenRetirosSeccion({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(resumenRetirosProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => TextButton(
          onPressed: () => ref.invalidate(historialProvider),
          child: const Text('No se pudieron cargar los retiros. Reintentar'),
        ),
        data: (resumen) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: CajaEstilo.gradiente,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total retirado como sueldo',
                    style: TextStyle(
                      color: CajaEstilo.tinta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dineroCentavos(resumen.totalCentavos),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: CajaEstilo.tinta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${resumen.retiros.length} ${resumen.retiros.length == 1 ? 'retiro' : 'retiros'} en el período',
                    style: const TextStyle(color: CajaEstilo.tinta),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solo incluye salidas de sueldo identificadas como retiro. No suma de nuevo su ingreso personal ni los ajustes de conciliación.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            Text(
              'Retiros del período',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (resumen.retiros.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay retiros de sueldo en este período.'),
                ),
              ),
            for (final m in resumen.retiros)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: const IconoCaja(Icons.north_east_rounded),
                    title: Text(m.descripcion),
                    subtitle: Text(
                      '${fechaHora(m.fecha)}\n${dineroCentavos((m.monto * 100).round())}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
