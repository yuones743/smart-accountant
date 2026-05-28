import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'data/local_database.dart';
import 'services/license_manager.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  final db = await LocalDB.init();
  await LicenseManager.init(db);
  runApp(SmartApp(db: db));
}

class SmartApp extends StatelessWidget {
  final Database db;
  const SmartApp({required this.db, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
        platform: TargetPlatform.android,
      ),
      home: LicenseManager.isDemoActive
          ? DashboardScreen(db: db)
          : LoginScreen(db: db),
    );
  }
}
