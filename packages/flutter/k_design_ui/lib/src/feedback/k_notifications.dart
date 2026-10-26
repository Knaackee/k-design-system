import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import 'k_notification_height.dart';
import '../primitives/k_icon.dart';

enum KNotificationPosition { bottomEnd, topEnd, bottomCenter }

enum KToastTone { neutral, success, warning, error }

/// One visible notification per overlay. Subsequent notifications queue FIFO.
class KToastController {
  KToastController._(this._overlay, this._duration, this._onDismiss);
  static final _queues = Expando<List<KToastController>>();
  final OverlayState _overlay;
  final Duration _duration;
  final VoidCallback? _onDismiss;
  late final OverlayEntry _entry;
  Timer? _timer;
  Duration _exitDuration = Duration.zero;
  ValueChanged<double>? _onHeightChanged;
  Stopwatch? _elapsed;
  Duration? _remaining;
  bool _dismissed = false, _visible = false, _hovered = false, _focused = false;
  bool _removed = false;
  void _activate() {
    if (!_overlay.mounted) {
      dismiss();
      return;
    }
    _visible = true;
    _overlay.insert(_entry);
    _remaining = _duration;
    _resume();
  }

  void _resume() {
    if (_dismissed ||
        !_visible ||
        _hovered ||
        _focused ||
        _duration <= Duration.zero) {
      return;
    }
    _elapsed = Stopwatch()..start();
    _timer = Timer(_remaining!, dismiss);
  }

  void _pause(bool hover, bool value) {
    if (_dismissed) return;
    if (hover) {
      _hovered = value;
    } else {
      _focused = value;
    }
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _remaining = _remaining! - (_elapsed?.elapsed ?? Duration.zero);
      if (_remaining! < Duration.zero) _remaining = Duration.zero;
      _elapsed = null;
    }
    if (!_hovered && !_focused) _resume();
  }

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    if (_visible && _overlay.mounted && _exitDuration > Duration.zero) {
      _entry.markNeedsBuild();
      _timer = Timer(_exitDuration, _remove);
    } else {
      _remove();
    }
    _onDismiss?.call();
  }

  void _remove() {
    if (_removed) return;
    _removed = true;
    _timer?.cancel();
    if (_visible) {
      if (_overlay.mounted) _entry.remove();
    }
    _entry.dispose();
    if (_visible) _onHeightChanged?.call(0);
    final queue = _queues[_overlay];
    queue?.remove(this);
    if (_visible && queue != null && queue.isNotEmpty) queue.first._activate();
  }
}

