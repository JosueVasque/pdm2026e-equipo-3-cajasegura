import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/casos_uso/generar_reporte.dart';
import '../providers/historial_provider.dart';
import '../tema/caja_estilo.dart';

const _periodos = {
  PeriodoReporte.todo: 'Todo el historial',
  PeriodoReporte.hoy: 'Hoy',
  PeriodoReporte.semana: 'Esta semana',
  PeriodoReporte.mes: 'Este mes',
  PeriodoReporte.personalizado: 'Elegir fechas',
};
String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

class FiltroFechasHistorial extends ConsumerWidget {
  const FiltroFechasHistorial({super.key});

  Future<void> _seleccionar(
    BuildContext context,
    WidgetRef ref,
    PeriodoReporte? periodo,
  ) async {
    if (periodo == null) return;
    final acciones = ref.read(filtroHistorialProvider.notifier);
    if (periodo != PeriodoReporte.personalizado) {
      acciones.seleccionarPeriodo(periodo);
      return;
    }
    final ahora = ref.read(relojHistorialProvider)();
    final rango = ref.read(rangoHistorialProvider);
    final fechas = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: ahora,
      initialDateRange: rango == null
          ? null
          : DateTimeRange(start: rango.inicio, end: rango.fin),
      helpText: 'Fechas del historial',
      saveText: 'Aplicar',
    );
    if (fechas != null && context.mounted) {
      acciones.seleccionarPeriodo(
        periodo,
        rango: RangoReporte(fechas.start, fechas.end),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroHistorialProvider);
    final rango = ref.watch(rangoHistorialProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: CajaEstilo.verde,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PeriodoReporte>(
                        key: const ValueKey('periodo-historial'),
                        value: filtro.periodo,
                        isExpanded: true,
                        items: [
                          for (final periodo in _periodos.entries)
                            DropdownMenuItem(
                              value: periodo.key,
                              child: Text(
                                periodo.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        onChanged: (v) => _seleccionar(context, ref, v),
                      ),
                    ),
                  ),
                  if (filtro.activo)
                    IconButton(
                      tooltip: 'Limpiar filtros',
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                      onPressed: () =>
                          ref.read(filtroHistorialProvider.notifier).limpiar(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rango == null
                ? 'Sin límite de fechas'
                : '${_fecha(rango.inicio)} – ${_fecha(rango.fin)} · Fechas incluidas',
            style: const TextStyle(fontSize: 11),
          ),
          if (filtro.periodo == PeriodoReporte.personalizado)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _seleccionar(context, ref, PeriodoReporte.personalizado),
                child: const Text('Cambiar fechas'),
              ),
            ),
        ],
      ),
    );
  }
}
