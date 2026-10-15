import 'conexion_nativa.dart'
    if (dart.library.js_interop) 'conexion_web.dart'
    as plataforma;
import 'package:sqflite/sqflite.dart';

import 'datos_iniciales.dart';

/// Una conexión compartida. El esquema y sus migraciones pertenecen a datos.
class BaseDatosLocal {
  BaseDatosLocal({this.factory, this.ruta});

  static final instancia = BaseDatosLocal();
  final DatabaseFactory? factory;
  final String? ruta;
  Future<Database>? _conexion;

  Future<Database> get database => _conexion ??= _abrirConReintento();

  Future<Database> _abrirConReintento() async {
    try {
      return await _abrir();
    } catch (_) {
      _conexion = null;
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final factorySeleccionada = factory ?? plataforma.factoryLocal;
    final rutaArchivo = ruta ?? await plataforma.rutaLocal(factorySeleccionada);
    return factorySeleccionada.openDatabase(
      rutaArchivo,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Los importes se guardan en centavos para evitar redondeos de REAL.
          await db.execute('''
            CREATE TABLE caja (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              efectivo_centavos INTEGER NOT NULL CHECK (efectivo_centavos >= 0),
              reserva_centavos INTEGER NOT NULL CHECK (reserva_centavos >= 0)
            )
          ''');
          await db.execute('''
            CREATE TABLE movimientos (
              id TEXT PRIMARY KEY NOT NULL,
              descripcion TEXT NOT NULL,
              monto_centavos INTEGER NOT NULL CHECK (monto_centavos > 0),
              tipo TEXT NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
              ambito TEXT NOT NULL CHECK (ambito IN ('empresa', 'personal')),
              fecha INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX movimientos_fecha ON movimientos (fecha DESC)',
          );
          await cargarDatosIniciales(db);
        },
      ),
    );
  }

  Future<void> cerrar() async {
    final conexion = _conexion;
    if (conexion != null) {
      await (await conexion).close();
      _conexion = null;
    }
  }
}
