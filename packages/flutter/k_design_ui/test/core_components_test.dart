import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget _app(
  Widget child, {
  double width = 393,
  double height = 800,
  double textScale = 1,
}) => MaterialApp(
  theme: kDesignTheme(),
  home: MediaQuery(
    data: MediaQueryData(
      size: Size(width, height),
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view
      ..physicalSize = const Size(1200, 900)
      ..devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  group('KListItem', () {
    testWidgets('navigating row is one button with a chevron', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          KList(
            children: [
              KListItem(
                title: 'Account',
                leadingIcon: KIconName.user,
                onPressed: () => taps++,
              ),
              const KListItem(title: 'Version', trailing: KText('1.0')),
            ],
          ),
        ),
      );
      expect(find.byType(KIcon), findsNWidgets(2)); // leading + chevron
      await tester.tap(find.text('Account'));
      expect(taps, 1);
    });

    testWidgets('trailing moves under the title from 1.3x text', (
      tester,
    ) async {
      Future<(double, double)> positions(double scale) async {
        await tester.pumpWidget(
          _app(
            const KListItem(title: 'Storage', trailing: KText('12 GB')),
            textScale: scale,
          ),
        );
        return (
          tester.getTopLeft(find.text('Storage')).dy,
          tester.getTopLeft(find.text('12 GB')).dy,
        );
      }

      final (titleTop, valueTop) = await positions(1);
      expect((valueTop - titleTop).abs(), lessThan(4));
      final (largeTitleTop, largeValueTop) = await positions(1.3);
      expect(largeValueTop, greaterThan(largeTitleTop + 10));
    });
  });

  group('KSegmentedControl', () {
    const segments = [
      KSegment(value: 'day', label: 'Day'),
      KSegment(value: 'week', label: 'Week'),
      KSegment(value: 'month', label: 'Month'),
    ];

    testWidgets('selects, plays a selection haptic and exposes state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final cues = <KHapticCue>[];
      final haptics = KHapticController(
        enabled: true,
        backend: _Recorder(cues),
        minInterval: Duration.zero,
      );
      addTearDown(haptics.dispose);
      var value = 'day';
      await tester.pumpWidget(
        _app(
          KHapticsProvider(
            controller: haptics,
            child: StatefulBuilder(
              builder: (context, setState) => KSegmentedControl<String>(
                label: 'Period',
                segments: segments,
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(value, 'week');
      expect(cues, [KHapticCue.selection]);
      await tester.tap(find.text('Week'));
      expect(cues, hasLength(1));
      expect(
        tester.getSemantics(find.text('Week')),
        matchesSemantics(
          label: 'Week',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('three segments stack from 1.3x text', (tester) async {
      await tester.pumpWidget(
        _app(
          KSegmentedControl<String>(
            label: 'Period',
            segments: segments,
            value: 'day',
            onChanged: (_) {},
          ),
          textScale: 1.3,
        ),
      );
      expect(
        tester.getTopLeft(find.text('Week')).dy,
        greaterThan(tester.getTopLeft(find.text('Day')).dy),
      );
    });

    testWidgets('rejects more than five segments', (tester) async {
      await tester.pumpWidget(
        _app(
          KSegmentedControl<int>(
            label: 'Too many',
            segments: [
              for (var i = 0; i < 6; i++) KSegment(value: i, label: '$i'),
            ],
            value: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('KPageHeader', () {
    Widget header() => KPageHeader(
      title: 'Portfolio',
      subtitle: '3 buildings',
      backLabel: 'Back to Portfolios',
      onBack: () {},
      actions: [KButton(label: 'Add', onPressed: () {})],
    );

    testWidgets('compact: large title under back and actions', (tester) async {
      await tester.pumpWidget(_app(header()));
      final backBottom = tester.getBottomLeft(find.byType(KBackButton)).dy;
      expect(
        tester.getTopLeft(find.text('Portfolio')).dy,
        greaterThanOrEqualTo(backBottom),
      );
      expect(
        tester.getTopLeft(find.text('Add')).dy,
        lessThan(tester.getTopLeft(find.text('Portfolio')).dy),
      );
    });

    testWidgets('wide: title between back and actions', (tester) async {
      await tester.pumpWidget(_app(header(), width: 1000));
      final back = tester.getRect(find.byType(KBackButton));
      final title = tester.getRect(find.text('Portfolio'));
      expect(title.left, greaterThan(back.right));
      expect(title.top, lessThan(back.bottom));
    });

    testWidgets('actions move under the title from 1.3x text', (tester) async {
      await tester.pumpWidget(_app(header(), textScale: 1.3));
      expect(
        tester.getTopLeft(find.text('Add')).dy,
        greaterThan(tester.getBottomLeft(find.text('Portfolio')).dy),
      );
    });
  });

  group('KAppShell', () {
    const destinations = [
      KAppDestination(id: 'home', label: 'Home', icon: KIconName.house),
      KAppDestination(id: 'search', label: 'Search', icon: KIconName.search),
      KAppDestination(
        id: 'settings',
        label: 'Settings',
        icon: KIconName.settings,
      ),
    ];

    Widget shell(ValueChanged<String> onSelected) => SizedBox.expand(
      child: KAppShell(
        destinations: destinations,
        selectedId: 'home',
        onSelected: onSelected,
        sidebarHeader: const KText('Assetry'),
        child: const Center(child: KText('Content')),
      ),
    );

    testWidgets('compact uses a tab bar', (tester) async {
      String? selected;
      await tester.pumpWidget(_app(shell((id) => selected = id)));
      expect(find.byType(KMobileAppBar), findsOneWidget);
      expect(
        tester
            .widget<KMobileAppBar>(find.byType(KMobileAppBar))
            .labelVisibility,
        KMobileAppBarLabelVisibility.always,
      );
      expect(find.byType(KSidebar), findsNothing);
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(selected, 'search');
    });

    testWidgets('medium uses a rail, expanded a full sidebar', (tester) async {
      await tester.pumpWidget(_app(shell((_) {}), width: 700));
      expect(
        tester.widget<KSidebar>(find.byType(KSidebar)).mode,
        KSidebarMode.rail,
      );
      expect(find.text('Assetry'), findsNothing);
      await tester.pumpWidget(_app(shell((_) {}), width: 1000));
      await tester.pumpAndSettle();
      expect(
        tester.widget<KSidebar>(find.byType(KSidebar)).mode,
        KSidebarMode.expanded,
      );
      expect(find.text('Assetry'), findsOneWidget);
      expect(find.byType(KMobileAppBar), findsNothing);
    });
  });
}

class _Recorder implements KHapticBackend {
  _Recorder(this.cues);
  final List<KHapticCue> cues;
  @override
  Future<void> perform(KHapticCue cue) async => cues.add(cue);
}
