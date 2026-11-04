import '../modelos/caja.dart';

enum EstadoReserva { protegida, sinMargen, insuficiente }

class EvaluacionReserva {
  const EvaluacionReserva(this.estado, this.faltanteCentavos);
  final EstadoReserva estado;
  final int faltanteCentavos;
}

EvaluacionReserva evaluarReserva(Caja caja) {
  final saldo = (caja.efectivoTotal * 100).round();
  final reserva = (caja.reservaInsumos * 100).round();
  return EvaluacionReserva(
    saldo < reserva
        ? EstadoReserva.insuficiente
        : saldo == reserva && reserva > 0
        ? EstadoReserva.sinMargen
        : EstadoReserva.protegida,
    saldo < reserva ? reserva - saldo : 0,
  );
}

/// El gasto es posible, pero el usuario debe reconocer su impacto en la reserva.
class ReservaRequiereConfirmacion implements Exception {
  const ReservaRequiereConfirmacion(this.faltanteCentavos);
  final int faltanteCentavos;
}
