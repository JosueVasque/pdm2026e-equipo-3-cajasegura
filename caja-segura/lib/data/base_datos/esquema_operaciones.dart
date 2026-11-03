import 'package:sqflite/sqflite.dart';

Future<void> crearTablasOperaciones(DatabaseExecutor db) async {
  await db.execute('''CREATE TABLE frecuentes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL CHECK(length(trim(descripcion)) > 0),
    monto_centavos INTEGER NOT NULL CHECK(monto_centavos > 0),
    tipo TEXT NOT NULL CHECK(tipo IN ('ingreso', 'gasto')),
    ambito TEXT NOT NULL CHECK(ambito IN ('empresa', 'personal')),
    categoria_id INTEGER REFERENCES categorias(id) ON DELETE SET NULL
  )''');
  await db.execute('''CREATE TABLE cierres (
    id TEXT PRIMARY KEY NOT NULL,
    fecha INTEGER NOT NULL,
    esperado_centavos INTEGER NOT NULL CHECK(esperado_centavos >= 0),
    contado_centavos INTEGER NOT NULL CHECK(contado_centavos >= 0),
    reserva_centavos INTEGER NOT NULL CHECK(reserva_centavos >= 0),
    nota TEXT NOT NULL,
    CHECK(contado_centavos = esperado_centavos OR length(trim(nota)) > 0)
  )''');
  await db.execute('CREATE INDEX cierres_fecha ON cierres(fecha DESC)');
}
