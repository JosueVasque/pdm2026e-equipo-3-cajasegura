import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

DatabaseFactory get factoryLocal => databaseFactory;

Future<String> rutaLocal(DatabaseFactory factory) async =>
    path.join(await factory.getDatabasesPath(), 'caja_segura.db');
