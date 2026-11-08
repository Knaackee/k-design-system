import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_focus_ring.dart';
import 'k_menu_item_content.dart';
import '../primitives/k_surface.dart';
import 'k_menu_button.dart';

/// Shared nested-menu surface used by context menus and menu buttons.
class KMenuSurface extends StatefulWidget {
  const KMenuSurface({
    required this.actions,
    required this.width,
    required this.onClose,
    this.header,
    super.key,
  });
  final List<KMenuAction> actions;
  final double width;
  final VoidCallback onClose;
  final Widget? header;
  @override
  State<KMenuSurface> createState() => _KMenuSurfaceState();
}

class _KMenuSurfaceState extends State<KMenuSurface> {
  final _submenuControllers = <String, MenuController>{};
  MenuController _submenuController(String path) =>
      _submenuControllers.putIfAbsent(path, MenuController.new);
  void _closeSubmenusExcept([String? path]) {
    for (final entry in _submenuControllers.entries) {
      if ((path == null ||
              !(path == entry.key || path.startsWith('${entry.key}/'))) &&
          entry.value.isOpen) {
        entry.value.close();
      }
    }
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
          : states.contains(WidgetState.hovered) || kFocusVisible(states)
          ? t.colorActionGhostHover
          : Colors.transparent,
    ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: kFocusVisible(states) ? t.colorBorderFocus : Colors.transparent,
        width: t.borderWidthStrong,
      ),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusControl),
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
              if (parentPath.isEmpty && widget.header != null)
                Padding(
                  padding: EdgeInsets.all(t.spaceControlInsetInline),
                  child: widget.header!,
                ),
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
                    submenuIcon: const WidgetStatePropertyAll(
                      SizedBox.shrink(),
                    ),
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
                    child: KMenuItemContent(action: action, width: width),
                  ).withMenuItemContext(action)
                else
                  MenuItemButton(
                    key: ValueKey(action.id),
                    style: _itemStyle(t, action),
                    onHover: (hovered) {
                      if (hovered) {
                        _closeSubmenusExcept(
                          parentPath.isEmpty ? null : parentPath,
                        );
                      }
                    },
                    onFocusChange: (focused) {
                      if (focused) {
                        _closeSubmenusExcept(
                          parentPath.isEmpty ? null : parentPath,
                        );
                      }
                    },
                    onPressed: action.disabled
                        ? null
                        : () {
                            widget.onClose();
                            action.onSelect?.call();
                          },
                    child: KMenuItemContent(action: action, width: width),
                  ).withMenuItemContext(action),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _surface(context, widget.actions, widget.width);
}
