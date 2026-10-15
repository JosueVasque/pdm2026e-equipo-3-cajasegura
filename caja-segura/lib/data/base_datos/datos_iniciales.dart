import 'package:sqflite/sqflite.dart';
import '../../domain/modelos/movimiento.dart';
import 'mapeadores.dart';

/// Se ejecuta únicamente al crear la base de datos, dentro de su transacción.
Future<void> cargarDatosIniciales(Database db) async {
  await db.insert('caja', {
    'id': 1,
    'efectivo_centavos': 250000,
    'reserva_centavos': 120000,
  });
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
  final batch = db.batch();
  for (final movimiento in movimientos) {
    batch.insert('movimientos', movimientoAFila(movimiento));
  }
  await batch.commit(noResult: true);
}
