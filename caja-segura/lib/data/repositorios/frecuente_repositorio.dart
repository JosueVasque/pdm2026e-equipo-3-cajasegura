import '../../domain/modelos/movimiento.dart';
import '../../domain/modelos/movimiento_frecuente.dart';
import '../base_datos/base_datos_local.dart';
import '../base_datos/mapeadores.dart';

class FrecuenteRepositorio {
  FrecuenteRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;
  final BaseDatosLocal _baseDatos;

  Future<List<MovimientoFrecuente>> listar() async {
    final db = await _baseDatos.database;
    final filas = await db.query(
      'frecuentes',
      orderBy: 'descripcion COLLATE NOCASE, id',
    );
    return filas
        .map(
          (f) => MovimientoFrecuente(
            id: f['id'] as int,
            descripcion: f['descripcion'] as String,
            monto: (f['monto_centavos'] as int) / 100,
            tipo: TipoMovimiento.values.byName(f['tipo'] as String),
            ambito: AmbitoMovimiento.values.byName(f['ambito'] as String),
            categoriaId: f['categoria_id'] as int?,
          ),
        )
        .toList();
  }

  Future<void> guardar(MovimientoFrecuente frecuente) async {
    final centavos = aCentavos(frecuente.monto);
    if (frecuente.descripcion.trim().isEmpty ||
        frecuente.descripcion.trim().length > 120 ||
        centavos <= 0) {
      throw ArgumentError('Ingresa una descripción y un monto positivo.');
    }
    final db = await _baseDatos.database;
    await db.transaction((txn) async {
      if (frecuente.categoriaId != null) {
        final categorias = await txn.query(
          'categorias',
          where: 'id = ? AND archivada = 0',
          whereArgs: [frecuente.categoriaId],
        );
        if (categorias.isEmpty) {
          throw StateError('Elige una categoría activa o Sin categoría.');
        }
      }
      final fila = <String, Object?>{
        'descripcion': frecuente.descripcion.trim(),
        'monto_centavos': centavos,
        'tipo': frecuente.tipo.name,
        'ambito': frecuente.ambito.name,
        'categoria_id': frecuente.categoriaId,
      };
      if (frecuente.id == null) {
        await txn.insert('frecuentes', fila);
      } else {
        final n = await txn.update(
          'frecuentes',
          fila,
          where: 'id = ?',
          whereArgs: [frecuente.id],
        );
        if (n == 0) throw StateError('El movimiento frecuente ya no existe.');
      }
    });
  }

  Future<void> eliminar(int id) async {
    final db = await _baseDatos.database;
    await db.delete('frecuentes', where: 'id = ?', whereArgs: [id]);
  }
}
