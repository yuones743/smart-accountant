import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:decimal/decimal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'config/app_config.dart';

// ==========================================
// 1. CanonicalJson (الحتمية)
// ==========================================
class CanonicalJson {
  static String encode(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return jsonEncode(v);
    if (v is num || v is bool) return v.toString();
    if (v is Map) {
      final keys = v.keys.toList()..sort();
      return '{${keys.map((k) => '${encode(k)}:${encode(v[k])}').join(',')}}';
    }
    if (v is Iterable) return '[${v.map(encode).join(',')}]';
    throw Exception('Unsupported type: ${v.runtimeType}');
  }
}

// ==========================================
// 2. Money (لا double أبداً)
// ==========================================
final class Currency {
  final String code;
  final int scale;
  const Currency({required this.code, required this.scale});
  static const usd = Currency(code: 'USD', scale: 2);
  static const eur = Currency(code: 'EUR', scale: 2);
  static const gbp = Currency(code: 'GBP', scale: 2);
  static const jpy = Currency(code: 'JPY', scale: 0);
  static const sar = Currency(code: 'SAR', scale: 2);
  static const aed = Currency(code: 'AED', scale: 2);
  static const kwd = Currency(code: 'KWD', scale: 3);
  static const egp = Currency(code: 'EGP', scale: 2);
  static const syp = Currency(code: 'SYP', scale: 2);
  static const try_ = Currency(code: 'TRY', scale: 2);
  static const rub = Currency(code: 'RUB', scale: 2);
  static const inr = Currency(code: 'INR', scale: 2);
  static const pkr = Currency(code: 'PKR', scale: 2);
  static const Map<String, Currency> _registry = {
    'USD': usd, 'EUR': eur, 'GBP': gbp, 'JPY': jpy, 'SAR': sar,
    'AED': aed, 'KWD': kwd, 'EGP': egp, 'SYP': syp, 'TRY': try_,
    'RUB': rub, 'INR': inr, 'PKR': pkr,
  };
  static Currency byCode(String c) => _registry[c] ?? usd;
}

final class Money {
  final Decimal _amount;
  final Currency _currency;
  const Money._(this._amount, this._currency);
  factory Money.parse(String v, {required Currency c}) => Money._(Decimal.parse(v.trim()).round(scale: c.scale), c);
  factory Money.fromMinor(int m, Currency c) => Money._(Decimal.fromInt(m) / Decimal.fromInt(10).pow(c.scale), c);
  static const zero = Money._(Decimal.zero, Currency.sar);
  factory Money.zeroCurrency(Currency c) => Money._(Decimal.zero, c);
  Currency get ccy => _currency;
  int get minor => (_amount * Decimal.fromInt(10).pow(_currency.scale)).round();
  bool get isZero => _amount == Decimal.zero;
  Money operator +(Money o) { _same(o); return Money._(_amount + o._amount, _currency); }
  Money operator -(Money o) { _same(o); return Money._(_amount - o._amount, _currency); }
  Money mul(Decimal f) => Money._(_amount * f, _currency);
  Money pct(double p) => mul(Decimal.parse(p.toString()) / Decimal.fromInt(100));
  int compareTo(Money o) { _same(o); return _amount.compareTo(o._amount); }
  @override bool operator ==(Object o) => o is Money && o._amount == _amount && o._currency == _currency;
  @override int get hashCode => Object.hash(_amount, _currency);
  String fmt() => '${_amount.toStringAsFixed(_currency.scale)} ${_currency.code}';
  Map<String, dynamic> toMap() => {'amount': _amount.toString(), 'currency': _currency.code};
  factory Money.fromMap(Map<String, dynamic> m) => Money.parse(m['amount'], currency: Currency.byCode(m['currency']));
  void _same(Money o) { if (_currency != o._currency) throw Exception('Currency mismatch'); }
}

// ==========================================
// 3. HLC (الساعة الهجينة)
// ==========================================
final class Hlc {
  final int wall, log;
  const Hlc._(this.wall, this.log);
  factory Hlc.create(int w) => Hlc._(w, 0);
  Hlc tick(int w) => w > wall ? Hlc._(w, 0) : Hlc._(wall, log + 1);
  @override bool operator ==(Object o) => o is Hlc && wall == o.wall && log == o.log;
  @override int get hashCode => Object.hash(wall, log);
}

