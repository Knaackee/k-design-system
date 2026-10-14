import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget frame({
    bool showTitle = false,
    bool conversationEmpty = false,
    Widget? avatar,
    bool status = true,
    bool reduceMotion = false,
    VoidCallback? onConversationTap,
    double mobileSize = 80,
    double desktopSize = 104,
    double compactSize = 52,
  }) => MaterialApp(
    theme: kDesignTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: KAgentChatWorkspace(
      labels: const KAgentChatWorkspaceLabels(
        agents: 'Agenten',
        closeAgents: 'Agenten schließen',
      ),
      sidebar: Semantics(
        label: 'Sidebar content',
        child: const ColoredBox(key: ValueKey('sidebar'), color: Colors.red),
      ),
      avatar:
          avatar ??
          const SizedBox.square(key: ValueKey('avatar'), dimension: 144),
      title: const Text('Ada'),
      status: status ? const Text('Bereit') : null,
      showTitle: showTitle,
      conversationEmpty: conversationEmpty,
      avatarSizeMobile: mobileSize,
      avatarSizeDesktop: desktopSize,
      avatarSizeCompact: compactSize,
      actions: const SizedBox(key: ValueKey('actions'), width: 40, height: 40),
      conversation: GestureDetector(
        onTap: onConversationTap,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(key: ValueKey('conversation')),
      ),
      composer: const SizedBox(key: ValueKey('composer'), height: 72),
    ),
  );
  final avatarFinder = find.byKey(
    const ValueKey('k-agent-chat-workspace-avatar'),
  );

  testWidgets(
    'desktop keeps sidebar while compact avatar floats over full conversation',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(frame());
      expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 280);
      expect(tester.getSize(avatarFinder).width, 104);
      final conversation = tester.getRect(
        find.byKey(const ValueKey('conversation')),
      );
      final avatar = tester.getRect(avatarFinder);
      expect(conversation.top, lessThan(64));
      expect(conversation.contains(avatar.center), true);
      expect(avatar.center.dx, conversation.center.dx);
      expect(conversation.height, greaterThan(750));
      // The fading backdrop consists of clipped blur bands. Each band spans
      // the conversation; no save-layer mask may hide the live backdrop.
      final blurBands = find.byType(BackdropFilter);
      expect(blurBands, findsWidgets);
      expect(find.byType(ShaderMask), findsNothing);
      for (final band in blurBands.evaluate()) {
        expect(
          tester.getSize(find.byWidget(band.widget)).width,
          conversation.width,
        );
      }
      expect(tester.takeException(), null);
    },
  );

  testWidgets('mobile avatar is80 and drawer remains accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame());
    expect(find.byKey(const ValueKey('sidebar')), findsNothing);
    expect(tester.getSize(avatarFinder).width, 80);
    await tester.tap(find.bySemanticsLabel('Agenten'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
    expect(find.bySemanticsLabel('Agenten schließen'), findsOneWidget);
  });

  testWidgets(
    'hidden title retains semantics and overlay does not block conversation taps',
    (tester) async {
      final semantics = tester.ensureSemantics();

      var tapped = false;
      await tester.pumpWidget(frame(onConversationTap: () => tapped = true));
      expect(tester.getSemantics(find.text('Ada')).label, 'Ada');
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Ada'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0,
      );
      await tester.tapAt(tester.getRect(avatarFinder).center);
      expect(tapped, true);
      expect(tester.takeException(), null);
      semantics.dispose();
    },
  );

  testWidgets(
    'keyboard animates overlay smaller on tall viewport without consuming conversation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(frame());
      final conversationTop = tester
          .getRect(find.byKey(const ValueKey('conversation')))
          .top;
      expect(tester.getSize(avatarFinder).width, 80);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(avatarFinder).width, inExclusiveRange(52, 80));
      await tester.pumpAndSettle();
      expect(tester.getSize(avatarFinder).width, 52);
      expect(
        tester.getRect(find.byKey(const ValueKey('conversation'))).top,
        conversationTop,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('conversation'))).height,
        greaterThan(620),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('composer'))).bottom,
        lessThanOrEqualTo(800),
      );
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'size overrides, visible title and absent status are consumer controlled',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        frame(showTitle: true, status: false, mobileSize: 88),
      );
      expect(tester.getSize(avatarFinder).width, 88);
      expect(find.text('Bereit'), findsNothing);
      expect(
        find.ancestor(of: find.text('Ada'), matching: find.byType(Opacity)),
        findsNothing,
      );
      expect(
        tester.getRect(find.text('Ada')).top,
        greaterThan(tester.getRect(avatarFinder).bottom),
      );
    },
  );

  testWidgets(
    'reduced motion uses compact size immediately and short heights stay usable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(frame(reduceMotion: true));
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pump();
      expect(tester.getSize(avatarFinder).width, 52);
      expect(
        tester.getSize(find.byKey(const ValueKey('conversation'))).height,
        greaterThan(0),
      );
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'empty avatar centers large then slides to top without remounting',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var mounts = 0, disposals = 0;
      final child = _LifecycleAvatar(
        onMount: () => mounts++,
        onDispose: () => disposals++,
      );
      await tester.pumpWidget(
        frame(conversationEmpty: true, avatar: child, status: false),
      );
      final stage = tester.getRect(find.byKey(const ValueKey('conversation')));
      final initial = tester.getRect(avatarFinder);
      // Approved empty identity: min(420, 72vw, 52vh).
      expect(initial.width, closeTo(390 * .72, .01));
      expect(initial.width, lessThanOrEqualTo(420));
      expect(initial.width, lessThanOrEqualTo(844 * .52));
      expect(initial.center.dy, closeTo(stage.center.dy, .01));
      expect(mounts, 1);
      await tester.pumpWidget(
        frame(conversationEmpty: false, avatar: child, status: false),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final middle = tester.getRect(avatarFinder);
      expect(middle.width, inExclusiveRange(80, initial.width));
      expect(middle.top, lessThan(initial.top));
      expect(middle.top, greaterThan(stage.top));
      await tester.pumpAndSettle();
      expect(tester.getSize(avatarFinder).width, 80);
      expect(tester.getRect(avatarFinder).top, stage.top);
      expect(mounts, 1);
      expect(disposals, 0);
    },
  );

  testWidgets(
    'desktop sidebar animates while immediately removing hidden semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(frame());
      final sidebar = find.byKey(
        const ValueKey('k-agent-chat-workspace-sidebar'),
      );
      expect(
        _hasSemanticsLabel(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
          'Sidebar content',
        ),
        true,
      );
      await tester.tap(find.bySemanticsLabel('Agenten schließen'));
      await tester.pump();
      expect(
        _hasSemanticsLabel(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
          'Sidebar content',
        ),
        false,
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getSize(sidebar).width, inExclusiveRange(0, 280));
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 0);
      expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Agenten'));
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 280);
      expect(
        _hasSemanticsLabel(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
          'Sidebar content',
        ),
        true,
      );
      semantics.dispose();
    },
  );
  testWidgets('sidebar builder can close the mobile drawer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KAgentChatWorkspace(
          sidebarBuilder: (context, controls) => TextButton(
            onPressed: controls.close,
            child: const Text('Choose Ada'),
          ),
          avatar: const SizedBox.square(dimension: 112),
          title: const Text('Ada'),
          conversation: const SizedBox.expand(),
          composer: const SizedBox(height: 72),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Agents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Ada').hitTestable(), findsNothing);
  });
}

class _LifecycleAvatar extends StatefulWidget {
  const _LifecycleAvatar({required this.onMount, required this.onDispose});
  final VoidCallback onMount, onDispose;
  @override
  State<_LifecycleAvatar> createState() => _LifecycleAvatarState();
}

class _LifecycleAvatarState extends State<_LifecycleAvatar> {
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
  Widget build(BuildContext context) => const SizedBox.square(dimension: 144);
}

bool _hasSemanticsLabel(SemanticsNode node, String label) {
  if (node.getSemanticsData().label == label) return true;
  var found = false;
  node.visitChildren((child) {
    found = found || _hasSemanticsLabel(child, label);
    return !found;
  });
  return found;
}
