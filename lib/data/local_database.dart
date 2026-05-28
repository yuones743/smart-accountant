import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDB {
  static Future<Database> init() async {
    final path = p.join(await getDatabasesPath(), 'smart_accountant.db');
    return openDatabase(path, version: 3, onCreate: (db, _) async {
      await db.execute('PRAGMA foreign_keys=ON');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, tenant_id TEXT, role TEXT DEFAULT \'sales\', phone TEXT, access_token TEXT, created_at TEXT DEFAULT (datetime(\'now\')))
      ''');
    });
  }
}
