import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_map_zone_editor_labels.dart';

/// The feedback surface shares the floating selection bar's width and origin.
class KMapZoneFeedback extends StatelessWidget {
  const KMapZoneFeedback({
    required this.width,
    required this.height,
    required this.tokens,
    required this.labels,
    required this.dirty,
    required this.canUndo,
    required this.enabled,
    required this.canAccept,
    required this.onUndo,
    required this.onDiscard,
    required this.onAccept,
    required this.surface,
    super.key,
  });
  final double width, height;
  final KDesignTokens tokens;
  final KMapZoneEditorLabels labels;
  final bool dirty, canUndo, enabled, canAccept;
  final VoidCallback onUndo, onDiscard, onAccept;
  final Widget Function(Widget) surface;

  @override
  Widget build(BuildContext context) {
    final gap = tokens.spaceControlGap;
    final child = !dirty
        ? null
        : surface(
            SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KIconButton(
                      label: labels.undo,
                      icon: KIconName.undo2,
                      onPressed: enabled && canUndo ? onUndo : null,
                    ),
                    SizedBox(width: gap),
                    KIconButton(
                      label: labels.discard,
                      icon: KIconName.x,
                      onPressed: enabled ? onDiscard : null,
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: KButton(
                        label: labels.acceptChanges,
                        onPressed: enabled && canAccept ? onAccept : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    return SizedBox(width: width, height: height, child: child);
  }
}

/// Selection and dirty actions occupy one shared bottom slot.
class KMapZoneBarSlot extends StatelessWidget {
  const KMapZoneBarSlot({
    required this.dirtyVisible,
    required this.duration,
    required this.width,
    required this.height,
    required this.selection,
    required this.dirty,
    super.key,
  });
  final bool dirtyVisible;
  final Duration duration;
  final double width, height;
  final Widget selection, dirty;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final outgoing =
              animation.status == AnimationStatus.reverse ||
              animation.status == AnimationStatus.dismissed;
          return IgnorePointer(
            ignoring: outgoing,
            child: ExcludeSemantics(
              excluding: outgoing,
              child: ExcludeFocus(
                excluding: outgoing,
                child: FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, .12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      child: KeyedSubtree(
        key: ValueKey(dirtyVisible ? 'dirty' : 'selection'),
        child: dirtyVisible ? dirty : selection,
      ),
    ),
  );
}
