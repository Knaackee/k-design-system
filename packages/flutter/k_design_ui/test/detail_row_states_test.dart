import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final selected in [false, true]) {
    testWidgets('single row selected=$selected uses list selection surface', (
      tester,
    ) async {
      final theme = kDesignTheme();
      final tokens = theme.extension<KDesignTokens>()!;
      var activated = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: KDataTableSingleRow<String>(
              row: 'Customer',
              selected: selected,
              content: KDataTableSingleColumn<String>(
                title: Text.new,
                semanticsLabel: (row) => row,
                columnLabel: 'Bookings',
                onActivate: (_) => activated = true,
              ),
            ),
          ),
        ),
      );
      final state = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(KDataTableSingleRow<String>),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(state.properties.selected, selected);
      final surface = find.descendant(
        of: find.byType(KDataTableSingleRow<String>),
        matching: find.byType(Material),
      );
      if (selected) {
        expect(
          tester.widget<Material>(surface).color,
          tokens.colorBrandPrimaryBackground,
        );
      } else {
        expect(surface, findsNothing);
      }
      await tester.tap(find.text('Customer'));
      expect(activated, isTrue);
    });
  }
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('selected row is visibly tinted above the list $brightness', (
      tester,
    ) async {
      final theme = kDesignTheme(
        brightness: brightness,
        configuration: const KDesignConfiguration(style: KStyle.apple),
        tokenTransform: (t) => t.withAccent(const Color(0xFF0C679F)),
      );
      final tokens = theme.extension<KDesignTokens>()!;
      const paintKey = ValueKey('list-paint');
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: RepaintBoundary(
              key: paintKey,
              child: KList(
                children: [
                  KDataTableSingleRow<String>(
                    row: 'Selected customer',
                    selected: true,
                    content: KDataTableSingleColumn<String>(
                      title: Text.new,
                      semanticsLabel: (row) => row,
                      columnLabel: 'Bookings',
                      onActivate: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(paintKey),
      );
      final sampled = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset =
            ((image.height ~/ 2) * image.width + image.width - 24) * 4;
        final color = Color.fromARGB(
          pixels.getUint8(offset + 3),
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2),
        );
        image.dispose();
        return color;
      });
      expect(sampled, isNotNull);
      final expected = tokens.colorBrandPrimaryBackground;
      expect(sampled!.r, closeTo(expected.r, 1 / 255));
      expect(sampled.g, closeTo(expected.g, 1 / 255));
      expect(sampled.b, closeTo(expected.b, 1 / 255));
      expect(sampled, isNot(tokens.colorSurfaceRaised));
    });
  }
  for (final tone in KListItemTone.values) {
    testWidgets('list tone $tone keeps description muted', (tester) async {
      final theme = kDesignTheme();
      final tokens = theme.extension<KDesignTokens>()!;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: KList(
              children: [
                KListItem(
                  title: 'Cancel',
                  description: 'Booking action',
                  leadingIcon: KIconName.x,
                  tone: tone,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final texts = tester.widgetList<KText>(find.byType(KText));
      final title = texts.firstWhere((text) => text.data == 'Cancel');
      final description = texts.firstWhere(
        (text) => text.data == 'Booking action',
      );
      expect(description.style?.color, tokens.colorTextMuted);
      expect(
        title.style?.color,
        tone == KListItemTone.destructive
            ? tokens.colorStatusErrorAccent
            : null,
      );
      final icon = tester
          .widgetList<KIcon>(find.byType(KIcon))
          .firstWhere((icon) => icon.name == KIconName.x);
      expect(
        icon.color,
        tone == KListItemTone.destructive
            ? tokens.colorStatusErrorAccent
            : tokens.colorTextMuted,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
