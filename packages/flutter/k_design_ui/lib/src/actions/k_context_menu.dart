import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_menu_surface.dart';
import 'k_menu_item_content.dart';
import 'k_menu_button.dart';

/// Dismisses the focused menu before its host handles platform Back.
bool kDismissFocusedMenu() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || !context.mounted) return false;
  final menu = MenuController.maybeOf(context);
  if (menu == null || !menu.isOpen) return false;
  menu.close();
  return true;
}

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
  final _anchor = GlobalKey();
  final _focus = FocusNode();

  bool get _enabled => !widget.disabled && widget.actions.isNotEmpty;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _open(Offset localPosition) {
    if (!_enabled) return;
    // Moving focus away from a menu item closes its child menus.
    if (MenuController.maybeOf(context) == null) _focus.requestFocus();
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

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final width = menuContentWidth(
      context,
      widget.actions,
      MediaQuery.sizeOf(context).width,
    );
    return MenuAnchor(
      key: _anchor,
      controller: _controller,
      consumeOutsideTap: true,
      childFocusNode: _focus,
      reservedPadding: EdgeInsets.all(t.spaceControlGap),
      style: _menuStyle(width),
      onOpen: () => widget.onOpenChange?.call(true),
      onClose: () {
        widget.onOpenChange?.call(false);
      },
      menuChildren: [
        KMenuSurface(
          actions: widget.actions,
          width: width,
          onClose: _controller.close,
        ),
      ],
      builder: (context, controller, child) => Focus(
        focusNode: _focus,
        skipTraversal: MenuController.maybeOf(this.context) != null,
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