// ==========================================
// 4. DomainEvent & Payloads
// ==========================================
enum EventType { invoiceCreated, paymentReceived, journalCreated }

sealed class EventPayload { String toCanonical(); }
class InvoicePayload extends EventPayload {
  final String invId; final Money total, sub, tax;
  InvoicePayload(this.invId, this.total, this.sub, this.tax);
  @override String toCanonical() => CanonicalJson.encode({'inv': invId, 'tot': total.toMap(), 'sub': sub.toMap(), 'tax': tax.toMap()});
}
class PaymentPayload extends EventPayload {
  final String payId, invId; final Money amt;
  PaymentPayload(this.payId, this.invId, this.amt);
  @override String toCanonical() => CanonicalJson.encode({'pay': payId, 'inv': invId, 'amt': amt.toMap()});
}
class JournalPayload extends EventPayload {
  final String entryId; final List<Map<String, dynamic>> lines;
  JournalPayload(this.entryId, this.lines);
  @override String toCanonical() => CanonicalJson.encode({'entry': entryId, 'lines': lines});
}

final class DomainEvent {
  final String id, aggId, aggType, tenant, user, device;
  final EventType type;
  final Set<String> parents;
  final int schema;
  final EventPayload payload;
  final Hlc hlc;
  final String? idem;
  final DateTime created;
  late final String hash;
  DomainEvent({
    required this.id, required this.aggId, required this.aggType, required this.type,
    required this.tenant, required this.user, required this.device, required this.parents,
    required this.schema, required this.payload, required this.hlc, this.idem, DateTime? created,
  }) : created = created ?? DateTime.now() { hash = _compute(); }
  String _compute() => sha256.convert(utf8.encode(toCanonical())).toString();
  String toCanonical() => CanonicalJson.encode({
    'id': id, 'agg': aggId, 'type': type.name, 'tenant': tenant, 'user': user,
    'device': device, 'parents': parents.toList()..sort(), 'schema': schema,
    'hlc': '${hlc.wall}|${hlc.log}', 'idem': idem, 'created': created.toIso8601String(),
    'payload': payload.toCanonical(),
  });
  Map<String, dynamic> toDb() => {
    'id': id, 'aggregate_id': aggId, 'aggregate_type': aggType, 'event_type': type.name,
    'tenant_id': tenant, 'user_id': user, 'device_id': device,
    'parent_event_ids': parents.toList()..sort(), 'schema_version': schema,
    'payload': jsonDecode(payload.toCanonical()), 'hlc_wall_clock': hlc.wall,
    'hlc_logical_counter': hlc.log, 'idempotency_key': idem, 'canonical_hash': hash,
    'created_at': created.toIso8601String()
  };
}

