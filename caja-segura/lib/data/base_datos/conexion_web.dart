import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory get factoryLocal => databaseFactoryFfiWeb;

// Es un nombre dentro del almacenamiento del navegador, no una ruta del SO.
Future<String> rutaLocal(DatabaseFactory factory) async => 'caja_segura.db';
