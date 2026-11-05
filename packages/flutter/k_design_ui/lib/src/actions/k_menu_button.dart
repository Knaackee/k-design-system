import '../feedback/k_sound.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import 'action_control.dart';
import 'k_menu_surface.dart';
import 'k_menu_item_content.dart';
import '../patterns/k_toolbar.dart';

class KMenuAction {
  const KMenuAction({
    required this.id,
    required this.label,
    this.onSelect,
    this.children = const [],
    this.icon,
    this.iconContent,
    this.disabled = false,
    this.destructive = false,
    this.separatorBefore = false,
    this.checked,
  });
  final String id;
  final String label;
  final VoidCallback? onSelect;
  final List<KMenuAction> children;
  final KIconName? icon;
  final Widget? iconContent;
  final bool disabled;
  final bool destructive;
  final bool separatorBefore;
  final bool? checked;
}

class KMenuButton extends StatefulWidget {
  const KMenuButton({
    required this.label,
    required this.actions,
    this.disabled = false,
    this.overflow = false,
    this.triggerContent,
    this.fullWidth = false,
    this.header,
    this.alignEnd = false,
    this.onOpenChange,
    this.triggerRadius,
    this.triggerIcon,
    super.key,
  });
  final String label;
  final List<KMenuAction> actions;
  final bool disabled;
  final bool overflow;
  final Widget? triggerContent;
  final bool fullWidth;
  final Widget? header;
  final bool alignEnd;
  final ValueChanged<bool>? onOpenChange;
  final BorderRadius? triggerRadius;
  final KIconName? triggerIcon;
  @override
  State<KMenuButton> createState() => _KMenuButtonState();
}

class _KMenuButtonState extends State<KMenuButton> {
  final _controller = MenuController();
  final _anchorKey = GlobalKey();
  final _trigger = FocusNode();
  final Map<String, FocusNode> _items = {};
  double? _menuWidth;
  bool _keyboardFocus = false;
  void _setKeyboardFocus(bool value) {
    if (_keyboardFocus != value) setState(() => _keyboardFocus = value);
  }

