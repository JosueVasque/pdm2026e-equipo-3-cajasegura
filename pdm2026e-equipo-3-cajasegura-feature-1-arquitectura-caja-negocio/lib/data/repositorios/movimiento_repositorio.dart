import '../../domain/modelos/movimiento.dart';

class MovimientoRepositorio {
  // Datos estáticos por ahora. A futuro: base de datos o API.
  // Se devuelven ordenados del más reciente al más antiguo.
  List<Movimiento> obtenerHistorial() {
    final movimientos = [
      Movimiento(
        id: '1',
        descripcion: 'Venta de garrafones',
        monto: 850,
        tipo: TipoMovimiento.ingreso,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime(2026, 10, 7),
      ),
      Movimiento(
        id: '2',
        descripcion: 'Compra de insumos (filtros y tapas)',
        monto: 320,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime(2026, 10, 6),
      ),
      Movimiento(
        id: '3',
        descripcion: 'Compras del mercado',
        monto: 180,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.personal,
        fecha: DateTime(2026, 10, 5),
      ),
      Movimiento(
        id: '4',
        descripcion: 'Venta de agua purificada',
        monto: 540,
        tipo: TipoMovimiento.ingreso,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime(2026, 10, 5),
      ),
      Movimiento(
        id: '5',
        descripcion: 'Pago de energía eléctrica del local',
        monto: 275.50,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime(2026, 10, 3),
      ),
      Movimiento(
        id: '6',
        descripcion: 'Pago de renta de la casa',
        monto: 700,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.personal,
        fecha: DateTime(2026, 10, 2),
      ),
      Movimiento(
        id: '7',
        descripcion: 'Sueldo retirado de la caja',
        monto: 600,
        tipo: TipoMovimiento.ingreso,
        ambito: AmbitoMovimiento.personal,
        fecha: DateTime(2026, 10, 1),
      ),
      Movimiento(
        id: '8',
        descripcion: 'Retiro de sueldo',
        monto: 600,
        tipo: TipoMovimiento.gasto,
        ambito: AmbitoMovimiento.empresa,
        fecha: DateTime(2026, 10, 1),
      ),
    ];
    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return movimientos;
  }
}
