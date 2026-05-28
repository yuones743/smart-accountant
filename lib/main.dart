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

  String? errorMessage;

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    errorMessage = 'Supabase init error: $e';
  }

  Database? db;
  if (errorMessage == null) {
    try {
      db = await LocalDB.init();
    } catch (e) {
      errorMessage = 'Database init error: $e';
    }
  }

  if (db != null && errorMessage == null) {
    try {
      await LicenseManager.init(db);
    } catch (e) {
      errorMessage = 'LicenseManager init error: $e';
    }
  }

  runApp(SmartApp(db: db, errorMessage: errorMessage));
}

class SmartApp extends StatelessWidget {
  final Database? db;
  final String? errorMessage;

  const SmartApp({required this.db, required this.errorMessage, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
      ),
      home: errorMessage != null
          ? ErrorScreen(message: errorMessage!)
          : LicenseManager.isDemoActive
              ? DashboardScreen(db: db!)
              : LoginScreen(db: db!),
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
                'حدث خطأ أثناء بدء التشغيل',
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
