import '../modelos/caja.dart';

class ResultadoRetiro {
  final bool esSeguro;
  final double montoRetiro;
  final double cajaRestante;
  final double reservaInsumos;

  const ResultadoRetiro({
    required this.esSeguro,
    required this.montoRetiro,
    required this.cajaRestante,
    required this.reservaInsumos,
  });
}

class VerificarRetiroSeguro {
  ResultadoRetiro call(Caja caja, double monto) {
    final restante = caja.efectivoTotal - monto;
    final seguro = monto > 0 && restante >= caja.reservaInsumos;

    return ResultadoRetiro(
      esSeguro: seguro,
      montoRetiro: monto,
      cajaRestante: restante,
      reservaInsumos: caja.reservaInsumos,
    );
  }
}