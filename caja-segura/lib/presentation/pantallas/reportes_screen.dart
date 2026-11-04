import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/casos_uso/generar_reporte.dart';
import '../../domain/modelos/movimiento.dart';
import '../providers/categoria_provider.dart';
import '../providers/historial_provider.dart';
import '../providers/reportes_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/resumen_retiros.dart';

String _quetzales(int centavos) =>
    '${centavos < 0 ? '-' : ''}Q${(centavos.abs() / 100).toStringAsFixed(2)}';
String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
const _periodos = {
  PeriodoReporte.hoy: 'Hoy',
  PeriodoReporte.semana: 'Esta semana',
  PeriodoReporte.mes: 'Este mes',
  PeriodoReporte.todo: 'Todo el historial',
  PeriodoReporte.personalizado: 'Elegir fechas',
};

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  void _recargar(WidgetRef ref) {
    ref.invalidate(historialProvider);
    ref.invalidate(categoriasProvider);
    ref.invalidate(relojReportesProvider);
  }

  Future<void> _periodo(
    BuildContext context,
    WidgetRef ref,
    PeriodoReporte? periodo,
  ) async {
    if (periodo == null) return;
    final acciones = ref.read(filtroReporteProvider.notifier);
    if (periodo != PeriodoReporte.personalizado) {
      acciones.periodo(periodo);
      return;
    }
    final ahora = ref.read(relojReportesProvider)();
    final actual = ref.read(rangoReporteProvider);
    final fechas = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: ahora,
      initialDateRange: actual == null
          ? null
          : DateTimeRange(start: actual.inicio, end: actual.fin),
      helpText: 'Selecciona el período',
      saveText: 'Aplicar',
    );
    if (fechas != null && context.mounted) {
      acciones.periodo(periodo, rango: RangoReporte(fechas.start, fechas.end));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroReporteProvider);
    final rango = ref.watch(rangoReporteProvider);
    final reporte = ref.watch(reporteProvider);
    final retiros = ref.watch(vistaRetirosProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar reportes',
            icon: const Icon(Icons.refresh_rounded, color: CajaEstilo.menta),
            onPressed: () => _recargar(ref),
          ),
        ],
      ),
      body: SuperficieCaja(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: IconoCaja(
                Icons.bar_chart_rounded,
                oscuro: true,
                tamano: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              retiros
                  ? 'Tu sueldo,\ncon claridad.'
                  : 'Entiende cómo se\nmueve tu dinero.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Elige un período y descubre de dónde viene y a dónde va.',
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Movimientos')),
                ButtonSegment(value: true, label: Text('Retiros de sueldo')),
              ],
              selected: {retiros},
              onSelectionChanged: (v) =>
                  ref.read(vistaRetirosProvider.notifier).seleccionar(v.first),
            ),
            const SizedBox(height: 20),
            _Selector(
              titulo: 'Período',
              child: DropdownButton<PeriodoReporte>(
                key: const ValueKey('periodo-reporte'),
                value: filtro.periodo,
                isExpanded: true,
                items: [
                  for (final p in _periodos.entries)
                    DropdownMenuItem(value: p.key, child: Text(p.value)),
                ],
                onChanged: (v) => _periodo(context, ref, v),
              ),
            ),
            const SizedBox(height: 12),
            if (!retiros)
              _Selector(
                titulo: 'Ámbito',
                child: DropdownButton<AmbitoMovimiento>(
                  key: const ValueKey('ambito-reporte'),
                  value: filtro.ambito,
                  isExpanded: true,
                  hint: const Text('Empresa + personal'),
                  items: const [
                    DropdownMenuItem(
                      value: AmbitoMovimiento.empresa,
                      child: Text('Empresa'),
                    ),
                    DropdownMenuItem(
                      value: AmbitoMovimiento.personal,
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem<AmbitoMovimiento>(
                      value: null,
                      child: Text('Empresa + personal'),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(filtroReporteProvider.notifier).ambito(v),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              rango == null
                  ? 'Todos los movimientos registrados'
                  : '${_fecha(rango.inicio)} – ${_fecha(rango.fin)} · Fechas incluidas',
              style: const TextStyle(fontSize: 12),
            ),
            if (filtro.periodo == PeriodoReporte.personalizado)
              TextButton(
                onPressed: () =>
                    _periodo(context, ref, PeriodoReporte.personalizado),
                child: const Text('Cambiar fechas'),
              ),
            const SizedBox(height: 24),
            if (retiros)
              const ResumenRetirosSeccion()
            else
              reporte.when(
                skipLoadingOnRefresh: false,
                loading: () => const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Column(
                  children: [
                    const Text('No se pudieron cargar los reportes.'),
                    TextButton.icon(
                      onPressed: () => _recargar(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (datos) => _ContenidoReporte(reporte: datos),
              ),
          ],
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({required this.titulo, required this.child});
  final String titulo;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 11)),
          DropdownButtonHideUnderline(child: child),
        ],
      ),
    ),
  );
}

class _ContenidoReporte extends StatelessWidget {
  const _ContenidoReporte({required this.reporte});
  final ReporteMovimientos reporte;
  @override
  Widget build(BuildContext context) {
    if (reporte.movimientos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              IconoCaja(Icons.receipt_long_outlined),
              SizedBox(height: 16),
              Text(
                'No hay movimientos en este período',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: CajaEstilo.tinta,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Prueba otras fechas o registra un movimiento.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
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
                'Balance de movimientos',
                style: TextStyle(
                  color: CajaEstilo.tinta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _quetzales(reporte.balanceCentavos),
                  style: const TextStyle(
                    fontSize: 34,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                    color: CajaEstilo.tinta,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${reporte.movimientos.length} movimientos · Ingresos menos gastos',
                style: const TextStyle(fontSize: 12, color: CajaEstilo.tinta),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Importe(
                  'Ingresos',
                  reporte.ingresosCentavos,
                  CajaEstilo.verde,
                ),
                const Divider(height: 28),
                _Importe('Gastos', reporte.gastosCentavos, CajaEstilo.peligro),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Este balance no es la ganancia ni el saldo de caja. Incluye los retiros registrados como gastos; excluye el saldo inicial y los ajustes directos de caja.',
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 28),
        Text('Por categoría', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Cada barra indica la proporción de los gastos del período.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        for (final c in reporte.categorias) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.nombre}${c.archivada ? ' (archivada)' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CajaEstilo.tinta,
                    ),
                  ),
                  Text(
                    '${c.cantidad} movimientos',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  _Importe('Ingresos', c.ingresosCentavos, CajaEstilo.verde),
                  const SizedBox(height: 8),
                  _Importe('Gastos', c.gastosCentavos, CajaEstilo.peligro),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: reporte.gastosCentavos == 0
                          ? 0
                          : c.gastosCentavos / reporte.gastosCentavos,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(reporte.gastosCentavos == 0 ? 0 : c.gastosCentavos * 100 / reporte.gastosCentavos).toStringAsFixed(1)}% de los gastos',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Importe extends StatelessWidget {
  const _Importe(this.etiqueta, this.centavos, this.color);
  final String etiqueta;
  final int centavos;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(etiqueta)),
      const SizedBox(width: 12),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _quetzales(centavos),
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    ],
  );
}
