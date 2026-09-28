import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'package:k_design_flutter_example/theme/consumer_theme.dart';

void main() {
  test('keeps light and dark brand overrides in the consumer', () {
    final light = consumerTheme(Brightness.light).extension<KDesignTokens>()!;
    final dark = consumerTheme(Brightness.dark).extension<KDesignTokens>()!;

    expect(light.colorActionPrimaryBackground, const Color(0xFF6D28D9));
    expect(light.colorActionPrimaryForeground, Colors.white);
    expect(dark.colorActionPrimaryBackground, const Color(0xFFC4B5FD));
    expect(dark.colorActionPrimaryForeground, const Color(0xFF1F1633));
  });
}
