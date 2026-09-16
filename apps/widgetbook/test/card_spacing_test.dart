import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('packages/k_design_tokens/Inter');
    loader.addFont(
      File(
        '../../packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await loader.load();
  });
  for (final width in [375.0, 1024.0]) {
    for (final density in KDensity.values) {
      testWidgets('card geometry at $width / ${density.name}', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final brand in KBrand.values) {
          for (final brightness in Brightness.values) {
            for (final typeScale in KTypeScale.values) {
              for (final inputMode in KInputMode.values) {
                for (final scale in [1.0, 2.0]) {
                  final configuration = KDesignConfiguration(
                    density: density,
                    typeScale: typeScale,
                    inputMode: inputMode,
                    windowClass: kWindowClassForWidth(width),
                  );
                  final tokens = kDesignTokens(
                    brand: brand,
                    brightness: brightness,
                    configuration: configuration,
                  );
                  await tester.pumpWidget(
                    MaterialApp(
                      theme: kDesignTheme(
                        brand: brand,
                        brightness: brightness,
                        configuration: configuration,
                      ),
                      home: MediaQuery(
                        data: MediaQueryData(
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: const Builder(builder: buildCardVariants),
                      ),
                    ),
                  );
                  await tester.pumpAndSettle();
                  final cards = find.byType(KCard);
                  final first = tester.getRect(cards.at(0));
                  final second = tester.getRect(cards.at(1));
                  final available = math.min(
                    760.0,
                    width - 2 * tokens.spaceLayoutGutter,
                  );
                  final columns = width < 600 ? 1 : 2;
                  expect(
                    first.width,
                    closeTo(
                      (available -
                              (columns - 1) * tokens.spaceLayoutSectionGap) /
                          columns,
                      .5,
                    ),
                  );
                  if (columns == 1) {
                    expect(
                      second.top - first.bottom,
                      closeTo(tokens.spaceLayoutSectionGap, .5),
                    );
                  } else {
                    expect(
                      second.left - first.right,
                      closeTo(tokens.spaceLayoutSectionGap, .5),
                    );
                    expect(second.top, first.top);
                  }
                  for (final (index, title, copy, action) in [
                    (
                      0,
                      'Project settings',
                      'Default cards use a fine border and no shadow.',
                      'Configure',
                    ),
                    (
                      1,
                      'Quiet grouping',
                      'Subtle tone separates content without added depth.',
                      'View details',
                    ),
                  ]) {
                    final heading = tester.getRect(find.text(title));
                    final body = tester.getRect(find.text(copy));
                    final button = tester.getRect(
                      find.ancestor(
                        of: find.text(action),
                        matching: find.byType(KButton),
                      ),
                    );
                    final visible = find.descendant(
                      of: find.ancestor(
                        of: find.text(action),
                        matching: find.byType(FilledButton),
                      ),
                      matching: find.byType(Material),
                    );
                    expect(
                      tester.getSize(visible).height,
                      closeTo(tokens.sizeControl, .5),
                    );
                    final card = tester.getRect(cards.at(index));
                    expect(
                      body.top - heading.bottom,
                      closeTo(tokens.spaceControlGap, .5),
                    );
                    expect(
                      button.top - body.bottom,
                      closeTo(tokens.spaceContentActionGap, .5),
                    );
                    expect(
                      heading.left - card.left,
                      closeTo(
                        tokens.spaceCardPadding + tokens.borderWidthDefault,
                        .5,
                      ),
                    );
                    expect(
                      heading.top - card.top,
                      closeTo(
                        tokens.spaceCardPadding + tokens.borderWidthDefault,
                        .5,
                      ),
                    );
                    expect(
                      heading.height,
                      closeTo(
                        tokens.fontHeading4LineHeight *
                            scale *
                            (heading.height /
                                    (tokens.fontHeading4LineHeight * scale))
                                .round(),
                        .5,
                      ),
                    );
                    expect(
                      button.height,
                      greaterThanOrEqualTo(tokens.sizeHitTarget),
                    );
                  }
                  expect(tester.takeException(), isNull);
                }
              }
            }
          }
        }
      });
    }
  }
}
