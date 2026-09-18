import 'package:intl/intl.dart';

const kCurrencyMaxMinorUnits = 9007199254740991;

class KCurrencyParseResult {
  const KCurrencyParseResult.valid(this.value) : valid = true;
  const KCurrencyParseResult.invalid() : valid = false, value = null;
  final bool valid;
  final int? value;
}

void _validate(int fractionDigits) {
  if (fractionDigits < 0 || fractionDigits > 6) {
    throw ArgumentError.value(
      fractionDigits,
      'fractionDigits',
      'Expected 0..6',
    );
  }
}

String _spaces(String value) => value.replaceAll(RegExp('[\u00a0\u202f]'), ' ');
String _ascii(String value, NumberFormat number) {
  final zero = number.symbols.ZERO_DIGIT.codeUnitAt(0);
  return String.fromCharCodes(
    value.runes.map(
      (code) => code >= zero && code <= zero + 9 ? code - zero + 48 : code,
    ),
  );
}

String _localized(String value, NumberFormat number) {
  final zero = number.symbols.ZERO_DIGIT.codeUnitAt(0);
  return value.replaceAllMapped(
    RegExp(r'\d'),
    (m) => String.fromCharCode(zero + int.parse(m[0]!)),
  );
}

// intl's simpleCurrencySymbols are global narrow symbols (e.g. KWD="din").
// Keep these currency/locale symbols aligned with ECMA-402 currencyDisplay=symbol.
String _currencySymbol(String currency, String locale) {
  final language = locale.replaceAll('-', '_').split('_').first;
  switch (currency.toUpperCase()) {
    case 'EUR':
      return '€';
    case 'USD':
      return switch (language) {
        'fr' => r'$US',
        'ar' => r'US$',
        _ => r'$',
      };
    case 'JPY':
      return switch (language) {
        'ja' => '￥',
        'fr' => 'JPY',
        'ar' || 'hi' => 'JP¥',
        _ => '¥',
      };
    case 'KWD':
      return language == 'ar' ? 'د.ك.\u200f' : 'KWD';
    default:
      return currency.toUpperCase();
  }
}

NumberFormat _currencyFormat(
  String currency,
  String locale,
  int fractionDigits,
) => NumberFormat.currency(
  locale: locale,
  name: currency,
  symbol: _currencySymbol(currency, locale),
  decimalDigits: fractionDigits,
);
String formatCurrencyMinorUnits(
  int? value, {
  required String currency,
  required String locale,
  int fractionDigits = 2,
  bool currencyDisplay = true,
}) {
  _validate(fractionDigits);
  if (value == null) return '';
  if (value.abs() > kCurrencyMaxMinorUnits) {
    throw ArgumentError.value(
      value,
      'value',
      'Expected safe integer minor units',
    );
  }
  final number = NumberFormat.decimalPattern(locale);
  final divisor = BigInt.from(10).pow(fractionDigits);
  final magnitude = BigInt.from(value).abs();
  final integer = number.format((magnitude ~/ divisor).toInt());
  final fraction = _localized(
    (magnitude % divisor).toString().padLeft(fractionDigits, '0'),
    number,
  );
  final numeric =
      integer +
      (fractionDigits > 0 ? '${number.symbols.DECIMAL_SEP}$fraction' : '');
  if (!currencyDisplay) {
    return '${value < 0 ? number.symbols.MINUS_SIGN : ''}$numeric';
  }
  final money = _currencyFormat(currency, locale, fractionDigits);
  // Replace the exact numeric placeholder, retaining locale currency affixes.
  final placeholder = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;
  final template = money.format(value < 0 ? -1 : 1);
  final sample = placeholder.format(1);
  final index = template.indexOf(sample);
  var prefix = template.substring(0, index);
  var suffix = template.substring(index + sample.length);
  // CLDR currency spacing separates alphabetic currency codes from numbers.
  if (RegExp(r'[A-Za-z]$').hasMatch(prefix)) prefix += '\u00a0';
  if (RegExp(r'^[A-Za-z]').hasMatch(suffix)) suffix = '\u00a0$suffix';
  return '$prefix$numeric$suffix';
}

KCurrencyParseResult parseCurrencyMinorUnits(
  String text, {
  required String currency,
  required String locale,
  int fractionDigits = 2,
}) {
  _validate(fractionDigits);
  final number = NumberFormat.decimalPattern(locale);
  final money = _currencyFormat(currency, locale, fractionDigits);
  var input = _spaces(
    text.replaceAll(RegExp('[\u061c\u200e\u200f]'), ''),
  ).trim();
  if (input.isEmpty) return const KCurrencyParseResult.valid(null);
  input = _ascii(input, number).replaceFirst(number.symbols.MINUS_SIGN, '-');
  final negative = input.startsWith('-');
  if (negative || input.startsWith('+')) input = input.substring(1);
  for (final symbol in {
    currency,
    money.currencySymbol.replaceAll(RegExp('[\u061c\u200e\u200f]'), ''),
  }) {
    if (input.startsWith(symbol)) {
      input = input.substring(symbol.length).trim();
    } else if (input.endsWith(symbol)) {
      input = input.substring(0, input.length - symbol.length).trim();
    }
  }
  final parts = input.split(number.symbols.DECIMAL_SEP);
  if (parts.length > 2) return const KCurrencyParseResult.invalid();
  final rawInteger = parts.first;
  final integer = rawInteger.replaceAll(_spaces(number.symbols.GROUP_SEP), '');
  final fraction = parts.length == 2 ? parts.last : null;
  if (!RegExp(r'^\d+$').hasMatch(integer) ||
      (fraction != null &&
          (!RegExp(r'^\d+$').hasMatch(fraction) ||
              fraction.length > fractionDigits))) {
    return const KCurrencyParseResult.invalid();
  }
  final whole = BigInt.tryParse(integer);
  if (whole == null || whole > BigInt.from(kCurrencyMaxMinorUnits)) {
    return const KCurrencyParseResult.invalid();
  }
  if (rawInteger != integer &&
      rawInteger != _ascii(_spaces(number.format(whole.toInt())), number)) {
    return const KCurrencyParseResult.invalid();
  }
  final amount =
      whole * BigInt.from(10).pow(fractionDigits) +
      BigInt.parse(
        (fraction ?? '').padRight(fractionDigits, '0').isEmpty
            ? '0'
            : (fraction ?? '').padRight(fractionDigits, '0'),
      );
  if (amount > BigInt.from(kCurrencyMaxMinorUnits)) {
    return const KCurrencyParseResult.invalid();
  }
  return KCurrencyParseResult.valid((negative ? -amount : amount).toInt());
}
