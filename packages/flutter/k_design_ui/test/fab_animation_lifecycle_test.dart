import 'package:flutter/material.dart';
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
