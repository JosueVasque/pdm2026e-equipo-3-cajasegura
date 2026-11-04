import 'package:flutter/material.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/casos_uso/evaluar_reserva.dart';
import '../tema/caja_estilo.dart';

class AlertaReserva extends StatelessWidget {
  const AlertaReserva({super.key, required this.caja});
  final Caja caja;
  @override
  Widget build(BuildContext context) {
    final evaluacion = evaluarReserva(caja);
    if (evaluacion.estado == EstadoReserva.protegida) {
      return const SizedBox.shrink();
    }
    final insuficiente = evaluacion.estado == EstadoReserva.insuficiente;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: insuficiente
              ? const Color(0xFFFFE9E5)
              : const Color(0xFFFFF2D9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: insuficiente
                  ? CajaEstilo.peligro
                  : const Color(0xFF896016),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insuficiente
                        ? 'Reserva sin cubrir'
                        : 'Sin margen para retiros',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CajaEstilo.tinta,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insuficiente
                        ? 'Faltan Q${(evaluacion.faltanteCentavos / 100).toStringAsFixed(2)} para cubrir tus insumos. Evita retirar sueldo hasta reponer la reserva.'
                        : 'El efectivo alcanza justo para tus insumos. Un gasto adicional utilizará la reserva.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CajaEstilo.tinta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