// ==========================================
// 5. Event Store (SQLite)
// ==========================================
class EventStore {
  final Database db;
  EventStore(this.db);
  static Future<void> create(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY, aggregate_id TEXT, aggregate_type TEXT, event_type TEXT,
      tenant_id TEXT, user_id TEXT, device_id TEXT, parent_event_ids TEXT,
      schema_version INTEGER, payload_canonical TEXT, hlc_wall_clock INTEGER,
      hlc_logical_counter INTEGER, idempotency_key TEXT, version INTEGER,
      canonical_hash TEXT, synced INTEGER DEFAULT 0, created_at TEXT)''');
  }
  Future<void> append(DomainEvent e, int ver) async {
    await db.transaction((txn) async {
      final rows = await txn.rawQuery('SELECT MAX(version) as v FROM events WHERE aggregate_id=?', [e.aggId]);
      final cur = (rows.first['v'] as int?) ?? 0;
      if (cur != ver) throw Exception('CONCURRENCY');
      if (e.idem != null) {
        final ex = await txn.query('events', where: 'idempotency_key=?', whereArgs: [e.idem]);
        if (ex.isNotEmpty) return;
      }
      final canon = e.toCanonical();
      final h = sha256.convert(utf8.encode(canon)).toString();
      if (h != e.hash) throw Exception('HASH');
      await txn.insert('events', {
        'id': e.id, 'aggregate_id': e.aggId, 'aggregate_type': e.aggType, 'event_type': e.type.name,
        'tenant_id': e.tenant, 'user_id': e.user, 'device_id': e.device,
        'parent_event_ids': jsonEncode(e.parents.toList()..sort()), 'schema_version': e.schema,
        'payload_canonical': canon, 'hlc_wall_clock': e.hlc.wall, 'hlc_logical_counter': e.hlc.log,
        'idempotency_key': e.idem, 'version': cur + 1, 'canonical_hash': h, 'created_at': e.created.toIso8601String()
      });
    });
  }
}

// ==========================================
// 6. RBAC
// ==========================================
enum GuardAction { create, read, update, delete }
class RBAC {
  static bool can(String role, String feature, GuardAction action) {
    if (role == 'admin') return true;
    if (role == 'accountant' && feature != 'users') return true;
    if (role == 'sales' && feature == 'invoices' && action == GuardAction.create) return true;
    return false;
  }
}

// ==========================================
// 7. Local Database
// ==========================================
class LocalDB {
  static Future<Database> init() async {
    final path = p.join(await getDatabasesPath(), 'smart_accountant.db');
    return openDatabase(path, version: 3, onCreate: (db, _) async {
      await db.execute('PRAGMA foreign_keys=ON');
      await db.execute('''CREATE TABLE users (
        id TEXT PRIMARY KEY, tenant_id TEXT, role TEXT DEFAULT 'sales',
        phone TEXT, access_token TEXT, created_at TEXT DEFAULT (datetime('now')))''');
      await db.execute('''CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY, user_id TEXT, plan INTEGER, start_date TEXT, end_date TEXT, status TEXT DEFAULT 'active')''');
      await EventStore.create(db);
    });
  }
}

// ==========================================
// 8. Subscription Service (قلب نموذج العمل)
// ==========================================
class SubscriptionService {
  final Database db;
  SubscriptionService(this.db);
  Future<bool> isTrialActive(String userId) async {
    final rows = await db.query('subscriptions', where: 'user_id=? AND status=?', whereArgs: [userId, 'trial']);
    if (rows.isEmpty) return false;
    final start = DateTime.parse(rows.first['start_date'] as String);
    return DateTime.now().difference(start).inDays < AppConfig.trialDays;
  }
  Future<bool> isPremiumActive(String userId) async {
    final rows = await db.query('subscriptions', where: 'user_id=? AND status=?', whereArgs: [userId, 'active']);
    if (rows.isEmpty) return false;
    return DateTime.now().isBefore(DateTime.parse(rows.first['end_date'] as String));
  }
  Future<bool> canAccessFeature(String userId, String feature) async {
    if (await isPremiumActive(userId)) return true;
    if (await isTrialActive(userId)) return true;
    // الميزات الأساسية متاحة حتى في الوضع الجاف
    if (feature == 'basic_entry') return true;
    return false;
  }
}

// ==========================================
// 9. التطبيق الرئيسي
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  final db = await LocalDB.init();
  runApp(SmartApp(db: db));
}

class SmartApp extends StatelessWidget {
  final Database db;
  const SmartApp({required this.db});
  @override Widget build(BuildContext c) => MaterialApp(
    title: AppConfig.appName,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Cairo'),
    home: LoginScreen(db: db),
  );
}

// ==========================================
// 10. شاشة تسجيل الدخول
// ==========================================
class LoginScreen extends StatefulWidget {
  final Database db;
  const LoginScreen({required this.db});
  @override _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: _phone.text.trim());
      // await Supabase.instance.client.auth.verifyOTP(phone: _phone.text.trim(), token: '123456');
      // الانتقال إلى الشاشة الرئيسية
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التسجيل: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext c) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.calculate, size: 80, color: Colors.teal),
      const SizedBox(height: 20),
      Text(AppConfig.appName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 40),
      TextField(controller: _phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixText: '+'), keyboardType: TextInputType.phone),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'جاري...' : 'تسجيل الدخول')),
    ]))),
  );
  @override void dispose() { _phone.dispose(); super.dispose(); }
}