KToastController _show(
  BuildContext context,
  Duration duration,
  VoidCallback? onDismiss,
  Widget Function(VoidCallback) builder,
  KNotificationPosition position, {
  double? bottomOffset,
  double? maxWidth,
  bool animateExit = false,
  ValueChanged<double>? onHeightChanged,
}) {
  final overlay = Overlay.of(context);
  final themes = InheritedTheme.capture(from: context, to: overlay.context);
  final t = Theme.of(context).extension<KDesignTokens>()!;
  final controller = KToastController._(overlay, duration, onDismiss)
    .._onHeightChanged = onHeightChanged
    .._exitDuration = animateExit && !MediaQuery.disableAnimationsOf(context)
        ? t.componentToastEntryDuration
        : Duration.zero;
  controller._entry = OverlayEntry(
    builder: (context) => Positioned(
      left: t.componentToastViewportInset,
      right: t.componentToastViewportInset,
      top: position == KNotificationPosition.topEnd
          ? t.componentToastViewportInset
          : null,
      bottom: position == KNotificationPosition.topEnd
          ? null
          : bottomOffset ?? t.componentToastViewportInset,
      child: SafeArea(
        child: Align(
          alignment: position == KNotificationPosition.bottomCenter
              ? Alignment.bottomCenter
              : AlignmentDirectional.bottomEnd,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(0, maxWidth ?? t.componentToastViewportWidth),
            ),
            child: themes.wrap(
              Material(
                color: Colors.transparent,
                child: MouseRegion(
                  onEnter: (_) => controller._pause(true, true),
                  onExit: (_) => controller._pause(true, false),
                  child: Focus(
                    onFocusChange: (v) => controller._pause(false, v),
                    child: Semantics(
                      liveRegion: true,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: controller._dismissed ? 0 : 1,
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : t.componentToastEntryDuration,
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: KNotificationHeight(
                          onHeightChanged: (height) {
                            if (!controller._dismissed) {
                              onHeightChanged?.call(height);
                            }
                          },
                          child: IgnorePointer(
                            ignoring: controller._dismissed,
                            child: ExcludeSemantics(
                              excluding: controller._dismissed,
                              child: ExcludeFocus(
                                excluding: controller._dismissed,
                                child: builder(controller.dismiss),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final queue = KToastController._queues[overlay] ??= [];
  if (queue.length >= 5) queue.last.dismiss();
  queue.add(controller);
  if (queue.length == 1) controller._activate();
  return controller;
}

class KToast extends StatelessWidget {
  const KToast({
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
    this.tone = KToastTone.neutral,
    super.key,
  }) : _compact = false;
  const KToast._snackbar({
    required this.title,
    this.icon,
    this.action,
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
    this.tone = KToastTone.neutral,
  }) : description = null,
       _compact = true;
  final bool _compact;
  final Widget title;
  final Widget? description, icon, action;
  final VoidCallback? onDismiss;
  final String dismissLabel;
  final KToastTone tone;
  static KToastController show({
    required BuildContext context,
    required Widget title,
    Widget? description,
    Widget? icon,
    Widget? action,
    Duration duration = const Duration(seconds: 4),
    KToastTone tone = KToastTone.neutral,
    String dismissLabel = 'Dismiss',
    VoidCallback? onDismiss,
    KNotificationPosition position = KNotificationPosition.bottomEnd,
  }) => _show(
    context,
    duration,
    onDismiss,
    (dismiss) => KToast(
      title: title,
      description: description,
      icon: icon,
      action: action,
      tone: tone,
      dismissLabel: dismissLabel,
      onDismiss: dismiss,
    ),
    position,
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final border = switch (tone) {
      KToastTone.success => t.colorStatusSuccessBorder,
      KToastTone.warning => t.colorStatusWarningBorder,
      KToastTone.error => t.colorStatusErrorBorder,
      _ => t.colorBorderDefault,
    };
    final iconForeground = switch (tone) {
      KToastTone.success => t.colorStatusSuccessForeground,
      KToastTone.warning => t.colorStatusWarningForeground,
      KToastTone.error => t.colorStatusErrorForeground,
      _ => t.colorTextPrimary,
    };
    final iconBackground = switch (tone) {
      KToastTone.success => t.colorStatusSuccessBackground,
      KToastTone.warning => t.colorStatusWarningBackground,
      KToastTone.error => t.colorStatusErrorBackground,
      _ => t.colorSurfaceSubtle,
    };
    return Container(
      constraints: BoxConstraints(minHeight: t.componentToastMinHeight),
      padding: EdgeInsets.fromLTRB(
        t.componentToastPaddingLeading,
        t.componentToastPaddingBlock,
        t.componentToastPaddingInline,
        t.componentToastPaddingBlock,
      ),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: border, width: t.borderWidthDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
        boxShadow: t.componentToastNativeElevation,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            if (_compact)
              icon!
            else
              Container(
                width: t.componentToastIconSize,
                height: t.componentToastIconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: iconForeground,
                    size: t.componentSpinnerDefaultSize,
                  ),
                  child: icon!,
                ),
              ),
            SizedBox(width: t.componentToastContentGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: t.fontFamily,
                    fontWeight: _compact ? t.fontBodyWeight : t.fontLabelWeight,
                    fontSize: t.fontBodySmallSize,
                    height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
                    color: t.colorTextPrimary,
                  ),
                  child: title,
                ),
                if (description != null) ...[
                  SizedBox(height: t.spaceMicro),
                  DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: t.fontFamily,
                      color: t.colorTextMuted,
                      fontSize: t.fontBodySmallSize,
                      height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
                    ),
                    child: description!,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(width: t.componentToastContentGap),
            action!,
          ],
          if (onDismiss != null) ...[
            SizedBox(width: t.componentToastContentGap),
            KIconButton(
              icon: KIconName.x,
              label: dismissLabel,
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact notification, with consumer-owned message, action and lifecycle.
class KSnackbar extends StatelessWidget {
  const KSnackbar({
    required this.message,
    this.icon,
    this.action,
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
    this.tone = KToastTone.neutral,
    super.key,
  });
  final Widget message;
  final Widget? icon, action;
  final VoidCallback? onDismiss;
  final String dismissLabel;
  final KToastTone tone;
  static KToastController show({
    required BuildContext context,
    required Widget message,
    Widget? icon,
    Widget? action,
    VoidCallback? onDismiss,
    String dismissLabel = 'Dismiss',
    KToastTone tone = KToastTone.neutral,
    Duration duration = const Duration(seconds: 4),
    KNotificationPosition position = KNotificationPosition.bottomCenter,
    double? bottomOffset,
    double? maxWidth,
    bool animateExit = false,
    ValueChanged<double>? onHeightChanged,
  }) => _show(
    context,
    duration,
    onDismiss,
    (dismiss) => KSnackbar(
      message: message,
      icon: icon,
      action: action,
      tone: tone,
      dismissLabel: dismissLabel,
      onDismiss: dismiss,
    ),
    position,
    bottomOffset: bottomOffset,
    maxWidth: maxWidth,
    animateExit: animateExit,
    onHeightChanged: onHeightChanged,
  );
  @override
  Widget build(BuildContext context) => KToast._snackbar(
    title: message,
    icon: icon,
    action: action,
    onDismiss: onDismiss,
    dismissLabel: dismissLabel,
    tone: tone,
  );
}
