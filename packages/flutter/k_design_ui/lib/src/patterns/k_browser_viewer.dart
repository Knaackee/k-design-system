import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../feedback/k_agent_cursor.dart';
import '../feedback/k_activity_dot.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';

/// Dock below the scrolling conversation and above its composer. The consumer
/// owns permission decisions, transport, control state and persistent dismissal.
class KBrowserViewer extends StatefulWidget {
  const KBrowserViewer({
    required this.child,
    required this.status,
    required this.onTakeControl,
    required this.onPause,
    required this.onStop,
    required this.onClose,
    this.connected = true,
    this.humanControl = false,
    this.paused = false,
    this.working = false,
    this.pending = false,
    this.permissionPending = false,
    this.height = 360,
    this.maximized = false,
    this.onMaximizedChanged,
    this.onReconnect,
    this.cursor,
    this.cursorState = KAgentCursorState.pointing,
    this.cursorAvatar,
    this.transportHandlesGestures = false,
    this.onResetView,
    this.onKeyboard,
    super.key,
  });

  final Widget child;
  final String status;
  final bool connected,
      humanControl,
      paused,
      permissionPending,
      maximized,
      working,
      pending;
  final double height;
  final VoidCallback? onTakeControl, onPause, onStop, onReconnect;
  final VoidCallback onClose;
  final ValueChanged<bool>? onMaximizedChanged;

  /// Normalized coordinates in the supplied browser surface, in [0, 1].
  final Offset? cursor;
  final KAgentCursorState cursorState;
  final Widget? cursorAvatar;

  /// Platform views can own pinch/pan and enforce their own read-only input.
  final bool transportHandlesGestures;
  final VoidCallback? onResetView;

  /// Explicit keyboard action; the transport cannot infer remote field focus.
  final VoidCallback? onKeyboard;

  @override
  State<KBrowserViewer> createState() => _KBrowserViewerState();
}

class _KBrowserViewerState extends State<KBrowserViewer> {
  final _transform = TransformationController();
  late bool _minimized = widget.permissionPending;
  bool _animateHeight = true;

