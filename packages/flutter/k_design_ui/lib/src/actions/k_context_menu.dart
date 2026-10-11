import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import 'k_menu_button.dart';

class KContextMenu extends StatefulWidget {
  const KContextMenu({
    required this.label,
    required this.actions,
    required this.child,
    this.disabled = false,
    this.onOpenChange,
    super.key,
  });

  final String label;
  final List<KMenuAction> actions;
  final Widget child;
  final bool disabled;
  final ValueChanged<bool>? onOpenChange;

  @override
  State<KContextMenu> createState() => _KContextMenuState();
}

class _KContextMenuState extends State<KContextMenu> {
  final _controller = MenuController();
  final _submenuControllers = <String, MenuController>{};
  final _anchor = GlobalKey();
  final _focus = FocusNode();

  bool get _enabled => !widget.disabled && widget.actions.isNotEmpty;

  MenuController _submenuController(String path) =>
      _submenuControllers.putIfAbsent(path, MenuController.new);

  void _closeSubmenusExcept([String? path]) {
    for (final entry in _submenuControllers.entries) {
      if (entry.key != path && entry.value.isOpen) entry.value.close();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _open(Offset localPosition) {
    if (!_enabled) return;
    _focus.requestFocus();
    _controller.open(position: localPosition);
  }

  MenuStyle _menuStyle(double width) => MenuStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    minimumSize: WidgetStatePropertyAll(Size(width, 0)),
    maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    side: const WidgetStatePropertyAll(BorderSide.none),
    shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
  );

  ButtonStyle _itemStyle(KDesignTokens t, KMenuAction action) => ButtonStyle(
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: WidgetStatePropertyAll(
      Size(0, math.max(t.sizeControl, t.sizeHitTarget)),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: t.spaceControlInsetInline,
        vertical: t.spaceControlGap,
      ),
    ),
    textStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontControlSize,
        fontWeight: t.fontControlWeight,
        height: t.fontTightHeight,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: -.01 * t.fontControlSize,
        fontVariations: [
          FontVariation.weight(t.fontControlWeight.value.toDouble()),
          FontVariation.opticalSize(t.fontControlSize.clamp(14, 32)),
        ],
      ),
    ),
    foregroundColor: WidgetStatePropertyAll(
      action.destructive ? t.colorStatusErrorForeground : t.colorTextPrimary,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? t.colorActionGhostPressed
          : states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
          ? t.colorActionGhostHover
          : Colors.transparent,
    ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.focused)
            ? t.colorBorderFocus
            : Colors.transparent,
        width: t.borderWidthStrong,
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
    ),
  );

  Widget _row(KDesignTokens t, KMenuAction action, double width) => Opacity(
    opacity: action.disabled ? .48 : 1,
    child: SizedBox(
      width: math.max(
        0,
        width -
            2 *
                (t.spaceControlGap +
                    t.spaceControlInsetInline +
                    t.borderWidthDefault),
      ),
      child: Row(
        children: [
          SizedBox(
            width: t.componentContextMenuIconSize,
            child:
                action.iconContent ??
                (action.icon == null
                    ? null
                    : KIcon(
                        action.icon!,
                        color: action.destructive
                            ? t.colorStatusErrorForeground
                            : t.colorTextPrimary,
                      )),
          ),
          SizedBox(width: t.spaceControlGap),
          Expanded(child: Text(action.label)),
        ],
      ),
    ),
  );

  Widget _surface(
    BuildContext context,
    List<KMenuAction> actions,
    double width, [
    String parentPath = '',
  ]) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return SizedBox(
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
              for (final (index, action) in actions.indexed) ...[
                if (index > 0 && action.separatorBefore)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
                    child: SizedBox(
                      height: t.borderWidthDefault,
                      child: ColoredBox(color: t.colorBorderDefault),
                    ),
                  ),
                if (action.children.isNotEmpty && !action.disabled)
                  SubmenuButton(
                    key: ValueKey(action.id),
                    controller: _submenuController(
                      parentPath.isEmpty
                          ? action.id
                          : '$parentPath/${action.id}',
                    ),
                    onHover: (hovered) {
                      if (hovered) {
                        _closeSubmenusExcept(
                          parentPath.isEmpty
                              ? action.id
                              : '$parentPath/${action.id}',
                        );
                      }
                    },
                    onFocusChange: (focused) {
                      if (focused) {
                        _closeSubmenusExcept(
                          parentPath.isEmpty
                              ? action.id
                              : '$parentPath/${action.id}',
                        );
                      }
                    },
                    style: _itemStyle(t, action),
                    menuStyle: _menuStyle(width),
                    menuChildren: [
                      _surface(
                        context,
                        action.children,
                        width,
                        parentPath.isEmpty
                            ? action.id
                            : '$parentPath/${action.id}',
                      ),
                    ],
                    child: _row(t, action, width),
                  )
                else
                  MenuItemButton(
                    key: ValueKey(action.id),
                    style: _itemStyle(t, action),
                    onHover: (hovered) {
                      if (hovered) _closeSubmenusExcept();
                    },
                    onFocusChange: (focused) {
                      if (focused) _closeSubmenusExcept();
                    },
                    onPressed: action.disabled
                        ? null
                        : () {
                            _controller.close();
                            action.onSelect?.call();
                          },
                    child: _row(t, action, width),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final width = math.min(
      t.componentContextMenuWidth,
      MediaQuery.sizeOf(context).width - t.componentContextMenuViewportInset,
    );
    return MenuAnchor(
      key: _anchor,
      controller: _controller,
      childFocusNode: _focus,
      reservedPadding: EdgeInsets.all(t.spaceControlGap),
      style: _menuStyle(width),
      onOpen: () => widget.onOpenChange?.call(true),
      onClose: () {
        _closeSubmenusExcept();
        widget.onOpenChange?.call(false);
      },
      menuChildren: [_surface(context, widget.actions, width)],
      builder: (context, controller, child) => Focus(
        focusNode: _focus,
        onKeyEvent: (_, event) {
          if (!_enabled || event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.contextMenu ||
              (event.logicalKey == LogicalKeyboardKey.f10 &&
                  HardwareKeyboard.instance.isShiftPressed)) {
            final box =
                _anchor.currentContext?.findRenderObject() as RenderBox?;
            _open(Offset(12, math.min(12, box?.size.height ?? 12)));
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapDown: _enabled
              ? (details) => _open(details.localPosition)
              : null,
          onLongPressStart: _enabled
              ? (details) => _open(details.localPosition)
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
