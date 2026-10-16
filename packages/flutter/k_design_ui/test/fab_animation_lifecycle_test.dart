import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('hidden chat bubble retains state but pauses child animation', (
    tester,
  ) async {
    var ticks = 0;
    var mounts = 0;
    Widget bubble(bool visible) => MaterialApp(
      home: Scaffold(
        body: KChatBubble(
          label: 'Chat',
          visible: visible,
          onPressed: () {},
          child: _TickProbe(onTick: () => ticks++, onMount: () => mounts++),
        ),
      ),
    );
    await tester.pumpWidget(bubble(false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, 0);
    expect(mounts, 1);
    await tester.pumpWidget(bubble(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, greaterThan(0));
    await tester.pumpWidget(bubble(false));
    final stoppedAt = ticks;
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, stoppedAt);
    expect(mounts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hidden menu pauses child tickers and opening resumes them', (
    tester,
  ) async {
    var ticks = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: KFab(
              label: 'Main',
              onPressed: () {},
              items: [
                KFabItem(
                  id: 'other',
                  label: 'Other',
                  child: _TickProbe(onTick: () => ticks++),
                  onSelected: () {},
                ),
              ],
              child: const Text('A'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, 0);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, greaterThan(0));
    await tester.tap(find.text('B'));
    await tester.pump();
    final stoppedAt = ticks;
    await tester.pump(const Duration(milliseconds: 100));
    expect(ticks, stoppedAt);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'lifecycle and visibility changes do not measure a stale anchor',
    (tester) async {
      var visible = true;
      var calls = 0;
      final transformKey = GlobalKey();
      late StateSetter rebuild;
      Widget buildFab() => MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _LayoutSensitiveProxy(
                key: transformKey,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: KFab(
                    label: 'Main',
                    visible: visible,
                    items: [
                      KFabItem(
                        id: 'other',
                        label: 'Other',
                        child: const Text('B'),
                        onSelected: () => calls++,
                      ),
                    ],
                    child: const Text('A'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(buildFab());
      await tester.pump();
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      (transformKey.currentContext!.findRenderObject()!
              as _LayoutSensitiveRenderBox)
          .invalidateSize();
      rebuild(() {});
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      visible = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpWidget(buildFab());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      visible = true;
      await tester.pumpWidget(buildFab());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('B'), findsOneWidget);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('B'), findsNothing);
    },
  );
}

class _LayoutSensitiveProxy extends SingleChildRenderObjectWidget {
  const _LayoutSensitiveProxy({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LayoutSensitiveRenderBox();
}

class _LayoutSensitiveRenderBox extends RenderProxyBox {
  bool _layoutReady = true;

  @override
  bool get hasSize => _layoutReady && super.hasSize;

  void invalidateSize() {
    _layoutReady = false;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    _layoutReady = true;
    super.performLayout();
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (!_layoutReady) throw FlutterError('RenderBox was not laid out');
    super.applyPaintTransform(child, transform);
  }
}

class _TickProbe extends StatefulWidget {
  const _TickProbe({required this.onTick, this.onMount});
  final VoidCallback onTick;
  final VoidCallback? onMount;

  @override
  State<_TickProbe> createState() => _TickProbeState();
}

class _TickProbeState extends State<_TickProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    widget.onMount?.call();
    _animation =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(widget.onTick)
          ..repeat();
  }

  @override
  Widget build(BuildContext context) => const Text('B');

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}
