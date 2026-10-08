enum TipoMovimiento { ingreso, gasto }

/// A quién pertenece el movimiento: al negocio o a las finanzas personales.
enum AmbitoMovimiento { empresa, personal }

class Movimiento {
  final String id;
  final String descripcion;
  final double monto;
  final TipoMovimiento tipo;
  final AmbitoMovimiento ambito;
  final DateTime fecha;

  const Movimiento({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.ambito,
    required this.fecha,
  });

  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esEmpresa => ambito == AmbitoMovimiento.empresa;
}
