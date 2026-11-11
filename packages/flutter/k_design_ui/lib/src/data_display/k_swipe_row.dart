import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';

enum KSwipeActionTone { neutral, info, success, warning, destructive }

/// One action behind a list row (`KListItem.leadingActions` /
/// `trailingActions`).
class KSwipeAction {
  const KSwipeAction({
    required this.id,
    required this.label,
    this.icon,
    this.tone = KSwipeActionTone.neutral,
    this.fullSwipe = false,
    this.onSelect,
  });

  final String id;
  final String label;
  final KIconName? icon;
  final KSwipeActionTone tone;

  /// Apple style: swiping across the row triggers this action.
  final bool fullSwipe;
  final VoidCallback? onSelect;
}

/// Swipe actions on a list row (Decision 0016). The style decides the
/// behaviour: Apple shows buttons behind the row (full swipe triggers the
/// `fullSwipe` action), Material reveals one coloured layer per side and
/// triggers past the threshold, Linear and keyboard users get the actions
/// inline at the end of the row.
class KSwipeRow extends StatefulWidget {
  const KSwipeRow({
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final List<KSwipeAction> leadingActions;
  final List<KSwipeAction> trailingActions;
  final bool enabled;

  @override
  State<KSwipeRow> createState() => _KSwipeRowState();
}

class _KSwipeRowState extends State<KSwipeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(vsync: this)
    ..addListener(
      () => setState(() => _offset = _settleTween.evaluate(_settle)),
    );
  Tween<double> _settleTween = Tween(begin: 0, end: 0);
  double _offset = 0;
  bool _hover = false;
  bool _focus = false;
  double _width = 1;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  KStyle get _style => KAdaptive.maybeOf(context)?.style ?? KStyle.linear;

  void _animateTo(double target, {VoidCallback? then}) {
    final motion = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motion(KMotionRole.control);
    _settleTween = Tween(begin: _offset, end: target);
    _settle
      ..duration = motion.duration
      ..reset();
    final run = _settle.animateTo(1, curve: motion.curve);
    if (then != null) unawaited(run.then((_) => then()));
  }

  void _run(KSwipeAction? action, double out) {
    if (action == null) return _animateTo(0);
    _animateTo(
      out,
      then: () {
        action.onSelect?.call();
        if (mounted) _animateTo(0);
      },
    );
  }

  void _onUpdate(DragUpdateDetails details) {
    _settle.stop();
    var next = _offset + details.delta.dx;
    if (widget.leadingActions.isEmpty) next = next.clamp(-_width, 0);
    if (widget.trailingActions.isEmpty) next = next.clamp(0, _width);
    setState(() => _offset = next.clamp(-_width, _width));
  }

  void _onEnd(DragEndDetails details) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final side = _offset > 0 ? widget.leadingActions : widget.trailingActions;
    final sign = _offset.sign;
    if (_style == KStyle.material) {
      return _offset.abs() > _width * t.componentSwipeActionRevealThreshold
          ? _run(side.firstOrNull, sign * _width)
          : _animateTo(0);
    }
    final full = side.where((a) => a.fullSwipe).firstOrNull;
    if (full != null &&
        _offset.abs() > _width * t.componentSwipeActionFullSwipeThreshold) {
      return _run(full, sign * _width);
    }
    final open = t.componentSwipeActionWidth * side.length;
    _animateTo(
      _offset.abs() > t.componentSwipeActionWidth / 2 ? sign * open : 0,
    );
  }

