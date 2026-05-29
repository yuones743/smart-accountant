import 'package:decimal/decimal.dart';

final class Currency {
  final String code;
  final int scale;
  const Currency({required this.code, required this.scale});
  
  static const usd = Currency(code: 'USD', scale: 2);
  static const eur = Currency(code: 'EUR', scale: 2);
  static const sar = Currency(code: 'SAR', scale: 2);
  static const syp = Currency(code: 'SYP', scale: 2);
  static const aed = Currency(code: 'AED', scale: 2);
  static const kwd = Currency(code: 'KWD', scale: 3);
  static const egp = Currency(code: 'EGP', scale: 2);
  static const try_ = Currency(code: 'TRY', scale: 2);
  static const rub = Currency(code: 'RUB', scale: 2);
  static const inr = Currency(code: 'INR', scale: 2);
  static const pkr = Currency(code: 'PKR', scale: 2);

  static final Map<String, Currency> _registry = {
    'USD': usd, 'EUR': eur, 'SAR': sar, 'SYP': syp,
    'AED': aed, 'KWD': kwd, 'EGP': egp, 'TRY': try_,
    'RUB': rub, 'INR': inr, 'PKR': pkr,
  };
  
  static Currency byCode(String c) => _registry[c] ?? usd;
}

final class Money {
  final Decimal _amount;
  final Currency _currency;
  
  const Money._(this._amount, this._currency);
  
  factory Money.parse(String v, {required Currency c}) {
    return Money._(Decimal.parse(v.trim()).round(scale: c.scale), c);
  }
  
  factory Money.fromMinor(int m, Currency c) {
    // تقسيم آمن: نحول Decimal إلى سلسلة لحساب القسمة بدقة
    final divisor = _tenPower(c.scale);
    return Money._(Decimal.parse((Decimal.fromInt(m) / divisor).toString()), c);
  }
  
  static final zero = Money._(Decimal.zero, Currency.sar);
  factory Money.zeroCurrency(Currency c) => Money._(Decimal.zero, c);
  
  Currency get ccy => _currency;
  
  int get minor {
    final factor = _tenPower(_currency.scale);
    // نستخدم toStringAsFixed ثم int.parse لاستخراج القيمة الصحيحة
    return int.parse((_amount * factor).toStringAsFixed(0));
  }
  
  bool get isZero => _amount == Decimal.zero;
  
  Money operator +(Money o) { _same(o); return Money._(_amount + o._amount, _currency); }
  Money operator -(Money o) { _same(o); return Money._(_amount - o._amount, _currency); }
  Money mul(Decimal f) => Money._(_amount * f, _currency);
  
  Money pct(double p) {
    final percent = Decimal.parse((p / 100.0).toStringAsFixed(10));
    return Money._(_amount * percent, _currency);
  }
  
  int compareTo(Money o) { _same(o); return _amount.compareTo(o._amount); }
  bool operator ==(Object o) => o is Money && o._amount == _amount && o._currency == _currency;
  int get hashCode => Object.hash(_amount, _currency);
  
  String fmt() => '${_amount.toStringAsFixed(_currency.scale)} ${_currency.code}';
  Map<String, dynamic> toMap() => {'amount': _amount.toString(), 'currency': _currency.code};
  
  factory Money.fromMap(Map<String, dynamic> m) {
    return Money.parse(m['amount'], c: Currency.byCode(m['currency']));
  }
  
  void _same(Money o) { if (_currency != o._currency) throw Exception('Currency mismatch'); }
}

/// دالة مساعدة لحساب 10^scale بطريقة متوافقة مع الإصدارات القديمة
Decimal _tenPower(int scale) {
  Decimal result = Decimal.one;
  for (int i = 0; i < scale; i++) {
    result = result * Decimal.fromInt(10);
  }
  return result;
}
