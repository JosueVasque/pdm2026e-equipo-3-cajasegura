class MovimientoConciliadoException implements Exception {
  const MovimientoConciliadoException();
  @override
  String toString() =>
      'Este movimiento está incluido en un cierre. Registra un ajuste sin modificar el original.';
}

class CambioMovimiento {
  const CambioMovimiento({
    required this.fecha,
    required this.accion,
    required this.motivo,
    required this.movimientoId,
    this.antes,
    this.despues,
  });
  final DateTime fecha;
  final String accion;
  final String motivo;
  final String? movimientoId;
  final Map<String, dynamic>? antes;
  final Map<String, dynamic>? despues;
}

class AjusteMovimiento {
  const AjusteMovimiento({
    required this.id,
    required this.movimientoId,
    required this.fecha,
    required this.deltaCentavos,
    required this.motivo,
  });
  final String id;
  final String movimientoId;
  final DateTime fecha;
  final int deltaCentavos;
  final String motivo;
}
