import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('fullscreen viewer follows keyboard resize without overflow', (
    tester,
  ) async {
    double height = 600;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height,
                child: KBrowserViewer(
                  height: height,
                  maximized: true,
                  status: 'Live verbunden',
                  onTakeControl: () {},
                  onPause: () {},
                  onStop: () {},
                  onClose: () {},
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
    update(() => height = 320);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
  testWidgets('leaving fullscreen does not overflow restored composer', (
    tester,
  ) async {
    bool maximized = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return KAgentChatWorkspace(
              sidebar: const SizedBox.expand(),
              defaultSidebarCollapsed: true,
              avatar: const SizedBox.square(dimension: 104),
              title: const Text('Nova'),
              conversation: const SizedBox.expand(),
              composer: const SizedBox(height: 88),
              dockMaximized: maximized,
              dockBuilder: (context, height) => KBrowserViewer(
                height: maximized ? height : height * .45,
                maximized: maximized,
                status: 'Live verbunden',
                onTakeControl: () {},
                onPause: () {},
                onStop: () {},
                onClose: () {},
                child: const ColoredBox(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
    update(() => maximized = true);
    await tester.pumpAndSettle();
    update(() => maximized = false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('dock follows conversation and composer content width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [920.0, double.infinity]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: KAgentChatWorkspace(
            contentMaxWidth: width,
            sidebar: const SizedBox.expand(),
            defaultSidebarCollapsed: true,
            avatar: const SizedBox.square(dimension: 104),
            title: const Text('Nova'),
            conversation: const SizedBox.expand(
              key: ValueKey('width-conversation'),
            ),
            composer: const SizedBox(
              height: 72,
              width: double.infinity,
              key: ValueKey('width-composer'),
            ),
            dockBuilder: (context, height) => const SizedBox(
              height: 180,
              width: double.infinity,
              key: ValueKey('width-dock'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dock = tester.getRect(find.byKey(const ValueKey('width-dock')));
      final conversation = tester.getRect(
        find.byKey(const ValueKey('width-conversation')),
      );
      final composer = tester.getRect(
        find.byKey(const ValueKey('width-composer')),
      );
      expect(dock.width, composer.width);
      expect(dock.width, conversation.width);
      expect(dock.left, composer.left);
      expect(dock.width, width.isFinite ? lessThan(1600) : 1600);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('maximizing dock preserves its mounted child and restores chat', (
    tester,
  ) async {
    bool maximized = false;
    late StateSetter update;
    int mounts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return KAgentChatWorkspace(
              sidebar: const SizedBox.expand(),
              defaultSidebarCollapsed: true,
              avatar: const SizedBox.square(dimension: 104),
              title: const Text('Nova'),
              conversation: const Column(
                children: [
                  SizedBox(height: 136, child: Text('Notice')),
                  Expanded(child: Text('Conversation')),
                ],
              ),
              composer: const SizedBox(height: 72, child: Text('Composer')),
              dockMaximized: maximized,
              dockBuilder: (context, height) => SizedBox(
                height: maximized ? height : 180,
                child: _Probe(onMount: () => mounts++),
              ),
            );
          },
        ),
      ),
    );
    expect(mounts, 1);
    expect(tester.getSize(find.byType(_Probe)).height, 180);
    update(() => maximized = true);
    await tester.pumpAndSettle();
    expect(mounts, 1);
    expect(find.text('Conversation'), findsNothing);
    expect(find.text('Composer'), findsNothing);
    expect(tester.getSize(find.byType(_Probe)).height, 600);
    expect(tester.takeException(), isNull);
    update(() => maximized = false);
    await tester.pumpAndSettle();
    expect(mounts, 1);
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('Composer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onMount});
  final VoidCallback onMount;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white);
}
