import 'package:flutter/widgets.dart';
import '../generated/locales.dart';
import '../pickers/picker_types.dart';

/// Localizes design-system defaults without changing consumer-provided text.
class KLocalization extends StatelessWidget {
  const KLocalization({
    required this.child,
    this.locale,
    this.calendarLocale,
    this.messages,
    this.locales,
    this.dateFormat,
    this.timeFormat,
    this.timeZone,
    super.key,
  });
  final Widget child;
  final String? locale, calendarLocale, timeZone;
  final Map<String, String>? messages;
  final Map<String, Map<String, dynamic>>? locales;
  final KDateFormat? dateFormat;
  final KTimeFormat? timeFormat;

  static KLocalizationData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocalizationTheme>()?.data ??
      KLocalizationData(
        locale: Localizations.maybeLocaleOf(context)?.toLanguageTag() ?? 'en',
      );

  @override
  Widget build(BuildContext context) {
    final parent = of(context);
    return _LocalizationTheme(
      data: KLocalizationData(
        locale: locale ?? parent.locale,
        calendarLocale: calendarLocale ?? parent.calendarLocale,
        messages: {...parent.messages, ...?messages},
        locales: {...parent.locales, ...?locales},
        dateFormat: dateFormat ?? parent.dateFormat,
        timeFormat: timeFormat ?? parent.timeFormat,
        timeZone: timeZone ?? parent.timeZone,
      ),
      child: child,
    );
  }
}

class KLocalizationData {
  const KLocalizationData({
    this.locale = 'en',
    this.calendarLocale,
    this.messages = const {},
    this.locales = const {},
    this.dateFormat = KDateFormat.iso,
    this.timeFormat = KTimeFormat.h24,
    this.timeZone = 'UTC',
  });
  final String locale, timeZone;
  final String? calendarLocale;
  final Map<String, String> messages;
  final Map<String, Map<String, dynamic>> locales;
  final KDateFormat dateFormat;
  final KTimeFormat timeFormat;

  /// Carries this resolved scope into an overlay without merging stale defaults.
  Widget wrap(Widget child) => _LocalizationTheme(data: this, child: child);

  Map<String, dynamic> pack(String tag) {
    final all = {...kLocaleCatalog, ...locales};
    final normalized = tag.replaceAll('_', '-').toLowerCase();
    final exact = all.keys
        .where((key) => key.toLowerCase() == normalized)
        .firstOrNull;
    final base = normalized.split('-').first;
    final baseKey = all.keys
        .where((key) => key.toLowerCase() == base)
        .firstOrNull;
    return all[exact ?? baseKey] ?? all['en']!;
  }

  String text(String key, {String? locale}) =>
      messages[key] ??
      (pack(locale ?? this.locale)['messages'] as Map?)?[key] as String? ??
      (kLocaleCatalog['en']!['messages'] as Map)[key] as String? ??
      key;
  Map<String, dynamic> calendar({String? locale}) =>
      pack(locale ?? calendarLocale ?? this.locale);
}

class _LocalizationTheme extends InheritedTheme {
  const _LocalizationTheme({required this.data, required super.child});
  final KLocalizationData data;
  @override
  bool updateShouldNotify(_LocalizationTheme oldWidget) =>
      data != oldWidget.data;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      _LocalizationTheme(data: data, child: child);
}
