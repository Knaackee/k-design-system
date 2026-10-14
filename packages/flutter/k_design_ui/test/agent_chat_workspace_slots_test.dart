import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

Widget frame({
  bool open = false,
  bool empty = false,
  ValueChanged<bool>? onChange,
}) => MaterialApp(
  theme: kDesignTheme(),
  home: KAgentChatWorkspace(
    sidebar: const SizedBox.expand(),
    defaultSidebarCollapsed: true,
    avatarPopoverActivation: KAgentAvatarPopoverActivation.tap,
    conversationEmpty: empty,
    avatar: const SizedBox.square(dimension: 144),
    title: const Text('Ada'),
    avatarLabel: const Text('Ada label'),
    avatarPopover: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Demo quota'),
    ),
    avatarPopoverLabel: 'Ada account',
    rightSidebar: const Text('Context slot'),
    rightSidebarOpen: open,
    onRightSidebarOpenChange: onChange,
    conversation: const SizedBox.expand(key: ValueKey('conversation')),
    composer: const SizedBox(
      width: double.infinity,
      height: 72,
      key: ValueKey('composer'),
    ),
  ),
);

void main() {
  testWidgets('single tap shrinks empty character and quota stays below it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame(empty: true));
    final figure = find.byKey(const ValueKey('k-agent-chat-workspace-avatar'));
    final before = tester.getSize(figure).width;
    await tester.tap(find.byType(KPopover));
    await tester.pumpAndSettle();
    expect(find.text('Demo quota'), findsOneWidget);
    expect(tester.getSize(figure).width, lessThan(before));
    final popup = tester.getRect(find.byType(PopupMenuItem<bool>));
    expect(popup.top, closeTo(tester.getRect(figure).bottom, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSize(figure).width, before);
  });
  testWidgets('speech bubble centers on avatar in an inset gallery navigator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SizedBox(width: 800, height: 600, child: frame())),
      ),
    );
    final avatar = tester.getRect(
      find.byKey(const ValueKey('k-agent-chat-workspace-avatar')),
    );
    await tester.tap(find.byType(KPopover));
    await tester.pumpAndSettle();
    final popup = tester.getRect(find.byType(PopupMenuItem<bool>));
    expect(popup.center.dx, closeTo(avatar.center.dx, 1));
    expect(popup.top, closeTo(avatar.bottom, 1));
  });
  testWidgets(
    'avatar speech bubble anchors to figure and supports keyboard activation',
    (tester) async {
      await tester.pumpWidget(frame());
      await tester.tap(find.byType(KPopover));
      await tester.pumpAndSettle();
      expect(find.text('Demo quota'), findsOneWidget);
      final popup = tester.getRect(find.byType(PopupMenuItem<bool>));
      expect(
        popup.top,
        closeTo(
          tester
              .getRect(
                find.byKey(const ValueKey('k-agent-chat-workspace-avatar')),
              )
              .bottom,
          1,
        ),
      );
      expect(popup.left, greaterThanOrEqualTo(16));
      expect(popup.right, lessThanOrEqualTo(784));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Demo quota'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada label'));
      await tester.pumpAndSettle();
      expect(find.text('Demo quota'), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('moving quota remains bounded when viewport narrows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KAgentChatWorkspace(
          sidebar: const SizedBox(),
          avatar: const SizedBox.square(dimension: 240),
          title: const Text('Ada'),
          conversation: const SizedBox(),
          composer: const SizedBox(height: 40),
          conversationEmpty: true,
          avatarPopoverActivation: KAgentAvatarPopoverActivation.tap,
          avatarTransitionDuration: const Duration(milliseconds: 900),
          avatarPopover: const Text('Quota resize'),
        ),
      ),
    );
    await tester.tap(find.byType(KPopover));
    await tester.pump(const Duration(milliseconds: 120));
    tester.view.physicalSize = const Size(240, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final popup = tester.getRect(find.byType(PopupMenuItem<bool>));
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right, lessThanOrEqualTo(240));
  });

  testWidgets('reading area and composer center while right column animates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame());
    final conversation = tester.getRect(
      find.byKey(const ValueKey('conversation')),
    );
    final composer = tester.getRect(find.byKey(const ValueKey('composer')));
    expect(conversation.width, 952);
    expect(composer.width, conversation.width);
    expect(composer.center.dx, conversation.center.dx);
    await tester.pumpWidget(frame(open: true));
    await tester.pump(const Duration(milliseconds: 120));
    final column = find.byKey(
      const ValueKey('k-agent-chat-workspace-right-sidebar'),
    );
    expect(tester.getSize(column).width, inExclusiveRange(0, 280));
    await tester.pumpAndSettle();
    expect(tester.getSize(column).width, 280);
    expect(tester.getSize(column).height, 900);
    expect(tester.takeException(), null);
  });

  testWidgets('tablet context uses bottom sheet and reports dismissal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool? changed;
    await tester.pumpWidget(
      frame(open: true, onChange: (open) => changed = open),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KBottomSheet), findsOneWidget);
    expect(find.text('Context slot'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(changed, false);
    expect(tester.takeException(), null);
  });
  testWidgets(
    'right sheet closes on external state, docking and workspace removal',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(frame(open: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(frame(open: false));
      await tester.pumpAndSettle();
      expect(find.byType(KBottomSheet), findsNothing);
      await tester.pumpWidget(frame(open: true));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      expect(find.byType(KBottomSheet), findsNothing);
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('k-agent-chat-workspace-right-sidebar'),
              ),
            )
            .width,
        280,
      );
      tester.view.physicalSize = const Size(800, 900);
      await tester.pumpAndSettle();
      expect(find.byType(KBottomSheet), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(theme: kDesignTheme(), home: const SizedBox()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KBottomSheet), findsNothing);
      expect(tester.takeException(), null);
    },
  );
}