  ({Color background, Color foreground}) _colors(
    KDesignTokens t,
    KSwipeActionTone tone, {
    required bool filled,
  }) {
    if (filled) {
      return (
        background: switch (tone) {
          KSwipeActionTone.neutral => t.componentSwipeActionNeutralBackground,
          KSwipeActionTone.info => t.colorStatusInfoAccent,
          KSwipeActionTone.success => t.colorStatusSuccessAccent,
          KSwipeActionTone.warning => t.colorStatusWarningAccent,
          KSwipeActionTone.destructive => t.colorStatusErrorAccent,
        },
        foreground: t.componentSwipeActionForeground,
      );
    }
    return switch (tone) {
      KSwipeActionTone.neutral => (
        background: t.colorSurfaceSubtle,
        foreground: t.colorTextPrimary,
      ),
      KSwipeActionTone.info => (
        background: t.colorStatusInfoBackground,
        foreground: t.colorStatusInfoForeground,
      ),
      KSwipeActionTone.success => (
        background: t.colorStatusSuccessBackground,
        foreground: t.colorStatusSuccessForeground,
      ),
      KSwipeActionTone.warning => (
        background: t.colorStatusWarningBackground,
        foreground: t.colorStatusWarningForeground,
      ),
      KSwipeActionTone.destructive => (
        background: t.colorStatusErrorBackground,
        foreground: t.colorStatusErrorForeground,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final style = _style;
    final swipes = style != KStyle.linear && widget.enabled;
    final side = _offset > 0 ? widget.leadingActions : widget.trailingActions;
    final caption = Theme.of(context).textTheme.labelSmall;

    Widget behind = const SizedBox.shrink();
    if (style == KStyle.apple && _offset != 0) {
      final full =
          _offset.abs() > _width * t.componentSwipeActionFullSwipeThreshold;
      behind = Align(
        alignment: _offset > 0
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: _offset.abs(),
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (final action in side)
                  if (!full ||
                      action.fullSwipe ||
                      !side.any((a) => a.fullSwipe))
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          action.onSelect?.call();
                          _animateTo(0);
                        },
                        child: ColoredBox(
                          color: _colors(
                            t,
                            action.tone,
                            filled: true,
                          ).background,
                          child: ClipRect(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (action.icon != null)
                                    KIcon(
                                      action.icon!,
                                      size: 20,
                                      color: t.componentSwipeActionForeground,
                                    ),
                                  Text(
                                    action.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: caption?.copyWith(
                                      color: t.componentSwipeActionForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    } else if (style == KStyle.material && _offset != 0 && side.isNotEmpty) {
      final action = side.first;
      final colors = _colors(t, action.tone, filled: false);
      final armed =
          _offset.abs() > _width * t.componentSwipeActionRevealThreshold;
      behind = ExcludeSemantics(
        child: ColoredBox(
          color: colors.background,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceLayoutGutter),
            child: Row(
              mainAxisAlignment: _offset > 0
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              spacing: t.spaceControlGap,
              children: [
                if (_offset < 0)
                  Text(
                    action.label,
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (action.icon != null)
                  AnimatedScale(
                    scale: armed ? 1.25 : 1,
                    duration: t.motion(KMotionRole.control).duration,
                    child: KIcon(
                      action.icon!,
                      size: t.componentSwipeActionIconSize,
                      color: colors.foreground,
                    ),
                  ),
                if (_offset > 0)
                  Text(
                    action.label,
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final inlineVisible = (style == KStyle.linear && _hover) || _focus;
    final inline = Positioned.directional(
      textDirection: Directionality.of(context),
      end: t.spaceControlInsetInline,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !inlineVisible,
        child: AnimatedOpacity(
          opacity: inlineVisible ? 1 : 0,
          duration: t.motion(KMotionRole.control).duration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in [
                ...widget.leadingActions,
                ...widget.trailingActions,
              ])
                Tooltip(
                  message: action.label,
                  child: Semantics(
                    button: true,
                    label: action.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(t.radiusControl),
                      onTap: action.onSelect,
                      child: SizedBox.square(
                        dimension: t.sizeControl,
                        child: Center(
                          child: action.icon == null
                              ? Text(action.label)
                              : KIcon(
                                  action.icon!,
                                  size: 20,
                                  color: t.colorTextMuted,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1;
        return Semantics(
          customSemanticsActions: {
            for (final action in [
              ...widget.leadingActions,
              ...widget.trailingActions,
            ])
              CustomSemanticsAction(label: action.label): () =>
                  action.onSelect?.call(),
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Focus(
              skipTraversal: true,
              onFocusChange: (f) => setState(() => _focus = f),
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(child: behind),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: swipes ? _onUpdate : null,
                      onHorizontalDragEnd: swipes ? _onEnd : null,
                      child: Transform.translate(
                        offset: Offset(_offset, 0),
                        child: ColoredBox(
                          color: t.colorSurfaceRaised,
                          child: widget.child,
                        ),
                      ),
                    ),
                    inline,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
