import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/operaciones_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/formato.dart';
import 'cierre_form_screen.dart';
import 'trazabilidad_screen.dart';

class CierresScreen extends ConsumerWidget {
  const CierresScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cierres = ref.watch(cierresProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de caja')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo-cierre',
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Cerrar caja'),
        onPressed: () async {
          final cerrado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CierreFormScreen()),
          );
          if (cerrado == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cierre guardado y caja conciliada'),
              ),
            );
          }
        },
      ),
      body: SuperficieCaja(
        child: cierres.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(cierresProvider),
              child: const Text(
                'No se pudieron cargar los cierres. Reintentar',
              ),
            ),
          ),
          data: (lista) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
            children: [
              Text(
                'Tu efectivo,\nsin dudas.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Compara el efectivo real con el saldo de la app. Cada cierre conserva su fecha, diferencia y explicación.',
              ),
              const SizedBox(height: 24),
              if (lista.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no hay cierres. Al finalizar tu jornada, cuenta el efectivo y registra el primero.',
                    ),
                  ),
                ),
              for (final cierre in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fechaHora(cierre.fecha),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: CajaEstilo.tinta,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Esperado: ${dineroCentavos(cierre.esperadoCentavos)}',
                          ),
                          Text(
                            'Contado: ${dineroCentavos(cierre.contadoCentavos)}',
                          ),
                          Text(
                            '${cierre.diferenciaCentavos == 0
                                ? 'Sin diferencia'
                                : cierre.diferenciaCentavos < 0
                                ? 'Faltante'
                                : 'Sobrante'}: ${dineroCentavos(cierre.diferenciaCentavos)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cierre.diferenciaCentavos < 0
                                  ? CajaEstilo.peligro
                                  : CajaEstilo.verde,
                            ),
                          ),
                          Text(
                            'Reserva conservada: ${dineroCentavos(cierre.reservaCentavos)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovimientosCierreScreen(
                                  cierreId: cierre.id,
                                ),
                              ),
                            ),
                            child: const Text('Ver movimientos protegidos'),
                          ),
                          if (cierre.nota.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(cierre.nota),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
