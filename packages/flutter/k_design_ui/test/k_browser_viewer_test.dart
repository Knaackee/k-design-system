import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [360.0, 393.0]) {
    testWidgets('fullscreen and close stay fully tappable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool maximized = false;
      int closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => KBrowserViewer(
                status: 'Live verbunden',
                humanControl: true,
                maximized: maximized,
                onMaximizedChanged: (value) =>
                    setState(() => maximized = value),
                onTakeControl: () {},
                onPause: () {},
                onStop: () {},
                onKeyboard: () {},
                onClose: () => closed++,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      Finder button(String label) =>
          find.byWidgetPredicate((w) => w is KIconButton && w.label == label);
      final close = button('Browser schließen');
      for (final label in ['Vollbild umschalten', 'Vollbild verlassen']) {
        if (maximized) {
          await tester.tap(find.byTooltip('Browsersteuerung anzeigen'));
          await tester.pump();
        }
        final fullscreen = button(label);
        expect(tester.getSize(fullscreen), tester.getSize(close));
        expect(
          find.ancestor(
            of: fullscreen,
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
        );
        expect(
          fullscreen.hitTestable(at: const Alignment(-.9, 0)),
          findsOneWidget,
        );
        expect(
          fullscreen.hitTestable(at: const Alignment(.9, 0)),
          findsOneWidget,
        );
        await tester.tap(fullscreen);
        await tester.pump();
        expect(maximized, label == 'Vollbild umschalten');
      }
      await tester.tap(close);
      expect(closed, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 393.0, 840.0, 1200.0]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets('floating controls preserve surface at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const surface = ValueKey('test-browser-surface');
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 852),
                textScaler: TextScaler.linear(scale),
              ),
              child: KAdaptiveTheme(
                child: Scaffold(
                  body: KBrowserViewer(
                    maximized: true,
                    height: 740,
                    humanControl: true,
                    status: 'Du steuerst',
                    onTakeControl: () {},
                    onPause: () {},
                    onStop: () {},
                    onClose: () {},
                    onMaximizedChanged: (_) {},
                    child: const SizedBox.expand(key: surface),
                  ),
                ),
              ),
            ),
          ),
        );
        final before = tester.getRect(find.byKey(surface));
        final toggle = find.byTooltip('Browsersteuerung anzeigen');
        expect(tester.getSize(toggle).shortestSide, greaterThanOrEqualTo(44));
        await tester.tap(toggle);
        await tester.pump();
        expect(tester.getRect(find.byKey(surface)), before);
        expect(find.byTooltip('Browsersteuerung ausblenden'), findsOneWidget);
        expect(
          find
              .byWidgetPredicate(
                (w) => w is KIconButton && w.label == 'Browser schließen',
              )
              .hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Browsersteuerung ausblenden'));
        await tester.pump();
        expect(tester.getRect(find.byKey(surface)), before);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final maximized in [false, true]) {
    for (final state in ['working', 'question']) {
      testWidgets('status paint and target stay complete: $maximized/$state', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        var navigation = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: KAdaptiveTheme(
              child: Scaffold(
                body: RepaintBoundary(
                  key: capture,
                  child: KBrowserViewer(
                    maximized: maximized,
                    transportHandlesGestures: true,
                    height: 740,
                    working: state == 'working',
                    permissionPending: state == 'question',
                    status: state,
                    onTakeControl: () {},
                    onPause: () {},
                    onStop: () {},
                    onClose: () {},
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 48,
                          width: 48,
                          height: 20,
                          child: GestureDetector(
                            onTap: () => navigation++,
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final dot = find.byType(KActivityDot);
        final visual = tester.widget<KActivityDot>(dot);
        expect(visual.animation, KActivityDotAnimation.auto);
        expect(visual.size, greaterThan(14));
        final paint = find.descendant(
          of: dot,
          matching: find.byType(CustomPaint),
        );
        final paintRect = tester.getRect(paint);
        final surfaceBefore = tester.getRect(find.byType(InteractiveViewer));
        if (maximized) {
          final toggle = find.byTooltip('Browsersteuerung anzeigen');
          final hitRect = tester.getRect(toggle);
          expect(hitRect.width, greaterThanOrEqualTo(64));
          expect(hitRect.height, 48);
          expect(
            hitRect.contains(paintRect.topLeft - const Offset(2, 2)),
            isTrue,
          );
          expect(
            hitRect.contains(paintRect.bottomRight + const Offset(2, 2)),
            isTrue,
          );
          await tester.tapAt(const Offset(18, 54));
          expect(
            navigation,
            1,
          ); // Real Chromium Back sits below the status pill.
          await tester.tapAt(
            const Offset(60, 24),
          ); // Widened edge is part of the action.
          await tester.pump();
          expect(find.byTooltip('Browsersteuerung ausblenden'), findsOneWidget);
          expect(tester.getRect(paint), paintRect);
          expect(tester.getRect(find.byType(InteractiveViewer)), surfaceBefore);
        }
        for (var phase = 0; phase < 4; phase++) {
          await tester.pump(const Duration(milliseconds: 120));
          expect(tester.getRect(paint), paintRect);
          final captureDirectory =
              Platform.environment['ORBIT_BROWSER_CAPTURE_DIR'];
          if (phase == 1 && captureDirectory != null) {
            await tester.runAsync(() async {
              final boundary =
                  capture.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final path =
                  '$captureDirectory/orbit-browser-$state-${maximized ? 'fullscreen' : 'dock'}.png';
              await File(path).writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('pending connection shows progress until a retryable failure', (
    tester,
  ) async {
    Widget frame(bool pending) => MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(
        body: KBrowserViewer(
          connected: false,
          pending: pending,
          status: 'Connecting',
          onTakeControl: null,
          onPause: null,
          onStop: null,
          onClose: () {},
          onReconnect: () {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpWidget(frame(true));
    expect(find.byType(KSpinner), findsOneWidget);
    expect(find.text('Erneut verbinden'), findsNothing);
    expect(
      tester.widget<KActivityDot>(find.byType(KActivityDot)).state,
      KActivityDotState.working,
    );
    await tester.pumpWidget(frame(false));
    expect(find.byType(KSpinner), findsNothing);
    expect(find.text('Erneut verbinden'), findsOneWidget);
  });
  testWidgets(
    'native transport receives gestures and reset without outer zoom',
    (tester) async {
      int reset = 0, taps = 0, keyboards = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KBrowserViewer(
              transportHandlesGestures: true,
              humanControl: true,
              onKeyboard: () => keyboards++,
              status: 'Live verbunden',
              onTakeControl: () {},
              onPause: () {},
              onStop: () {},
              onClose: () {},
              onResetView: () => reset++,
              child: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Local viewer gesture'),
                ),
              ),
            ),
          ),
        ),
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.scaleEnabled, false);
      expect(viewer.panEnabled, false);
      await tester.tap(find.text('Local viewer gesture'));
      expect(taps, 1);
      final resetButton = find.byWidgetPredicate(
        (w) => w is KIconButton && w.label == 'Ansicht zurücksetzen',
      );
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      expect(reset, 1);
      final keyboardButton = find.byWidgetPredicate(
        (w) => w is KIconButton && w.label == 'Tastatur öffnen',
      );
      await tester.ensureVisible(keyboardButton);
      await tester.tap(keyboardButton);
      expect(keyboards, 1);
    },
  );
  testWidgets('permission shrinks a mounted preview and user can enlarge it', (
    tester,
  ) async {
    bool permission = false;
    late StateSetter update;
    int mounts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KBrowserViewer(
                height: 360,
                permissionPending: permission,
                status: 'Live verbunden',
                onTakeControl: () {},
                onPause: () {},
                onStop: () {},
                onClose: () {},
                onMaximizedChanged: (_) {},
                child: _MountProbe(onMount: () => mounts++),
              );
            },
          ),
        ),
      ),
    );
    final panel = find.byKey(const ValueKey('browser-viewer'));
    expect(tester.getSize(panel).height, 360);
    update(() => permission = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(panel).height, 180);
    expect(mounts, 1);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.label == 'Browseransicht vergrößern',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(panel).height, 360);
    update(() => permission = false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(panel).height, 360);
    expect(mounts, 1);
  });

  testWidgets('human control enables page input and disables local panning', (
    tester,
  ) async {
    int clicks = 0;
    bool human = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KBrowserViewer(
                status: 'Live verbunden',
                humanControl: human,
                onTakeControl: () {},
                onPause: () {},
                onStop: () {},
                onClose: () {},
                cursor: const Offset(.5, .5),
                child: Center(
                  child: TextButton(
                    onPressed: () => clicks++,
                    child: const Text('Page action'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).maxScale,
      3,
    );
    await tester.tap(find.text('Page action'), warnIfMissed: false);
    expect(clicks, 0);
    expect(find.byType(KAgentCursor), findsOneWidget);
    update(() => human = true);
    await tester.pump();
    await tester.tap(find.text('Page action'));
    expect(clicks, 1);
    expect(
      tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .panEnabled,
      false,
    );
    expect(find.byType(KAgentCursor), findsNothing);
  });

  testWidgets('compact toolbar exposes close on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KBrowserViewer(
            permissionPending: true,
            status: 'Wartet auf deine Freigabe',
            onTakeControl: () {},
            onPause: () {},
            onStop: () {},
            onClose: () => closed++,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
    final toolbar = find.byKey(const ValueKey('browser-viewer-toolbar'));
    expect(
      find.descendant(of: toolbar, matching: find.byType(Wrap)),
      findsNothing,
    );
    expect(tester.getSize(toolbar).height, lessThanOrEqualTo(80));
    final close = find.byWidgetPredicate(
      (w) => w is KIconButton && w.label == 'Browser schließen',
    );
    expect(
      tester.getCenter(close).dy,
      closeTo(tester.getCenter(find.byType(KActivityDot)).dy, 1),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.label == 'Browser schließen',
      ),
    );
    expect(closed, 1);
    expect(tester.takeException(), isNull);
  });
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount});
  final VoidCallback onMount;
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
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white);
}
