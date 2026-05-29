import 'package:flutter/material.dart';
import 'core/money.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // اختبار بسيط: هل تستطيع النواة تحويل نص إلى مبلغ؟
    final testMoney = Money.parse("100.50", currency: Currency.sar);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            testMoney.fmt(),
            style: const TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}
