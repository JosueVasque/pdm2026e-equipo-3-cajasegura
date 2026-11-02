import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caja_segura/data/repositorios/categoria_repositorio.dart';
import 'package:caja_segura/domain/modelos/categoria.dart';
import 'package:caja_segura/presentation/pantallas/categorias_screen.dart';
import 'package:caja_segura/presentation/providers/categoria_provider.dart';

class CategoriaRepositorioFalso extends CategoriaRepositorio {
  final List<Categoria> categorias = [
    const Categoria(id: 1, nombre: 'Alimentación'),
  ];

  @override
  Future<List<Categoria>> listar({bool incluirArchivadas = false}) async {
    return List.of(categorias);
  }

  @override
  Future<void> actualizar(int id, String nombre) async {
    final indice = categorias.indexWhere((categoria) => categoria.id == id);

    if (indice == -1) {
      throw StateError('Categoría no encontrada');
    }

    categorias[indice] = Categoria(
      id: id,
      nombre: nombre,
      archivada: categorias[indice].archivada,
    );
  }
}

void main() {
  testWidgets('editar categoría conserva el ID y actualiza el listado', (
    tester,
  ) async {
    final repositorio = CategoriaRepositorioFalso();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriaRepositorioProvider.overrideWithValue(repositorio),
        ],
        child: const MaterialApp(home: CategoriasScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // La categoría existente aparece en el listado.
    expect(find.text('Alimentación'), findsOneWidget);

    // Tocar la categoría abre el formulario de edición.
    await tester.tap(find.text('Alimentación'));
    await tester.pumpAndSettle();

    expect(find.text('Editar categoría'), findsOneWidget);

    // El formulario debe mostrar el nombre anterior.
    final campo = tester.widget<TextFormField>(find.byType(TextFormField));

    expect(campo.controller!.text, 'Alimentación');

    // Cambiar el nombre.
    await tester.enterText(find.byType(TextFormField), 'Comida');

    // Guardar los cambios.
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    // El listado debe mostrar el nuevo nombre.
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('Alimentación'), findsNothing);

    // El ID original debe mantenerse.
    expect(repositorio.categorias.first.id, 1);
    expect(repositorio.categorias.first.nombre, 'Comida');
  });
}
