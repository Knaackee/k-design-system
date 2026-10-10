import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/src/chat/k_web_search.dart';
import 'package:k_design_ui/src/primitives/k_animated_icon.dart';

final labels = KWebSearchLabels(
  title: 'Websuche',
  running: 'Suche läuft…',
  empty: 'Keine Quellen gefunden.',
  failed: 'Suche fehlgeschlagen',
  sourceCount: (count) => '$count Quellen',
);
const results = [
  KWebSearchResult(
    id: 'flutter',
    url: 'https://docs.flutter.dev/ui/animations',
    title: 'Flutter: Animationen und interaktive Oberflächen',
    description: 'Offizielle Dokumentation zu Animationen und Übergängen.',
  ),
];
Widget frame(Widget child, {double width = 320}) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets('leading title shimmers while arriving sources stay visible', (
    tester,
  ) async {
    Widget search(List<KWebSearchResult> sources) => frame(
      KWebSearch(
        id: 'search',
        state: KWebSearchState.running,
        labels: labels,
        results: sources,
      ),
    );
    await tester.pumpWidget(search(const []));
    expect(
      find.ancestor(
        of: find.text(labels.title),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text(labels.running),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );
    await tester.pumpWidget(search(results));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 Quellen'), findsOneWidget);
    expect(find.text(labels.running), findsNothing);
    expect(
      find.ancestor(
        of: find.text(labels.title),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disclosure reveals sources and delegates activation', (
    tester,
  ) async {
    KWebSearchResult? selected;
    await tester.pumpWidget(
      frame(
        KWebSearch(
          id: 'search',
          state: KWebSearchState.succeeded,
          query: 'Flutter Rive Foley Animationen',
          labels: labels,
          results: results,
          onSourceActivate: (result) => selected = result,
        ),
      ),
    );
    expect(find.text(results.first.title), findsNothing);
    await tester.tap(find.text('Websuche'));
    await tester.pumpAndSettle();
    expect(find.text('docs.flutter.dev'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(results.first.title));
    expect(selected?.id, 'flutter');
    await tester.tap(find.text('Websuche'));
    await tester.pumpAndSettle();
    expect(find.text(results.first.title), findsNothing);
  });

  testWidgets('controlled disclosure requests change without changing itself', (
    tester,
  ) async {
    bool? requested;
    await tester.pumpWidget(
      frame(
        KWebSearch(
          id: 'search',
          state: KWebSearchState.succeeded,
          labels: labels,
          results: results,
          expanded: false,
          onExpandedChanged: (value) => requested = value,
        ),
      ),
    );
    await tester.tap(find.text('Websuche'));
    await tester.pumpAndSettle();
    expect(requested, isTrue);
    expect(find.text(results.first.title), findsNothing);
  });

  testWidgets(
    'running empty and error states remain readable at narrow width',
    (tester) async {
      for (final state in KWebSearchState.values) {
        await tester.pumpWidget(
          frame(
            KWebSearch(
              id: state.name,
              state: state,
              labels: labels,
              query: 'Flutter Rive Foley Animationen',
              expanded: true,
              error: state == KWebSearchState.failed
                  ? 'Bitte erneut versuchen.'
                  : null,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.text(switch (state) {
            KWebSearchState.running => labels.running,
            KWebSearchState.succeeded => labels.empty,
            KWebSearchState.failed => 'Bitte erneut versuchen.',
          }),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('animated loading alternates and stops after completion', (
    tester,
  ) async {
    Widget search(KWebSearchState state) => frame(
      KWebSearch(
        id: 'search',
        state: state,
        labels: labels,
        loadingIndicator: KWebSearchLoadingIndicator.animatedIcon,
      ),
    );
    await tester.pumpWidget(search(KWebSearchState.running));
    expect(find.byType(KAnimatedIcon), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(search(KWebSearchState.succeeded));
    await tester.pumpAndSettle();
    expect(find.byType(KAnimatedIcon), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion disables both loading animations', (
    tester,
  ) async {
    for (final indicator in KWebSearchLoadingIndicator.values) {
      await tester.pumpWidget(
        frame(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: KWebSearch(
              id: 'search',
              state: KWebSearchState.running,
              labels: labels,
              loadingIndicator: indicator,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text(labels.running), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
