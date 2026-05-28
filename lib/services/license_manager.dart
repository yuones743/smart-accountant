import 'package:sqflite/sqflite.dart';
import '../config/app_config.dart';

class LicenseManager {
  static bool _isDemoActive = false;

  static Future<void> init(Database db) async {
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: ['demo_start']);
    if (rows.isNotEmpty) {
      final start = DateTime.parse(rows.first['value'] as String);
      if (DateTime.now().difference(start).inDays < AppConfig.demoMonths) {
        _isDemoActive = true;
      }
    }
  }

  static Future<void> activateDemo(Database db) async {
    await db.insert('app_settings', {'key': 'demo_start', 'value': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    _isDemoActive = true;
  }

  static bool get isDemoActive => _isDemoActive;
}
