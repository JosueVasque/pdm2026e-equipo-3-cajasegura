enum TipoMovimiento { ingreso, gasto }

enum AmbitoMovimiento { empresa, personal }

class Movimiento {
  final String id;
  final String descripcion;
  final double monto;
  final TipoMovimiento tipo;
  final AmbitoMovimiento ambito;
  final DateTime fecha;
  final int? categoriaId;
  final int impactoCajaCentavos;
  final bool esRetiro;
  final bool conciliado;

  const Movimiento({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.ambito,
    required this.fecha,
    this.categoriaId,
    this.impactoCajaCentavos = 0,
    this.esRetiro = false,
    this.conciliado = false,
  });

  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esEmpresa => ambito == AmbitoMovimiento.empresa;
}
