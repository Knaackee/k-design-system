import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget fixture({
    VoidCallback? edit,
    void Function(String, String, String?)? move,
    String Function(String)? translate,
    void Function(String, List<String>, int, int)? reorder,
  }) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: KOfferOverview(
            onAddCategory: () {},
            newActions: const [],
            onReorderEntries: reorder,
            onMoveEntry: move,
            translate: translate,
            categories: [
              KOfferCategory(
                id: 'c1',
                name: 'Haarschnitt & Styling',
                description: 'Eine Kategorie mit langer Beschreibung',
                onAdd: () {},
                entries: [
                  KOfferEntry(
                    id: 's1',
                    name: 'Langhaarschnitt mit Pflegekur und Föhnfrisur',
                    kind: 'service',
                    price: '58,00 €',
                    detail: '60 Min.',
                    onEdit: edit ?? () {},
                    actions: [
                      KMenuAction(
                        id: 'edit',
                        label: 'Bearbeiten',
                        onSelect: () {},
                      ),
                    ],
                  ),
                  KOfferEntry(
                    id: 'p1',
                    name: 'Styling-Set',
                    kind: 'product',
                    price: '24,90 €',
                    detail: '12 verfügbar',
                    onEdit: () {},
                  ),
                ],
              ),
              if (move != null)
                KOfferCategory(
                  id: 'c2',
                  name: 'Zweite Kategorie',
                  entries: const [],
                  onAdd: () {},
                ),
            ],
          ),
        ),
      ),
    ),
  );
  testWidgets('compact list search filters and empty recovery retain hint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(fixture());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Halten und ziehen'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(KButton, 'Produkte · 1'));
    await tester.tap(find.widgetWithText(KButton, 'Produkte · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Styling-Set'), findsOneWidget);
    expect(
      find.text('Langhaarschnitt mit Pflegekur und Föhnfrisur'),
      findsNothing,
    );
    await tester.enterText(find.byType(TextField), 'nicht vorhanden');
    await tester.pumpAndSettle();
    expect(find.text('Keine passenden Angebote'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Filter zurücksetzen'));
    await tester.pumpAndSettle();
    expect(find.text('Styling-Set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('long press reorders whole item without opening editor', (
    tester,
  ) async {
    var edits = 0;
    List<Object>? moved;
    await tester.pumpWidget(
      fixture(
        edit: () => edits++,
        reorder: (c, ids, from, to) => moved = [c, ids, from, to],
      ),
    );
    await tester.pumpAndSettle();
    final row = find.text('Langhaarschnitt mit Pflegekur und Föhnfrisur');
    final start = tester.getCenter(row);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 5));
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.text('Styling-Set')) + const Offset(0, 20),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(edits, 0);
    expect(moved, isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop also shows sorting hint and no grip handles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(fixture());
    await tester.pumpAndSettle();
    expect(find.textContaining('Halten und ziehen'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is KIcon && w.name == KIconName.gripVertical,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'long press moves to an empty category and passes host identity',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      List<String?>? moved;
      await tester.pumpWidget(
        fixture(
          reorder: (_, _, _, _) {},
          move: (id, category, before) => moved = [id, category, before],
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Styling-Set')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final add = find.widgetWithText(KButton, 'Angebot hinzufügen').last;
      await gesture.moveTo(tester.getTopLeft(add) + const Offset(40, -20));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moved, ['p1', 'c2', null]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'host can localize interface copy without translating business names',
    (tester) async {
      await tester.pumpWidget(
        fixture(translate: (s) => s == 'Angebot' ? 'Offers' : s),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Styling-Set'), findsOneWidget);
    },
  );
}
