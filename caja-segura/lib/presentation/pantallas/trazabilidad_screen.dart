import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trazabilidad_provider.dart';
import '../tema/caja_estilo.dart';
import '../widgets/formato.dart';

const _acciones = {
  'alta': 'Movimiento registrado',
  'retiro': 'Retiro confirmado',
  'correccion': 'Movimiento corregido',
  'categoria': 'Categoría corregida',
  'eliminacion': 'Movimiento eliminado',
  'restauracion': 'Eliminación deshecha',
  'ajuste_conciliado': 'Ajuste de movimiento conciliado',
  'cierre': 'Cierre de caja',
  'caja': 'Cambio manual de caja',
  'proteccion_migracion': 'Protección al actualizar',
};

class TrazabilidadScreen extends ConsumerWidget {
  const TrazabilidadScreen({super.key, this.movimientoId});
  final String? movimientoId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Trazabilidad')),
    body: SuperficieCaja(
      child: ref
          .watch(cambiosProvider(movimientoId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(cambiosProvider(movimientoId)),
                child: const Text('No se pudo cargar. Reintentar'),
              ),
            ),
            data: (lista) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Registro de cambios de solo lectura. Los motivos y valores anteriores se conservan aunque se elimine un movimiento no conciliado.',
                ),
                const SizedBox(height: 20),
                if (lista.isEmpty)
                  const Text(
                    'No hay cambios registrados desde que se activó la trazabilidad.',
                  ),
                for (final c in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _acciones[c.accion] ?? c.accion,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CajaEstilo.tinta,
                              ),
                            ),
                            Text(
                              fechaHora(c.fecha),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Text(c.motivo),
                            if (c.movimientoId != null)
                              Text(
                                'Movimiento: ${c.movimientoId}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (c.antes != null)
                              _Valores(titulo: 'Antes', datos: c.antes!),
                            if (c.despues != null)
                              _Valores(titulo: 'Después', datos: c.despues!),
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

class _Valores extends StatelessWidget {
  const _Valores({required this.titulo, required this.datos});
  final String titulo;
  final Map<String, dynamic> datos;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: CajaEstilo.tinta,
          ),
        ),
        if (datos['descripcion'] != null) Text(datos['descripcion'] as String),
        if (datos['monto_centavos'] != null)
          Text('Monto: ${dineroCentavos(datos['monto_centavos'] as int)}'),
        if (datos['tipo'] != null)
          Text(
            '${datos['tipo'] == 'ingreso' ? 'Ingreso' : 'Gasto'} · ${datos['ambito'] == 'empresa' ? 'Empresa' : 'Personal'}',
          ),
        if (datos['categoria_id'] != null)
          Text(
            'Categoría: ${datos['categoria_nombre'] ?? '#${datos['categoria_id']}'}',
          ),
        if (datos['tipo'] != null && datos['categoria_id'] == null)
          const Text('Sin categoría'),
        if (datos['efectivo_centavos'] != null)
          Text('Caja: ${dineroCentavos(datos['efectivo_centavos'] as int)}'),
        if (datos['reserva_centavos'] != null)
          Text('Reserva: ${dineroCentavos(datos['reserva_centavos'] as int)}'),
        if (datos['delta_centavos'] != null)
          Text(
            'Cambio de caja: ${dineroCentavos(datos['delta_centavos'] as int)}',
          ),
        if (datos['fecha'] != null)
          Text(
            'Fecha: ${fechaHora(DateTime.fromMillisecondsSinceEpoch(datos['fecha'] as int))}',
          ),
      ],
    ),
  );
}

class MovimientosCierreScreen extends ConsumerWidget {
  const MovimientosCierreScreen({super.key, required this.cierreId});
  final String cierreId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Movimientos del cierre')),
    body: SuperficieCaja(
      child: ref
          .watch(instantaneasCierreProvider(cierreId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(instantaneasCierreProvider(cierreId)),
                child: const Text('Reintentar movimientos'),
              ),
            ),
            data: (lista) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  lista.any((f) => f['capturada_en_migracion'] == true)
                      ? 'Protección al actualizar: estas copias conservan los movimientos existentes durante la migración. La versión anterior no guardaba qué movimientos formaban parte del cierre; no son una reconstrucción de sus valores originales.'
                      : 'Estos son los valores conservados al confirmar el cierre. No cambian aunque después se registren ajustes.',
                ),
                const SizedBox(height: 16),
                if (lista.isEmpty)
                  const Text(
                    'Este cierre no tiene instantáneas disponibles. Los cierres de versiones anteriores solo se pudieron proteger de forma conservadora al actualizar.',
                  ),
                for (final fila in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _Valores(
                          titulo: 'Movimiento protegido',
                          datos: fila,
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
