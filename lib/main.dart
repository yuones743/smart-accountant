import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('تطبيق اختباري'),
        ),
        body: const Center(
          child: Text(
            'مرحباً بالعالم!',
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}
