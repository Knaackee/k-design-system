import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _examples = [
  (label: 'Amount', value: 123456, currency: 'EUR', locale: 'de-DE', digits: 2),
  (label: 'Zero', value: 0, currency: 'EUR', locale: 'de-DE', digits: 2),
  (
    label: 'Negative',
    value: -12345,
    currency: 'USD',
    locale: 'en-US',
    digits: 2,
  ),
  (label: 'Yen', value: 1234, currency: 'JPY', locale: 'ja-JP', digits: 0),
  (label: 'Dinar', value: 123456, currency: 'KWD', locale: 'en-US', digits: 3),
  (
    label: 'Read only',
    value: 123456,
    currency: 'EUR',
    locale: 'de-DE',
    digits: 2,
  ),
  (
    label: 'Unavailable',
    value: 123456,
    currency: 'EUR',
    locale: 'de-DE',
    digits: 2,
  ),
];

class CurrencyFixture extends StatefulWidget {
  const CurrencyFixture({super.key});
  @override
  State<CurrencyFixture> createState() => _CurrencyFixtureState();
}

class _CurrencyFixtureState extends State<CurrencyFixture> {
  final List<int?> _values = _examples.map((e) => e.value).toList();
  final _invalid = <int>{};
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Currency amounts', variant: KTextVariant.heading4),
            for (var index = 0; index < _examples.length; index++)
              KField(
                label: _examples[index].label,
                errorText: _invalid.contains(index)
                    ? 'Enter a valid amount without extra decimal places.'
                    : null,
                child: KCurrencyInput(
                  value: _values[index],
                  currency: _examples[index].currency,
                  locale: _examples[index].locale,
                  fractionDigits: _examples[index].digits,
                  readOnly: index == 5,
                  enabled: index != 6,
                  clearable: true,
                  onInvalidDraft: (_) => setState(() => _invalid.add(index)),
                  onCommit: (value) => setState(() {
                    _values[index] = value;
                    _invalid.remove(index);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
