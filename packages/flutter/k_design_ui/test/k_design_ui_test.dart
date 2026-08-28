import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  test('UI package can consume the token package', () {
    expect(kUiPackageReady, isTrue);
  });
}
