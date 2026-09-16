import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('button activates once and renders from theme tokens', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Center(
          child: KButton(label: 'Continue', onPressed: () => activations += 1),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    expect(activations, 1);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('loading button blocks activation', (tester) async {
    var activated = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KButton(
          label: 'Saving',
          loading: true,
          onPressed: () => activated = true,
        ),
      ),
    );

    await tester.tap(find.text('Saving'));
    expect(activated, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('button states use tokens without Material overlays', (
    tester,
  ) async {
    final tokens = kDesignTokens();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KButton(label: 'Continue', onPressed: () {}),
      ),
    );

    final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;

    expect(
      style.backgroundColor!.resolve({WidgetState.hovered}),
      tokens.colorActionPrimaryHover,
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.pressed}),
      tokens.colorActionPrimaryPressed,
    );
    expect(
      style.overlayColor!.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(style.elevation!.resolve({WidgetState.pressed}), 0);
    expect(
      style.surfaceTintColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
  });

  testWidgets('button variants resolve their semantic token palettes', (
    tester,
  ) async {
    final tokens = kDesignTokens();
    final cases = [
      (
        KButtonVariant.primary,
        tokens.colorActionPrimaryBackground,
        tokens.colorActionPrimaryForeground,
        Colors.transparent,
      ),
      (
        KButtonVariant.secondary,
        tokens.colorActionSecondaryBackground,
        tokens.colorActionSecondaryForeground,
        tokens.colorActionSecondaryBorder,
      ),
      (
        KButtonVariant.ghost,
        tokens.colorActionGhostBackground,
        tokens.colorActionGhostForeground,
        tokens.colorActionGhostBorder,
      ),
    ];

    for (final (variant, background, foreground, border) in cases) {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: KButton(
            label: variant.name,
            variant: variant,
            onPressed: () {},
          ),
        ),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(style.backgroundColor!.resolve({}), background);
      expect(style.foregroundColor!.resolve({}), foreground);
      expect(style.side!.resolve({})!.color, border);
    }
  });

  testWidgets('text primitive uses the shared type tokens and heading level', (
    tester,
  ) async {
    final tokens = kDesignTokens();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const KText('Product direction', variant: KTextVariant.heading1),
      ),
    );

    final text = tester.widget<Text>(find.text('Product direction'));
    expect(text.style!.fontFamily, tokens.fontFamily);
    expect(text.style!.fontSize, tokens.fontHeading1Size);
    expect(text.style!.height, tokens.fontHeading1LineHeight / 28);
    expect(text.style!.fontVariations, isNotEmpty);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any((widget) => widget.properties.headingLevel == 1),
      isTrue,
    );
  });

  testWidgets('surface maps semantic tone, border, radius and elevation', (
    tester,
  ) async {
    final tokens = kDesignTokens();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const KSurface(
          tone: KSurfaceTone.subtle,
          border: KSurfaceBorder.strong,
          radius: KSurfaceRadius.overlay,
          elevation: KSurfaceElevation.medium,
          child: SizedBox(width: 100, height: 80),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.color, tokens.colorSurfaceSubtle);
    expect((decoration.border! as Border).top.color, tokens.colorBorderStrong);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(tokens.radiusOverlay),
    );
    expect(decoration.boxShadow, tokens.elevationMedium);
  });

  testWidgets('borderless surfaces do not create Flutter hairline borders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const KSurface(border: KSurfaceBorder.none, child: SizedBox()),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((decorated.decoration as BoxDecoration).border, isNull);
  });

  testWidgets('card uses semantic card radius and padding without elevation', (
    tester,
  ) async {
    final tokens = kDesignTokens();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const KCard(child: Text('Project settings')),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(tokens.radiusCard));
    expect(decoration.boxShadow, tokens.elevationNone);
    expect(
      tester
          .widget<Padding>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Padding &&
                  widget.padding == EdgeInsets.all(tokens.spaceCardPadding),
            ),
          )
          .padding,
      EdgeInsets.all(tokens.spaceCardPadding),
    );
  });
}
