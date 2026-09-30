import 'dart:math';

class Caja {
  final double efectivoTotal;
  final double reservaInsumos;

  const Caja({
    required this.efectivoTotal,
    required this.reservaInsumos,
  });

  /// Dinero que Maria puede retirar sin tocar la reserva.
  double get disponibleParaSueldo => max(0, efectivoTotal - reservaInsumos);
}