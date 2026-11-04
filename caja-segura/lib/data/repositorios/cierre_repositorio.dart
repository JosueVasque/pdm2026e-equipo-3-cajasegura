import '../../domain/modelos/cierre_caja.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';
import '../base_datos/trazabilidad_local.dart';

class CierreRepositorio {
  CierreRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;
  final BaseDatosLocal _baseDatos;

  Future<List<CierreCaja>> listar() async {
    final db = await _baseDatos.database;
    final filas = await db.query('cierres', orderBy: 'fecha DESC, id DESC');
    return filas
        .map(
          (f) => CierreCaja(
            id: f['id'] as String,
            fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
            esperadoCentavos: f['esperado_centavos'] as int,
            contadoCentavos: f['contado_centavos'] as int,
            reservaCentavos: f['reserva_centavos'] as int,
            nota: f['nota'] as String,
          ),
        )
        .toList();
  }

  Future<void> confirmar({
    required String id,
    required double esperado,
    required double contado,
    required String nota,
  }) async {
    final esperadoCentavos = aCentavos(esperado);
    final contadoCentavos = aCentavos(contado);
    if (id.trim().isEmpty ||
        (esperadoCentavos != contadoCentavos && nota.trim().isEmpty)) {
      throw ArgumentError(
        'Explica la diferencia antes de confirmar el cierre.',
      );
    }
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      final caja = (await txn.query('caja', where: 'id = 1')).single;
      if (caja['efectivo_centavos'] != esperadoCentavos) {
        throw const SaldoCambioException();
      }
      await txn.insert('cierres', {
        'id': id,
        'fecha': DateTime.now().millisecondsSinceEpoch,
        'esperado_centavos': esperadoCentavos,
        'contado_centavos': contadoCentavos,
        'reserva_centavos': caja['reserva_centavos'],
        'nota': nota.trim(),
      });
      await txn.update('caja', {
        'efectivo_centavos': contadoCentavos,
      }, where: 'id = 1');
      await sellarMovimientos(txn, id);
      await registrarCambio(
        txn,
        accion: 'cierre',
        motivo: nota.trim().isEmpty ? 'Cierre sin diferencia' : nota,
        antes: caja,
        despues: {
          ...caja,
          'efectivo_centavos': contadoCentavos,
          'cierre_id': id,
        },
      );
    });
  }
}
