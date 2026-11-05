import 'conexion_nativa.dart'
    if (dart.library.js_interop) 'conexion_web.dart'
    as plataforma;
import 'package:sqflite/sqflite.dart';

import 'datos_iniciales.dart';
import 'esquema_operaciones.dart';
import 'trazabilidad_local.dart';

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
        version: 6,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
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
              fecha INTEGER NOT NULL,
              categoria_id INTEGER REFERENCES categorias(id) ON DELETE RESTRICT,
              impacto_caja_centavos INTEGER NOT NULL DEFAULT 0,
              es_retiro INTEGER NOT NULL DEFAULT 0 CHECK(es_retiro IN (0, 1))
            )
          ''');
          await db.execute(
            'CREATE INDEX movimientos_fecha ON movimientos (fecha DESC)',
          );
          await db.execute('''
            CREATE TABLE categorias (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
              archivada INTEGER NOT NULL DEFAULT 0 CHECK (archivada IN (0, 1))
            )
          ''');
          await crearTablasOperaciones(db);
          await cargarDatosIniciales(db);
          await db.execute(
            "UPDATE movimientos SET es_retiro = 1 WHERE descripcion = 'Retiro de sueldo' AND tipo = 'gasto' AND ambito = 'empresa'",
          );
          await crearTrazabilidad(db);
        },
        onUpgrade: (db, versionAnterior, versionNueva) async {
          if (versionAnterior < 4) {
            await db.execute(
              'ALTER TABLE movimientos ADD COLUMN '
              'impacto_caja_centavos INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (versionAnterior < 2) {
            await db.execute('''
              CREATE TABLE categorias (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
                archivada INTEGER NOT NULL DEFAULT 0
                  CHECK (archivada IN (0, 1))
              )
            ''');
          }

          if (versionAnterior < 3) {
            await db.execute('''
              ALTER TABLE movimientos
              ADD COLUMN categoria_id INTEGER
              REFERENCES categorias(id) ON DELETE RESTRICT
            ''');
          }
          if (versionAnterior < 5) {
            await db.execute(
              'ALTER TABLE movimientos ADD COLUMN es_retiro INTEGER NOT NULL DEFAULT 0 CHECK(es_retiro IN (0, 1))',
            );
            await db.execute(
              "UPDATE movimientos SET es_retiro = 1 WHERE descripcion = 'Retiro de sueldo' AND tipo = 'gasto' AND ambito = 'empresa'",
            );
            await crearTablasOperaciones(db);
          }
          if (versionAnterior < 6) {
            await crearTrazabilidad(db);
            final cierres = await db.query(
              'cierres',
              orderBy: 'fecha DESC, id DESC',
              limit: 1,
            );
            if (cierres.isNotEmpty) {
              await sellarMovimientos(
                db,
                cierres.single['id'] as String,
                migracion: true,
              );
              await registrarCambio(
                db,
                accion: 'proteccion_migracion',
                motivo:
                    'Protección conservadora de movimientos existentes: la versión anterior no guardaba qué movimientos incluía cada cierre.',
              );
            }
          }
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
