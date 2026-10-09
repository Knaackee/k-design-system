import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final activation in KFabActivation.values) {
    testWidgets('$activation separates menu activation from main action', (
      tester,
    ) async {
      var mainCalls = 0;
      var itemCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: KFab(
                  label: 'Main',
                  activation: activation,
                  onPressed: () => mainCalls++,
                  items: [
                    KFabItem(
                      id: 'one',
                      label: 'Other',
                      child: const Text('B'),
                      onSelected: () => itemCalls++,
                    ),
                  ],
                  child: const Text('A'),
                ),
              ),
            ),
          ),
        ),
      );
      if (activation == KFabActivation.longPress) {
        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();
        expect(mainCalls, 1);
        expect(find.text('B'), findsNothing);
        await tester.longPress(find.text('A'));
      } else {
        await tester.tap(find.text('A'));
      }
      await tester.pumpAndSettle();
      expect(mainCalls, activation == KFabActivation.longPress ? 1 : 0);
      expect(find.text('B'), findsOneWidget);
      expect(
        tester.getCenter(find.text('B')).dy,
        lessThan(tester.getCenter(find.text('A')).dy),
      );
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(itemCalls, 1);
      expect(find.text('B'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('new attention replaces the active notice immediately', (
    tester,
  ) async {
    late StateSetter update;
    var notices = <KFabAttention>[
      const KFabAttention(id: 'first', itemId: 'one'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Center(
                child: KFab(
                  label: 'Main',
                  attention: notices,
                  items: [
                    KFabItem(
                      id: 'one',
                      label: 'First',
                      onSelected: () {},
                      child: const Text('B'),
                    ),
                    KFabItem(
                      id: 'two',
                      label: 'Second',
                      onSelected: () {},
                      child: const Text('C'),
                    ),
                    KFabItem(
                      id: 'three',
                      label: 'Third',
                      onSelected: () {},
                      child: const Text('D'),
                    ),
                  ],
                  child: const Text('A'),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('k-fab-attention-first')), findsOneWidget);

    update(() {
      notices = [
        const KFabAttention(id: 'first', itemId: 'one'),
        const KFabAttention(id: 'second', itemId: 'two'),
      ];
    });
    await tester.pump();

    expect(find.byKey(const ValueKey('k-fab-attention-first')), findsNothing);
    expect(
      find.byKey(const ValueKey('k-fab-attention-second')),
      findsOneWidget,
    );

    update(() {
      notices.add(const KFabAttention(id: 'third', itemId: 'three'));
    });
    await tester.pump();

    expect(find.byKey(const ValueKey('k-fab-attention-second')), findsNothing);
    expect(find.byKey(const ValueKey('k-fab-attention-third')), findsOneWidget);
  });

  testWidgets('attention starts when appended to an initially empty queue', (
    tester,
  ) async {
    late StateSetter update;
    final notices = <KFabAttention>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: 24,
                bottom: 24,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return KFab(
                      label: 'Main',
                      attention: notices,
                      attentionPeekFraction: .75,
                      attentionHoldDuration: const Duration(milliseconds: 2000),
                      items: [
                        KFabItem(
                          id: 'one',
                          label: 'First',
                          onSelected: () {},
                          child: const Text('B'),
                        ),
                      ],
                      child: const Text('A'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('k-fab-attention-notice')), findsNothing);

    update(() {
      notices.add(const KFabAttention(id: 'notice', itemId: 'one'));
    });
    await tester.pump();
    final main = tester.getRect(find.byType(KChatBubble).last);
    final attentionFinder = find.byKey(
      const ValueKey('k-fab-attention-notice'),
    );
    expect(attentionFinder, findsOneWidget);

    await tester.pump(const Duration(microseconds: 175610));
    final attention = tester.getRect(attentionFinder);
    expect(main.top - attention.top, closeTo(48, .2));
    expect(main.bottom, closeTo(576, .1));
  });

  testWidgets('attention selection emits before item action without autoack', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: KFab(
              label: 'Main',
              attention: const [KFabAttention(id: 'notice', itemId: 'one')],
              onAttentionSelect: (_) => calls.add('notice'),
              items: [
                KFabItem(
                  id: 'one',
                  label: 'First',
                  onSelected: () => calls.add('item'),
                  child: const Text('B'),
                ),
              ],
              child: const Text('A'),
            ),
          ),
        ),
      ),
    );
    final main = tester.getRect(find.byType(KChatBubble).last);
    final attention = tester.getRect(
      find.byKey(const ValueKey('k-fab-attention-notice')),
    );
    final exposedPoint = Offset(attention.center.dx, attention.top + 8);
    expect(exposedPoint.dy, lessThan(main.top));
    await tester.tapAt(exposedPoint);
    await tester.pump();

    expect(calls, ['notice', 'item']);
    expect(
      find.byKey(const ValueKey('k-fab-attention-notice')),
      findsOneWidget,
    );
  });

  testWidgets('attention honors configured distance and hold duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Center(
          child: KFab(
            label: 'Main',
            attention: const [KFabAttention(id: 'notice', itemId: 'one')],
            attentionShowDuration: const Duration(milliseconds: 1000),
            attentionHoldDuration: const Duration(milliseconds: 400),
            attentionPeekFraction: .75,
            items: [
              KFabItem(
                id: 'one',
                label: 'First',
                onSelected: () {},
                child: const Text('B'),
              ),
            ],
            child: const Text('A'),
          ),
        ),
      ),
    );
    final mainCenter = tester.getCenter(find.text('A'));

    await tester.pump(const Duration(microseconds: 175610));
    expect(
      mainCenter.dy - tester.getCenter(find.text('B')).dy,
      closeTo(48, .2),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      mainCenter.dy - tester.getCenter(find.text('B')).dy,
      closeTo(48, .2),
    );
    await tester.pump(const Duration(milliseconds: 180));
    expect(mainCenter.dy - tester.getCenter(find.text('B')).dy, lessThan(46));
  });

  testWidgets('attention animation disposes with pending work', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KFab(
          label: 'Main',
          attention: const [KFabAttention(id: 'notice', itemId: 'one')],
          attentionShowDuration: const Duration(milliseconds: 600),
          attentionHoldDuration: Duration.zero,
          attentionPauseDuration: const Duration(milliseconds: 10),
          items: [
            KFabItem(
              id: 'one',
              label: 'First',
              onSelected: () {},
              child: const Text('B'),
            ),
          ],
          child: const Text('A'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 610));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary click toggles the menu open and closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Align(
          alignment: Alignment.bottomRight,
          child: KFab(
            label: 'Main',
            items: [
              KFabItem(
                id: 'one',
                label: 'Other',
                child: const Text('B'),
                onSelected: () {},
              ),
            ],
            child: const Text('A'),
          ),
        ),
      ),
    );

    final trigger = tester.getCenter(find.text('A'));
    await tester.tapAt(trigger, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);

    await tester.tapAt(trigger, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsNothing);
  });

  testWidgets('itemGap spaces menu items and the main trigger equally', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Align(
          alignment: Alignment.bottomRight,
          child: KFab(
            label: 'Main',
            itemGap: 20,
            items: [
              KFabItem(
                id: 'one',
                label: 'One',
                child: const Text('B'),
                onSelected: () {},
              ),
              KFabItem(
                id: 'two',
                label: 'Two',
                child: const Text('C'),
                onSelected: () {},
              ),
            ],
            child: const Text('A'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    Rect bubbleRect(String text) => tester.getRect(
      find.ancestor(of: find.text(text), matching: find.byType(KChatBubble)),
    );
    final main = bubbleRect('A');
    final first = bubbleRect('B');
    final second = bubbleRect('C');
    expect(second.top - first.bottom, closeTo(20, .1));
    expect(main.top - second.bottom, closeTo(20, .1));
  });

  testWidgets('menu children mount before opening and retain state', (
    tester,
  ) async {
    var mounts = 0;
    var disposals = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Align(
          alignment: Alignment.bottomRight,
          child: KFab(
            label: 'Main',
            items: [
              KFabItem(
                id: 'one',
                label: 'Other',
                child: _MountProbe(
                  onMount: () => mounts++,
                  onDispose: () => disposals++,
                ),
                onSelected: () {},
              ),
            ],
            child: const Text('A'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(mounts, 1);
    expect(disposals, 0);
    expect(find.byType(_MountProbe), findsNothing);
    expect(find.byType(_MountProbe, skipOffstage: false), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.byType(_MountProbe), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(mounts, 1);
      expect(disposals, 0);
    }
  });
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount, required this.onDispose});

  final VoidCallback onMount;
  final VoidCallback onDispose;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Probe');
}
