import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/license_manager.dart';
import 'dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Database db;
  const SettingsScreen({required this.db, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDemoActive = LicenseManager.isDemoActive;

  Future<void> _activateDemo() async {
    await LicenseManager.activateDemo(widget.db);
    setState(() => _isDemoActive = true);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardScreen(db: widget.db)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('تفعيل النسخة التجريبية الكاملة'),
            subtitle: const Text('جميع الميزات مفعّلة لمدة 4 أشهر'),
            trailing: _isDemoActive
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: _activateDemo,
                    child: const Text('تفعيل'),
                  ),
          ),
          if (_isDemoActive) ...[
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('الحالة'),
              subtitle: Text('النسخة التجريبية مفعّلة'),
              trailing: Icon(Icons.check, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}
