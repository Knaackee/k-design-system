import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  home: KAdaptiveTheme(
    overrides: const KAdaptiveOverrides(style: KStyle.apple),
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: KPage(children: [child])),
      ),
    ),
  ),
);
void main() {
  testWidgets(
    'four full action labels remain usable at phone widths and large text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 2.0]) {
        var copied = 0;
        await tester.pumpWidget(
          host(
            KBookingPageActions(
              compact: true,
              actions: [
                KBookingPageAction(
                  label: 'Teilen',
                  icon: KIconName.share,
                  onPressed: () {},
                  primary: true,
                ),
                KBookingPageAction(
                  label: 'Kopieren',
                  icon: KIconName.copy,
                  onPressed: () => copied++,
                ),
                KBookingPageAction(
                  label: 'QR-Code',
                  icon: KIconName.qrCode,
                  onPressed: () {},
                ),
              ],
              previewAction: KBookingPageAction(
                label: 'Vorschau',
                icon: KIconName.eye,
                onPressed: () {},
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final share = find.descendant(
          of: find.widgetWithText(KButton, 'Teilen'),
          matching: find.byType(KIcon),
        );
        final tokens = Theme.of(
          tester.element(share),
        ).extension<KDesignTokens>()!;
        expect(
          tester.widget<KIcon>(share).color,
          tokens.colorActionPrimaryForeground,
        );
        for (final label in ['Teilen', 'Kopieren', 'QR-Code', 'Vorschau']) {
          expect(find.text(label), findsOneWidget);
        }
        await tester.tap(find.text('Kopieren'));
        expect(copied, 1);
      }
    },
  );
  testWidgets(
    'carousel reaches all designs and swatches retain selected semantics',
    (tester) async {
      String selected = '0', color = 'blue';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => KBookingThemePicker(
              carousel: true,
              value: selected,
              onChanged: (id) => setState(() => selected = id),
              options: [
                for (var i = 0; i < 11; i++)
                  KBookingThemeChoice(
                    id: '$i',
                    label: 'Design $i',
                    image: const SizedBox(),
                  ),
              ],
              footer: KColorSwatches(
                label: 'Farbe',
                value: color,
                onChanged: (v) => setState(() => color = v),
                options: const [
                  KColorSwatch(
                    value: 'blue',
                    label: 'Blau',
                    color: Colors.blue,
                  ),
                  KColorSwatch(value: 'red', label: 'Rot', color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alle 11 ansehen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Design 10'));
      await tester.tap(find.text('Design 10'));
      await tester.pump();
      expect(selected, '10');
      await tester.ensureVisible(find.byTooltip('Rot'));
      await tester.tap(find.byTooltip('Rot'));
      await tester.pump();
      expect(color, 'red');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('icon-only shape control retains its accessible names', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KSegmentedControl(
          label: 'Bildform',
          showLabels: false,
          value: 'square',
          segments: const [
            KSegment(value: 'square', label: 'Eckig', icon: KIconName.square),
            KSegment(value: 'round', label: 'Rund', icon: KIconName.circle),
          ],
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Eckig'), findsNothing);
    expect(find.bySemanticsLabel('Eckig'), findsOneWidget);
    expect(find.bySemanticsLabel('Rund'), findsOneWidget);
  });
}
