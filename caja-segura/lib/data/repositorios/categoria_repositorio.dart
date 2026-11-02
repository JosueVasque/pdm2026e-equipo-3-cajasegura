import 'package:sqflite/sqflite.dart';

import '../../domain/modelos/categoria.dart';
import '../base_datos/base_datos_local.dart';

class CategoriaDuplicadaException implements Exception {
  const CategoriaDuplicadaException();

  @override
  String toString() => 'Ya existe una categoría con ese nombre.';
}

class CategoriaEnUsoException implements Exception {
  const CategoriaEnUsoException();

  @override
  String toString() =>
      'Esta categoría tiene movimientos asociados. Puedes archivarla.';
}

class CategoriaRepositorio {
  CategoriaRepositorio({BaseDatosLocal? baseDatos})
    : _baseDatos = baseDatos ?? BaseDatosLocal.instancia;

  final BaseDatosLocal _baseDatos;

  Categoria _desdeFila(Map<String, Object?> fila) {
    return Categoria(
      id: fila['id'] as int,
      nombre: fila['nombre'] as String,
      archivada: (fila['archivada'] as int) == 1,
    );
  }

  Future<List<Categoria>> listar({bool incluirArchivadas = false}) async {
    final db = await _baseDatos.database;

    final filas = await db.query(
      'categorias',
      where: incluirArchivadas ? null : 'archivada = ?',
      whereArgs: incluirArchivadas ? null : [0],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return filas.map(_desdeFila).toList();
  }

  Future<int> crear(String nombre) async {
    final db = await _baseDatos.database;
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre es obligatorio.');
    }

    try {
      return await db.insert('categorias', {
        'nombre': nombreLimpio,
        'archivada': 0,
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const CategoriaDuplicadaException();
      }
      rethrow;
    }
  }

  Future<void> actualizar(int id, String nombre) async {
    final db = await _baseDatos.database;
    final nombreLimpio = nombre.trim();

    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre es obligatorio.');
    }

    try {
      final filas = await db.update(
        'categorias',
        {'nombre': nombreLimpio},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (filas == 0) {
        throw StateError('La categoría ya no existe.');
      }
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const CategoriaDuplicadaException();
      }
      rethrow;
    }
  }

  Future<void> archivar(int id) async {
    final db = await _baseDatos.database;

    final filas = await db.update(
      'categorias',
      {'archivada': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (filas == 0) {
      throw StateError('La categoría ya no existe.');
    }
  }

  Future<void> eliminar(int id) async {
    final db = await _baseDatos.database;

    await db.transaction((txn) async {
      final categoria = await txn.query(
        'categorias',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (categoria.isEmpty) {
        throw StateError('La categoría no existe.');
      }

      final resultado = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM movimientos WHERE categoria_id = ?',
        [id],
      );

      final total = Sqflite.firstIntValue(resultado) ?? 0;

      if (total > 0) {
        throw const CategoriaEnUsoException();
      }

      await txn.delete('categorias', where: 'id = ?', whereArgs: [id]);
    });
  }
}
