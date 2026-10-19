import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  const validDraft = KIntegrationDraft(
    name: 'Linear',
    description: 'Issues als Kontext verwenden.',
    category: 'Planung',
    endpoint: 'https://mcp.example.test/linear',
  );

  test('integration validation accepts HTTPS and rejects unsafe endpoints', () {
    expect(validateKIntegrationDraft(validDraft), isEmpty);
    expect(
      validateKIntegrationDraft(
        validDraft.copyWith(endpoint: 'http://mcp.example.test/linear'),
      )['endpoint'],
      'Der Endpoint muss HTTPS verwenden.',
    );
    expect(
      validateKIntegrationDraft(
        validDraft.copyWith(endpoint: 'https://user@example.test/path#token'),
      )['endpoint'],
      contains('keine Zugangsdaten'),
    );
    expect(
      validateKIntegrationDraft(validDraft.copyWith(category: ''))['category'],
      'Bitte gib eine Kategorie ein.',
    );
    const localOrigin = 'http://127.0.0.1:15173';
    final localDraft = validDraft.copyWith(endpoint: '$localOrigin/mcp');
    expect(validateKIntegrationDraft(localDraft)['endpoint'], isNotNull);
    expect(
      validateKIntegrationDraft(
        localDraft,
        allowedHttpOrigins: const {localOrigin},
      ),
      isEmpty,
    );
  });

  testWidgets('editor resets tested status after a field changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    KIntegrationCatalogState? savedStatus;
    KIntegrationDraft? testedDraft;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KIntegrationEditor(
          value: validDraft,
          testSuccessMessage: 'Realer Verbindungstest erfolgreich.',
          onCancel: () {},
          onTest: (draft) async {
            testedDraft = draft;
            return true;
          },
          onSave: (_, status) => savedStatus = status,
          onPublish: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Verbindung testen'));
    await tester.pump();
    expect(testedDraft?.endpoint, validDraft.endpoint);
    expect(find.text('Getestet'), findsOneWidget);
    expect(find.text('Realer Verbindungstest erfolgreich.'), findsOneWidget);
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Veröffentlichen'))
          .onPressed,
      isNotNull,
    );

    await tester.enterText(find.byType(TextField).first, 'Linear Cloud');
    await tester.pump();
    expect(find.text('Entwurf'), findsOneWidget);
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Veröffentlichen'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Integration speichern'));
    await tester.pump();
    expect(savedStatus, KIntegrationCatalogState.draft);
  });

  testWidgets('stale async test results cannot re-enable publishing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final result = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KIntegrationEditor(
          value: validDraft,
          onCancel: () {},
          onTest: (_) => result.future,
          onSave: (_, _) {},
          onPublish: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Verbindung testen'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Changed during test');
    result.complete(true);
    await tester.pump();

    expect(find.text('Entwurf'), findsOneWidget);
    expect(find.text('Getestet'), findsNothing);
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Veröffentlichen'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Verbindung testen'))
          .loading,
      isFalse,
    );
  });

  testWidgets('failed test callback clears loading and keeps draft status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KIntegrationEditor(
          value: validDraft,
          testErrorMessage: 'Realer Verbindungstest nicht erreichbar.',
          onCancel: () {},
          onTest: (_) => Future<bool>.error(StateError('simulated')),
          onSave: (_, _) {},
          onPublish: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Verbindung testen'));
    await tester.pump();

    expect(find.text('Entwurf'), findsOneWidget);
    expect(
      find.text('Realer Verbindungstest nicht erreichbar.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Verbindung testen'))
          .loading,
      isFalse,
    );
  });

  testWidgets('icon picker blocks actions and reports callback failures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selection = Completer<KIntegrationIconSelection?>();
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KIntegrationEditor(
          value: validDraft,
          initialStatus: KIntegrationCatalogState.tested,
          onCancel: () {},
          onPickIcon: () {
            picks += 1;
            return selection.future;
          },
          onTest: (_) async => true,
          onSave: (_, _) {},
          onPublish: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Icon hochladen'));
    await tester.pump();
    expect(picks, 1);
    expect(
      tester
          .widget<KButton>(
            find.widgetWithText(KButton, 'Integration speichern'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Verbindung testen'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Veröffentlichen'))
          .onPressed,
      isNull,
    );

    selection.completeError(StateError('picker failed'));
    await tester.pump();
    expect(find.text('Das Icon konnte nicht gelesen werden.'), findsOneWidget);
    expect(
      tester
          .widget<KButton>(
            find.widgetWithText(KButton, 'Integration speichern'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('admin catalog opens every row through the edit callback', (
    tester,
  ) async {
    final item = KIntegrationCatalogItem(
      id: 'linear',
      name: 'Linear',
      category: 'Planung',
      description: 'Projekte und Issues nutzen.',
      endpoint: 'https://mcp.example.test/linear',
      icon: const Text('L'),
      catalogState: KIntegrationCatalogState.tested,
    );
    KIntegrationCatalogItem? edited;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KIntegrationAdminCatalog(
            integrations: [item],
            labels: const KIntegrationAdminCatalogLabels(preview: null),
            onCreate: () {},
            onEdit: (value) => edited = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Linear'));
    expect(edited, same(item));
    expect(find.text('Vorschau'), findsNothing);
    expect(find.text('Getestet'), findsOneWidget);
  });

  testWidgets('admin catalog filters and sorts lifecycle states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    KIntegrationCatalogItem item(
      String id,
      String name,
      String category,
      KIntegrationCatalogState state,
    ) => KIntegrationCatalogItem(
      id: id,
      name: name,
      category: category,
      description: '$name verwenden.',
      endpoint: 'https://mcp.example.test/$id',
      icon: Text(name.characters.first),
      catalogState: state,
    );
    final integrations = [
      item('zebra', 'Zebra', 'Planung', KIntegrationCatalogState.draft),
      item('beta', 'Beta', 'Entwicklung', KIntegrationCatalogState.published),
      item('alpha', 'Alpha', 'Planung', KIntegrationCatalogState.tested),
      item('able', 'Able', 'Entwicklung', KIntegrationCatalogState.published),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KIntegrationAdminCatalog(
            integrations: integrations,
            onCreate: () {},
            onEdit: (_) {},
          ),
        ),
      ),
    );

    expect(
      [
        'Able',
        'Beta',
        'Alpha',
        'Zebra',
      ].map((name) => tester.getTopLeft(find.text(name)).dy),
      orderedEquals(
        [
          'Able',
          'Beta',
          'Alpha',
          'Zebra',
        ].map((name) => tester.getTopLeft(find.text(name)).dy).toList()..sort(),
      ),
    );

    await tester.tap(find.text('Veröffentlicht').first);
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Able'), findsOneWidget);
    expect(find.text('Zebra'), findsNothing);
    expect(find.text('Alpha'), findsNothing);

    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KIntegrationAdminCatalog(
            integrations: integrations,
            activeCategory: 'Entwicklung',
            onCreate: () {},
            onEdit: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Able'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Zebra'), findsNothing);
  });
}
