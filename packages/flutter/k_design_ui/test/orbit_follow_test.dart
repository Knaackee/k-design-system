import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const levels = [
  KOrbitLevel(id: 'issues', radius: 120, periodSeconds: 90),
  KOrbitLevel(id: 'agents', radius: 40, periodSeconds: 50),
];
const nodes = [
  KOrbitNode(id: 'team', label: 'Team', radius: 32),
  KOrbitNode(
    id: 'issue',
    label: 'Issue',
    parentId: 'team',
    levelId: 'issues',
    radius: 16,
  ),
  KOrbitNode(
    id: 'agent',
    label: 'Agent',
    parentId: 'issue',
    levelId: 'agents',
    radius: 10,
    progress: 42,
  ),
];

Widget app(Widget child) => MaterialApp(
  theme: kDesignTheme(),
  home: Center(child: SizedBox(width: 500, height: 500, child: child)),
);
Finder marker(String id) => find.byKey(ValueKey('k-orbit-node-$id'));

void main() {
  testWidgets('node content and badge scale together with camera zoom', (
    tester,
  ) async {
    String? activated;
    Widget scene(double zoom) => app(
      KOrbit(
        levels: levels,
        nodes: const [
          KOrbitNode(
            id: 'team',
            label: 'Team',
            radius: 32,
            content: Text('PT'),
            badge: KOrbitBadge(content: Text('3')),
          ),
          KOrbitNode(
            id: 'issue',
            label: 'Issue',
            parentId: 'team',
            levelId: 'issues',
          ),
        ],
        connections: const [],
        paused: true,
        viewState: KOrbitViewState(zoom: zoom),
        onNodeActivate: (node) => activated = node.id,
      ),
    );
    await tester.pumpWidget(scene(1));
    await tester.tap(marker('team'));
    expect(activated, 'team');
    final contentWidth = tester.getRect(find.text('PT')).width;
    final badgeWidth = tester.getRect(find.text('3')).width;
    await tester.pumpWidget(scene(2));
    expect(
      tester.getRect(find.text('PT')).width,
      closeTo(contentWidth * 2, .01),
    );
    expect(tester.getRect(find.text('3')).width, closeTo(badgeWidth * 2, .01));
  });

  testWidgets(
    'follow survives rotation, zoom and motion; unpin and removal restore center',
    (tester) async {
      late StateSetter update;
      String? pinned = 'agent';
      var present = true;
      KOrbitViewState? changed;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KOrbit(
                levels: levels,
                nodes: present ? nodes : [nodes.first],
                connections: const [],
                showControls: false,
                pinnedNodeId: pinned,
                onPinnedChange: (value) => setState(() => pinned = value),
                onViewChange: (value) => changed = value,
              );
            },
          ),
        ),
      );
      final center = tester.getCenter(find.byType(KOrbit));
      expect(
        (tester.getCenter(marker('agent')) - center).distance,
        lessThan(.01),
      );
      // Keyboard rotation/zoom use the same camera as wheel and pinch.
      await tester.tapAt(
        tester.getTopLeft(find.byType(KOrbit)) + const Offset(10, 10),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.pump(const Duration(milliseconds: 16));
      expect(changed!.zoom, greaterThan(1));
      expect(
        (tester.getCenter(marker('agent')) - center).distance,
        lessThan(.01),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        (tester.getCenter(marker('agent')) - center).distance,
        lessThan(.01),
      );
      update(() => pinned = null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(changed!.zoom, 1);
      expect(changed!.offset, Offset.zero);
      expect(
        (tester.getCenter(marker('team')) - center).distance,
        lessThan(.01),
      );
      update(() => pinned = 'agent');
      await tester.pump();
      update(() => present = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(pinned, isNull);
      expect(
        (tester.getCenter(marker('team')) - center).distance,
        lessThan(.01),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'primary mouse pans, secondary rotates, touch rotates and pinch zooms',
    (tester) async {
      var view = const KOrbitViewState();
      await tester.pumpWidget(
        app(
          KOrbit(
            levels: levels,
            nodes: nodes,
            connections: const [],
            showControls: false,
            paused: true,
            onViewChange: (value) => view = value,
          ),
        ),
      );
      final origin =
          tester.getTopLeft(find.byType(KOrbit)) + const Offset(20, 20);
      var gesture = await tester.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(40, 20));
      await gesture.up();
      await tester.pump();
      expect(view.offset, const Offset(40, 20));
      expect(view.yaw, 0);
      gesture = await tester.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.moveBy(const Offset(40, 20));
      await gesture.up();
      await tester.pump();
      expect(view.yaw, closeTo(.32, .001));
      expect(view.offset, const Offset(40, 20));
      final touch = await tester.startGesture(origin, pointer: 3);
      await touch.moveBy(const Offset(30, 0));
      await touch.moveBy(const Offset(30, 0));
      await touch.up();
      await tester.pump();
      expect(view.yaw, greaterThan(.32));
      final a = await tester.startGesture(
        origin + const Offset(80, 80),
        pointer: 4,
      );
      final b = await tester.startGesture(
        origin + const Offset(140, 80),
        pointer: 5,
      );
      await tester.pump(const Duration(milliseconds: 16));
      await b.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await b.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await b.moveBy(const Offset(30, 0));
      await tester.pump();
      await a.up();
      await b.up();
      expect(view.zoom, greaterThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('local ping works while motion is paused and ends once', (
    tester,
  ) async {
    final controller = KOrbitController();
    final ended = <(String, KOrbitSignalEndReason)>[];
    await tester.pumpWidget(
      app(
        KOrbit(
          levels: levels,
          nodes: nodes,
          connections: const [],
          controller: controller,
          paused: true,
          onSignalEnd: (id, reason) => ended.add((id, reason)),
        ),
      ),
    );
    expect(
      controller.triggerSignal(
        const KOrbitSignal(
          id: 'ping',
          nodeId: 'agent',
          duration: Duration(milliseconds: 100),
        ),
      ),
      KOrbitSignalTriggerResult.accepted,
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(ended, [('ping', KOrbitSignalEndReason.completed)]);
    expect(
      controller.triggerSignal(
        const KOrbitSignal(id: 'invalid', nodeId: 'missing'),
      ),
      KOrbitSignalTriggerResult.invalid,
    );
  });
}
