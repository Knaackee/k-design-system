import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../feedback/k_agent_cursor.dart';
import '../extended_components.dart' show KSpinner;
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
    this.showInteractionHint = true,
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

  /// Show the optional gesture hint below the viewer.
  final bool showInteractionHint;
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
  bool _controlsExpanded = false;

  @override
  void didUpdateWidget(KBrowserViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximized != oldWidget.maximized) _controlsExpanded = false;
    // A shrinking parent (including IME insets) cannot fit the old dock height.
    _animateHeight =
        !widget.maximized &&
        widget.maximized == oldWidget.maximized &&
        widget.height >= oldWidget.height;
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
    // The indicator's full paint footprint and its action target are separate.
    final statusHeight = math.max(t.sizeControl, t.sizeHitTarget);
    final statusTarget = statusHeight + t.spaceControlGap * 2;
    final toolbar = Padding(
      key: const ValueKey('browser-viewer-toolbar'),
      padding: widget.maximized
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(
              horizontal: t.spaceControlGap * 2,
              vertical: t.spaceControlGap,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = widget.maximized || constraints.maxWidth <= 600;
          Widget action(String label, KIconName icon, VoidCallback? callback) =>
              narrow
              ? KIconButton(label: label, icon: icon, onPressed: callback)
              : KButton(
                  label: label,
                  variant: KButtonVariant.ghost,
                  onPressed: callback,
                );
          final indicator = SizedBox(
            width: statusTarget,
            height: statusHeight,
            child: Center(
              child: Tooltip(
                message: widget.status,
                excludeFromSemantics: true,
                child: Semantics(
                  liveRegion: true,
                  child: KActivityDot(
                    label: widget.status,
                    size: t.sizeIndicatorMedium,
                    animation: KActivityDotAnimation.auto,
                    state: widget.pending
                        ? KActivityDotState.working
                        : !widget.connected
                        ? KActivityDotState.error
                        : widget.permissionPending
                        ? KActivityDotState.question
                        : widget.working || widget.pending
                        ? KActivityDotState.working
                        : KActivityDotState.idle,
                    dotColor: widget.pending
                        ? t.colorStatusInfoAccent
                        : !widget.connected
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
            if (!widget.maximized)
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
              widget.connected && !widget.humanControl ? widget.onPause : null,
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
              icon: widget.maximized ? KIconName.minimize : KIconName.maximize,
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
          final toggle = Semantics(
            button: true,
            expanded: _controlsExpanded,
            label: '${widget.status}, Browsersteuerung',
            child: Tooltip(
              message: _controlsExpanded
                  ? 'Browsersteuerung ausblenden'
                  : 'Browsersteuerung anzeigen',
              child: InkWell(
                onTap: () =>
                    setState(() => _controlsExpanded = !_controlsExpanded),
                borderRadius: BorderRadius.circular(t.radiusControl),
                child: indicator,
              ),
            ),
          );
          if (widget.maximized && !_controlsExpanded) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: toggle,
            );
          }
          return Row(
            spacing: t.spaceControlGap,
            children: [
              if (widget.maximized) toggle,
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: t.spaceControlGap,
                    children: [
                      if (!widget.maximized) indicator,
                      ...controls.take(controls.length - 2),
                    ],
                  ),
                ),
              ),
              ...controls.skip(controls.length - 2),
            ],
          );
        },
      ),
    );
    return AnimatedContainer(
      key: const ValueKey('browser-viewer'),
      height: compact ? 180 : widget.height,
      duration: MediaQuery.disableAnimationsOf(context) || !_animateHeight
          ? Duration.zero
          : t.motion(KMotionRole.control).settle,
      curve: t.motion(KMotionRole.control).curve,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: t.colorSurfaceCanvas,
        border: widget.maximized
            ? null
            : Border.all(color: t.colorBorderDefault),
        borderRadius: widget.maximized
            ? null
            : BorderRadius.circular(t.radiusControl),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.maximized) toolbar,
              if (!widget.maximized)
                Divider(
                  height: t.borderWidthDefault,
                  thickness: t.borderWidthDefault,
                  color: t.colorBorderDefault,
                ),
              Expanded(
                key: const ValueKey('browser-viewer-surface'),
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 3,
                    // Review gestures stay local; human pointer drags reach the page.
                    panEnabled:
                        !widget.transportHandlesGestures &&
                        !widget.humanControl,
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
                                alpha:
                                    t.componentBrowserViewerDisconnectedOpacity,
                              ),
                              child: Center(
                                child: widget.pending
                                    ? KSpinner(label: widget.status)
                                    : KButton(
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
              if (!widget.maximized && !compact && widget.showInteractionHint)
                Padding(
                  padding: EdgeInsets.all(t.spaceControlGap),
                  child: Text(
                    widget.humanControl
                        ? 'Du steuerst den Browser. Schließen gibt die Kontrolle ab.'
                        : 'Schreibgeschützte Liveansicht · Pinch zum Zoomen, ziehen zum Verschieben.',
                    style: TextStyle(
                      color: t.colorTextMuted,
                      fontSize: t.fontCaptionSize,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.maximized)
            PositionedDirectional(
              start: 0,
              end: 0,
              // Float over the tab-strip edge; navigation and omnibox stay below.
              top: 0,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: _controlsExpanded ? null : statusTarget,
                  child: Material(
                    color: _controlsExpanded
                        ? t.colorSurfaceCanvas
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(t.radiusControl),
                    child: toolbar,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
