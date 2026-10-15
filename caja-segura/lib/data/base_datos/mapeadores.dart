import '../../domain/modelos/caja.dart';
import '../../domain/modelos/movimiento.dart';

int aCentavos(double monto) {
  if (!monto.isFinite || monto < 0) {
    throw ArgumentError.value(monto, 'monto', 'Debe ser finito y no negativo');
  }
  return (monto * 100).round();
}

Map<String, Object?> cajaAFila(Caja caja) => {
  'id': 1,
  'efectivo_centavos': aCentavos(caja.efectivoTotal),
  'reserva_centavos': aCentavos(caja.reservaInsumos),
};

Caja cajaDesdeFila(Map<String, Object?> fila) => Caja(
  efectivoTotal: (fila['efectivo_centavos'] as int) / 100,
  reservaInsumos: (fila['reserva_centavos'] as int) / 100,
);

Map<String, Object?> movimientoAFila(Movimiento movimiento) {
  final centavos = aCentavos(movimiento.monto);
  if (movimiento.id.trim().isEmpty ||
      movimiento.descripcion.trim().isEmpty ||
      centavos == 0) {
    throw ArgumentError(
      'El movimiento requiere id, descripción y monto positivo',
    );
  }
  return {
    'id': movimiento.id,
    'descripcion': movimiento.descripcion,
    'monto_centavos': centavos,
    'tipo': movimiento.tipo.name,
    'ambito': movimiento.ambito.name,
    'fecha': movimiento.fecha.millisecondsSinceEpoch,
  };
}

Movimiento movimientoDesdeFila(Map<String, Object?> fila) => Movimiento(
  id: fila['id'] as String,
  descripcion: fila['descripcion'] as String,
  monto: (fila['monto_centavos'] as int) / 100,
  tipo: TipoMovimiento.values.byName(fila['tipo'] as String),
  ambito: AmbitoMovimiento.values.byName(fila['ambito'] as String),
  fecha: DateTime.fromMillisecondsSinceEpoch(fila['fecha'] as int),
);