  String _search = '';
  DateTime _typedAt = DateTime(0);
  bool get _disabled => widget.disabled || widget.actions.isEmpty;
  @override
  void initState() {
    super.initState();
    _trigger.onKeyEvent = (_, event) {
      final navigation = KToolbar.handleNavigation(context, event);
      if (navigation == KeyEventResult.handled) return navigation;
      if (event is KeyDownEvent &&
          !_controller.isOpen &&
          (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowUp)) {
        _open(last: event.logicalKey == LogicalKeyboardKey.arrowUp);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _trigger.dispose();
    for (final node in _items.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(KMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final id in _items.keys.toList()) {
      if (!widget.actions.any((a) => a.id == id)) {
        _items.remove(id)!.dispose();
      }
    }
    if (_disabled && _controller.isOpen) _controller.close();
  }

  List<FocusNode> get _enabled => [
    for (final action in widget.actions)
      if (!action.disabled) _items[action.id]!,
  ];
  void _open({bool last = false}) {
    if (_disabled) return;
    _keyboardFocus = HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final screen = overlay.size;
    final width = menuContentWidth(context, widget.actions, screen.width);
    final origin =
        box?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    setState(() => _menuWidth = width);
    final desiredX = widget.alignEnd
        ? origin.dx + (box?.size.width ?? 0) - width
        : origin.dx;
    final x = desiredX.clamp(
      t.spaceControlGap,
      math.max(t.spaceControlGap, screen.width - width - t.spaceControlGap),
    );
    _controller.open(
      position: Offset(
        x - origin.dx,
        (box?.size.height ?? t.sizeControl) + t.spaceControlGap,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _controller.isOpen &&
          !widget.actions.any((a) => a.children.isNotEmpty) &&
          _enabled.isNotEmpty) {
        (last ? _enabled.last : _enabled.first).requestFocus();
      }
    });
  }

  void _close() {
    _controller.close();
    _trigger.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
    final width =
        _menuWidth ??
        menuContentWidth(
          context,
          widget.actions,
          MediaQuery.sizeOf(context).width,
        );
    final textStyle = TextStyle(
      fontFamily: t.fontFamily,
      fontSize: t.fontControlSize,
      fontWeight: t.fontControlWeight,
      height: t.fontTightHeight,
      // CSS centers leading evenly above and below the font metrics.
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: -.01 * scaled,
      fontVariations: [
        FontVariation.weight(t.fontControlWeight.value.toDouble()),
        FontVariation.opticalSize(scaled.clamp(14, 32)),
      ],
    );
    for (final action in widget.actions) {
      _items.putIfAbsent(action.id, () => FocusNode(debugLabel: action.label));
    }
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || _controller.isOpen) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _open(last: event.logicalKey == LogicalKeyboardKey.arrowUp);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      canRequestFocus: false,
      skipTraversal: true,
      child: MenuAnchor(
        key: _anchorKey,
        controller: _controller,
        consumeOutsideTap: true,
        onOpen: () => widget.onOpenChange?.call(true),
        onClose: () => widget.onOpenChange?.call(false),
        childFocusNode: _trigger,
        alignmentOffset: Offset(0, t.spaceControlGap),
        reservedPadding: EdgeInsets.all(t.spaceControlGap),
        clipBehavior: Clip.none,
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: WidgetStatePropertyAll(Size(width, 0)),
          maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
        menuChildren: [
          if (widget.actions.any((a) => a.children.isNotEmpty))
            KMenuSurface(
              actions: widget.actions,
              width: width,
              onClose: _close,
              header: widget.header,
            )
          else
            Listener(
              onPointerHover: (_) => _setKeyboardFocus(false),
              onPointerDown: (_) => _setKeyboardFocus(false),
              child: SizedBox(
                width: width,
                child: KSurface(
                  radius: KSurfaceRadius.overlay,
                  elevation: KSurfaceElevation.overlay,
                  child: Padding(
                    padding: EdgeInsets.all(t.spaceControlGap),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.header != null)
                          Container(
                            padding: EdgeInsets.all(t.spaceControlInsetInline),
                            margin: EdgeInsets.only(bottom: t.spaceControlGap),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: t.colorBorderDefault,
                                  width: t.borderWidthDefault,
                                ),
                              ),
                            ),
                            child: widget.header,
                          ),
                        for (final (index, action)
                            in widget.actions.indexed) ...[
                          if (index > 0 && action.separatorBefore)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: t.spaceControlGap,
                              ),
                              child: SizedBox(
                                height: t.borderWidthDefault,
                                child: ColoredBox(color: t.colorBorderDefault),
                              ),
                            ),
                          Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (_, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }
                              _setKeyboardFocus(true);
                              final nodes = _enabled;
                              final current = nodes.indexWhere(
                                (n) => n.hasFocus,
                              );
                              final key = event.logicalKey;
                              if (key == LogicalKeyboardKey.escape) {
                                _close();
                                return KeyEventResult.handled;
                              }
                              if (key == LogicalKeyboardKey.tab) {
                                _close();
                                return KeyEventResult.ignored;
                              }
                              if (nodes.isNotEmpty) {
                                int? next;
                                if (key == LogicalKeyboardKey.home) next = 0;
                                if (key == LogicalKeyboardKey.end) {
                                  next = nodes.length - 1;
                                }
                                if (key == LogicalKeyboardKey.arrowDown) {
                                  next = (current + 1) % nodes.length;
                                }
                                if (key == LogicalKeyboardKey.arrowUp) {
                                  next =
                                      (current - 1 + nodes.length) %
                                      nodes.length;
                                }
                                if (next != null) {
                                  nodes[next].requestFocus();
                                  return KeyEventResult.handled;
                                }
                                final char = event.character;
                                if (char != null &&
                                    char.trim().isNotEmpty &&
                                    !HardwareKeyboard
                                        .instance
                                        .isControlPressed &&
                                    !HardwareKeyboard.instance.isMetaPressed) {
                                  final now = DateTime.now();
                                  _search =
                                      now.difference(_typedAt).inMilliseconds >
                                          700
                                      ? char
                                      : _search + char;
                                  _typedAt = now;
                                  final enabled = widget.actions
                                      .where((a) => !a.disabled)
                                      .toList();
                                  for (
                                    var offset = 1;
                                    offset <= enabled.length;
                                    offset++
                                  ) {
                                    final candidate =
                                        enabled[(current + offset) %
                                            enabled.length];
                                    if (candidate.label
                                        .toLowerCase()
                                        .startsWith(_search.toLowerCase())) {
                                      _items[candidate.id]!.requestFocus();
                                      break;
                                    }
                                  }
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: MenuItemButton(
                              key: ValueKey(action.id),
                              focusNode: _items[action.id],
                              onPressed: action.disabled
                                  ? null
                                  : () {
                                      _close();
                                      action.onSelect?.call();
                                    },
                              style: ButtonStyle(
                                enableFeedback:
                                    KSoundProvider.maybeOf(context) == null,
                                visualDensity: VisualDensity.standard,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: WidgetStatePropertyAll(
                                  Size(
                                    0,
                                    math.max(t.sizeControl, t.sizeHitTarget),
                                  ),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    horizontal: t.spaceControlInsetInline,
                                    vertical: t.spaceControlGap,
                                  ),
                                ),
                                textStyle: WidgetStatePropertyAll(textStyle),
                                foregroundColor: WidgetStatePropertyAll(
                                  action.destructive
                                      ? t.colorStatusErrorForeground
                                      : t.colorTextPrimary,
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.pressed)
                                          ? t.colorActionGhostPressed
                                          : states.contains(
                                                  WidgetState.hovered,
                                                ) ||
                                                (_keyboardFocus &&
                                                    states.contains(
                                                      WidgetState.focused,
                                                    ))
                                          ? t.colorActionGhostHover
                                          : Colors.transparent,
                                    ),
                                overlayColor: const WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                side: WidgetStateProperty.resolveWith(
                                  (states) => BorderSide(
                                    color:
                                        _keyboardFocus &&
                                            states.contains(WidgetState.focused)
                                        ? t.colorBorderFocus
                                        : Colors.transparent,
                                    width: t.borderWidthStrong,
                                  ),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      t.radiusControl,
                                    ),
                                  ),
                                ),
                              ),
                              child: KMenuItemContent(
                                action: action,
                                width: width,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        builder: (context, controller, child) {
          final onPressed = _disabled
              ? null
              : () => controller.isOpen ? _close() : _open();
          if (widget.triggerContent == null) {
            return KActionControl(
              label: widget.label,
              icon:
                  widget.triggerIcon ??
                  (widget.overflow
                      ? KIconName.ellipsis
                      : KIconName.chevronDown),
              iconOnly: widget.overflow,
              focusNode: _trigger,
              onPressed: onPressed,
            );
          }
          return Semantics(
            label: widget.label,
            button: true,
            enabled: onPressed != null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                enableFeedback: KSoundProvider.maybeOf(context) == null,
                focusNode: _trigger,
                onTap: onPressed,
                borderRadius:
                    widget.triggerRadius ??
                    BorderRadius.circular(t.radiusControl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(t.sizeControl, t.sizeHitTarget),
                    minWidth: widget.fullWidth ? double.infinity : 0,
                  ),
                  child: widget.triggerContent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class KOverflowMenu extends StatelessWidget {
  const KOverflowMenu({
    required this.label,
    required this.actions,
    this.disabled = false,
    super.key,
  });
  final String label;
  final List<KMenuAction> actions;
  final bool disabled;
  @override
  Widget build(BuildContext context) => KMenuButton(
    label: label,
    actions: actions,
    disabled: disabled,
    overflow: true,
  );
}
