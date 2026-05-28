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

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    runApp(ErrorScreen(message: 'Supabase error: $e'));
    return;
  }

  Database? db;
  try {
    db = await LocalDB.init();
  } catch (e) {
    runApp(ErrorScreen(message: 'Database error: $e'));
    return;
  }

  try {
    await LicenseManager.init(db);
  } catch (e) {
    runApp(ErrorScreen(message: 'License error: $e'));
    return;
  }

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
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Cairo'),
      home: LicenseManager.isDemoActive
          ? DashboardScreen(db: db)
          : LoginScreen(db: db),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'حدث خطأ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
