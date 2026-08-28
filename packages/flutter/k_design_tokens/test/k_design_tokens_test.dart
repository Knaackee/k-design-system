import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  test('Orbit and reference themes expose different action colors', () {
    expect(
      KDesignTokens.orbitLight.colorActionPrimaryBackground,
      isNot(KDesignTokens.referenceLight.colorActionPrimaryBackground),
    );
  });

  test('theme helper installs the selected token extension', () {
    final theme = kDesignTheme(
      brand: KBrand.reference,
      brightness: Brightness.dark,
    );
    expect(theme.extension<KDesignTokens>(), same(KDesignTokens.referenceDark));
  });
}
