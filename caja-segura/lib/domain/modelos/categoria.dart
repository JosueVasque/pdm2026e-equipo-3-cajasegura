class Categoria {
  final int? id;
  final String nombre;
  final bool archivada;

  const Categoria({this.id, required this.nombre, this.archivada = false});

  Categoria copyWith({int? id, String? nombre, bool? archivada}) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      archivada: archivada ?? this.archivada,
    );
  }
}
