import 'movimiento.dart';

class MovimientoFrecuente {
  const MovimientoFrecuente({
    this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.ambito,
    this.categoriaId,
  });
  final int? id;
  final String descripcion;
  final double monto;
  final TipoMovimiento tipo;
  final AmbitoMovimiento ambito;
  final int? categoriaId;
}