  @override
  void didUpdateWidget(KBrowserViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fullscreen also hides/restores chat chrome, so its height must snap.
    _animateHeight = widget.maximized == oldWidget.maximized;
    if (widget.permissionPending != oldWidget.permissionPending) {
      _minimized = widget.permissionPending;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final compact = _minimized && !widget.maximized;
    return AnimatedContainer(
      key: const ValueKey('browser-viewer'),
      height: compact ? 180 : widget.height,
      duration: MediaQuery.disableAnimationsOf(context) || !_animateHeight
          ? Duration.zero
          : t.motionModerate,
      curve: Curves.easeOut,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: t.colorSurfaceCanvas,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: const ValueKey('browser-viewer-toolbar'),
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceControlGap * 2,
              vertical: t.spaceControlGap,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth <= 600;
                Widget action(
                  String label,
                  KIconName icon,
                  VoidCallback? callback,
                ) => narrow
                    ? KIconButton(label: label, icon: icon, onPressed: callback)
                    : KButton(
                        label: label,
                        variant: KButtonVariant.ghost,
                        onPressed: callback,
                      );
                final indicator = SizedBox.square(
                  dimension: t.sizeHitTarget,
                  child: Center(
                    child: Tooltip(
                      message: widget.status,
                      excludeFromSemantics: true,
                      child: Semantics(
                        liveRegion: true,
                        child: KActivityDot(
                          label: widget.status,
                          animation: KActivityDotAnimation.none,
                          state: !widget.connected
                              ? KActivityDotState.error
                              : widget.permissionPending
                              ? KActivityDotState.question
                              : widget.working || widget.pending
                              ? KActivityDotState.working
                              : KActivityDotState.idle,
                          dotColor: !widget.connected
                              ? t.colorStatusErrorAccent
                              : widget.permissionPending
                              ? t.colorStatusWarningAccent
                              : widget.paused
                              ? t.colorTextMuted
                              : widget.humanControl ||
                                    widget.working ||
                                    widget.pending
                              ? t.colorStatusInfoAccent
                              : t.colorStatusSuccessAccent,
                        ),
                      ),
                    ),
                  ),
                );
                final controls = [
                  KIconButton(
                    label: compact
                        ? 'Browseransicht vergrößern'
                        : 'Browseransicht minimieren',
                    icon: compact ? KIconName.chevronUp : KIconName.chevronDown,
                    onPressed: () => setState(() => _minimized = !_minimized),
                  ),
                  action(
                    widget.humanControl ? 'Kontrolle abgeben' : 'Übernehmen',
                    KIconName.mousePointer,
                    widget.connected ? widget.onTakeControl : null,
                  ),
                  if (widget.humanControl)
                    KIconButton(
                      label: 'Tastatur öffnen',
                      icon: KIconName.keyboard,
                      onPressed: widget.connected ? widget.onKeyboard : null,
                    ),
                  action(
                    widget.paused ? 'Fortsetzen' : 'Pausieren',
                    widget.paused ? KIconName.play : KIconName.pause,
                    widget.connected && !widget.humanControl
                        ? widget.onPause
                        : null,
                  ),
                  action(
                    'Stoppen',
                    KIconName.square,
                    widget.connected ? widget.onStop : null,
                  ),
                  KIconButton(
                    label: 'Ansicht zurücksetzen',
                    icon: KIconName.rotateCcw,
                    onPressed: () {
                      _transform.value = Matrix4.identity();
                      widget.onResetView?.call();
                    },
                  ),
                  KIconButton(
                    label: widget.maximized
                        ? 'Vollbild verlassen'
                        : 'Vollbild umschalten',
                    icon: widget.maximized
                        ? KIconName.minimize
                        : KIconName.maximize,
                    onPressed: widget.onMaximizedChanged == null
                        ? null
                        : () {
                            setState(() => _minimized = false);
                            widget.onMaximizedChanged!(!widget.maximized);
                          },
                  ),
                  KIconButton(
                    label: 'Browser schließen',
                    icon: KIconName.x,
                    onPressed: widget.onClose,
                  ),
                ];
                return Row(
                  spacing: t.spaceControlGap,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: t.spaceControlGap,
                          children: [
                            indicator,
                            ...controls.take(controls.length - 1),
                          ],
                        ),
                      ),
                    ),
                    controls.last,
                  ],
                );
              },
            ),
          ),
          Divider(
            height: t.borderWidthDefault,
            thickness: t.borderWidthDefault,
            color: t.colorBorderDefault,
          ),
          Expanded(
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 3,
                // Review gestures stay local; human pointer drags reach the page.
                panEnabled:
                    !widget.transportHandlesGestures && !widget.humanControl,
                scaleEnabled: !widget.transportHandlesGestures,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    children: [
                      IgnorePointer(
                        ignoring:
                            !widget.connected ||
                            (!widget.humanControl &&
                                !widget.transportHandlesGestures),
                        child: widget.child,
                      ),
                      if (widget.cursor != null &&
                          widget.connected &&
                          !widget.humanControl)
                        Positioned(
                          left:
                              widget.cursor!.dx.clamp(0, 1) *
                              constraints.maxWidth,
                          top:
                              widget.cursor!.dy.clamp(0, 1) *
                              constraints.maxHeight,
                          child: KAgentCursor(
                            size: 28,
                            state: widget.cursorState,
                            avatar: widget.cursorAvatar == null
                                ? null
                                : Transform.translate(
                                    offset: const Offset(-6, -8),
                                    child: SizedBox.square(
                                      dimension: t
                                          .componentBrowserViewerCursorAvatarSize,
                                      child: FittedBox(
                                        child: widget.cursorAvatar,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      if (!widget.connected)
                        ColoredBox(
                          color: t.colorSurfaceCanvas.withValues(
                            alpha: t.componentBrowserViewerDisconnectedOpacity,
                          ),
                          child: Center(
                            child: KButton(
                              label: 'Erneut verbinden',
                              onPressed: widget.onReconnect,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!compact)
            Padding(
              padding: EdgeInsets.all(t.spaceControlGap),
              child: Text(
                widget.humanControl
                    ? 'Du steuerst den Browser. Schließen beendet die Sitzung.'
                    : 'Schreibgeschützte Liveansicht · Pinch zum Zoomen, ziehen zum Verschieben.',
                style: TextStyle(
                  color: t.colorTextMuted,
                  fontSize: t.fontCaptionSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
