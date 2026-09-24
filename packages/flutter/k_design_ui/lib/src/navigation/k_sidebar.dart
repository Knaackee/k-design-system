import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';

enum KSidebarMode { expanded, rail, hidden }

class KSidebar extends StatelessWidget {
  const KSidebar({
    required this.mode,
    required this.child,
    this.onModeChanged,
    this.expandedWidth = 248,
    this.railWidth = 52,
    this.semanticLabel = 'Sidebar',
    super.key,
  });

  final KSidebarMode mode;
  final ValueChanged<KSidebarMode>? onModeChanged;
  final Widget child;
  final double expandedWidth;
  final double railWidth;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (mode == KSidebarMode.hidden) return const SizedBox.shrink();
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final width = mode == KSidebarMode.rail ? railWidth : expandedWidth;
    return _KSidebarScope(
      mode: mode,
      onModeChanged: onModeChanged,
      child: Semantics(
        label: semanticLabel,
        container: true,
        child: AnimatedContainer(
          duration: tokens.componentSidebarTransitionDuration,
          curve: Curves.easeOutCubic,
          width: width,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            border: Border(right: BorderSide(color: tokens.colorBorderDefault)),
          ),
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }
}

class _KSidebarScope extends InheritedWidget {
  const _KSidebarScope({
    required this.mode,
    required this.onModeChanged,
    required super.child,
  });
  final KSidebarMode mode;
  final ValueChanged<KSidebarMode>? onModeChanged;

  static _KSidebarScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KSidebarScope>()!;

  @override
  bool updateShouldNotify(_KSidebarScope oldWidget) =>
      mode != oldWidget.mode || onModeChanged != oldWidget.onModeChanged;
}

class KSidebarHeader extends StatelessWidget {
  const KSidebarHeader({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 4), child: child);
}

class KSidebarBody extends StatelessWidget {
  const KSidebarBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Scrollbar(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        children: children,
      ),
    ),
  );
}

class KSidebarFooter extends StatelessWidget {
  const KSidebarFooter({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 8), child: child);
}

class KSidebarModeContent extends StatelessWidget {
  const KSidebarModeContent({this.expanded, this.rail, super.key});
  final Widget? expanded;
  final Widget? rail;
  @override
  Widget build(BuildContext context) {
    final mode = _KSidebarScope.of(context).mode;
    return mode == KSidebarMode.rail
        ? (rail ?? const SizedBox.shrink())
        : (expanded ?? const SizedBox.shrink());
  }
}

class KSidebarToggle extends StatelessWidget {
  const KSidebarToggle({
    this.collapseLabel = 'Collapse sidebar',
    this.expandLabel = 'Expand sidebar',
    super.key,
  });
  final String collapseLabel;
  final String expandLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _KSidebarScope.of(context);
    final expanded = scope.mode == KSidebarMode.expanded;
    return _SidebarIconControl(
      label: expanded ? collapseLabel : expandLabel,
      icon: expanded ? KIconName.chevronLeft : KIconName.chevronRight,
      onPressed: scope.onModeChanged == null
          ? null
          : () => scope.onModeChanged!(
              expanded ? KSidebarMode.rail : KSidebarMode.expanded,
            ),
    );
  }
}

class KSidebarGroup extends StatefulWidget {
  const KSidebarGroup({
    required this.children,
    this.label,
    this.labelContent,
    this.action,
    this.collapsible = false,
    this.expanded,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
    super.key,
  });
  final String? label;
  final Widget? labelContent;
  final Widget? action;
  final bool collapsible;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final List<Widget> children;

  @override
  State<KSidebarGroup> createState() => _KSidebarGroupState();
}

class _KSidebarGroupState extends State<KSidebarGroup> {
  late bool internalExpanded = widget.initiallyExpanded;

  bool get expanded => widget.expanded ?? internalExpanded;

  void toggle() {
    final next = !expanded;
    if (widget.expanded == null) setState(() => internalExpanded = next);
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final scope = _KSidebarScope.of(context);
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final showHeading =
        scope.mode == KSidebarMode.expanded &&
        (widget.label != null ||
            widget.labelContent != null ||
            widget.action != null);
    return Padding(
      padding: EdgeInsets.only(bottom: t.spaceControlGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeading)
            SizedBox(
              height: t.componentSidebarGroupHeaderHeight,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(t.radiusControl),
                      onTap: widget.collapsible ? toggle : null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: t.spaceControlGap,
                        ),
                        child: Row(
                          children: [
                            if (widget.collapsible) ...[
                              KIcon(
                                expanded
                                    ? KIconName.chevronDown
                                    : KIconName.chevronRight,
                                size: 12,
                                color: t.colorTextMuted,
                              ),
                              SizedBox(width: t.spaceTight),
                            ],
                            Expanded(
                              child:
                                  widget.labelContent ??
                                  Text(
                                    widget.label ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: t.colorTextMuted,
                                      fontFamily: t.fontFamily,
                                      fontSize: t.fontCaptionSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.action != null) widget.action!,
                ],
              ),
            ),
          if (expanded || !widget.collapsible) ...widget.children,
        ],
      ),
    );
  }
}

class KSidebarItem extends StatefulWidget {
  const KSidebarItem({
    required this.label,
    this.labelContent,
    this.leading,
    this.badge,
    this.trailing,
    this.action,
    this.active = false,
    this.disabled = false,
    this.depth = 0,
    this.expanded,
    this.onPressed,
    super.key,
  });
  final String label;
  final Widget? labelContent;
  final Widget? leading;
  final Widget? badge;
  final Widget? trailing;
  final Widget? action;
  final bool active;
  final bool disabled;
  final int depth;
  final bool? expanded;
  final VoidCallback? onPressed;

  @override
  State<KSidebarItem> createState() => _KSidebarItemState();
}

class _KSidebarItemState extends State<KSidebarItem> {
  bool hovered = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final scope = _KSidebarScope.of(context);
    final rail = scope.mode == KSidebarMode.rail;
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final showAction = !rail && widget.action != null && (hovered || focused);
    final minHeight = math.max(36.0, t.sizeHitTarget);
    final color = widget.active
        ? t.colorActionSecondaryBackground
        : hovered || focused
        ? t.colorActionGhostHover
        : Colors.transparent;
    final item = FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (value) => setState(() => hovered = value),
      onShowFocusHighlight: (value) => setState(() => focused = value),
      child: Semantics(
        label: widget.label,
        button: true,
        selected: widget.active,
        enabled: !widget.disabled,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(t.radiusControl),
          child: InkWell(
            borderRadius: BorderRadius.circular(t.radiusControl),
            onTap: widget.disabled ? null : widget.onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.only(
                  left: rail ? 0 : 8 + widget.depth * 20,
                  right: rail ? 0 : 4,
                ),
                child: rail
                    ? Center(child: widget.leading)
                    : Row(
                        children: [
                          SizedBox(
                            width: t.componentSidebarLeadingWidth,
                            child: Center(child: widget.leading),
                          ),
                          SizedBox(width: t.spaceControlGap),
                          Expanded(
                            child:
                                widget.labelContent ??
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.disabled
                                        ? t.colorTextMuted
                                        : widget.active || hovered || focused
                                        ? t.colorTextPrimary
                                        : t.colorTextMuted,
                                    fontFamily: t.fontFamily,
                                    fontSize: t.fontControlSize,
                                    fontWeight: widget.active
                                        ? FontWeight.w600
                                        : t.fontControlWeight,
                                  ),
                                ),
                          ),
                          if (showAction)
                            SizedBox(
                              width: t.componentSidebarActionWidth,
                              child: Center(child: widget.action),
                            )
                          else ...[
                            if (widget.badge != null) widget.badge!,
                            if (widget.trailing != null) ...[
                              SizedBox(width: t.spaceSmallInset),
                              widget.trailing!,
                            ],
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!rail || widget.badge == null) {
      return Tooltip(message: rail ? widget.label : '', child: item);
    }
    return Tooltip(
      message: widget.label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          item,
          Positioned(
            right: -2,
            top: -2,
            child: IgnorePointer(
              child: Transform.scale(
                scale: .73,
                alignment: Alignment.topRight,
                child: widget.badge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KSidebarSubgroup extends StatefulWidget {
  const KSidebarSubgroup({
    required this.label,
    required this.children,
    this.labelContent,
    this.leading,
    this.badge,
    this.action,
    this.depth = 0,
    this.expanded,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
    super.key,
  });
  final String label;
  final Widget? labelContent;
  final Widget? leading;
  final Widget? badge;
  final Widget? action;
  final int depth;
  final bool? expanded;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final List<Widget> children;

  @override
  State<KSidebarSubgroup> createState() => _KSidebarSubgroupState();
}

class _KSidebarSubgroupState extends State<KSidebarSubgroup> {
  late bool internalExpanded = widget.initiallyExpanded;

  bool get expanded => widget.expanded ?? internalExpanded;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KSidebarItem(
        label: widget.label,
        labelContent: widget.labelContent,
        leading: widget.leading,
        badge: widget.badge,
        action: widget.action,
        depth: widget.depth,
        expanded: expanded,
        trailing: KSidebarModeContent(
          expanded: KIcon(
            expanded ? KIconName.chevronDown : KIconName.chevronRight,
            size: 14,
          ),
        ),
        onPressed: () {
          final next = !expanded;
          if (widget.expanded == null) {
            setState(() => internalExpanded = next);
          }
          widget.onExpandedChanged?.call(next);
        },
      ),
      if (expanded && _KSidebarScope.of(context).mode == KSidebarMode.expanded)
        ...widget.children,
    ],
  );
}

class KSidebarSeparator extends StatelessWidget {
  const KSidebarSeparator({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Divider(
      height: t.componentSidebarSeparatorHeight,
      thickness: t.borderWidthDefault,
      color: t.colorBorderDefault,
    );
  }
}

class _SidebarIconControl extends StatelessWidget {
  const _SidebarIconControl({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final KIconName icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Tooltip(
      message: label,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        constraints: BoxConstraints.tightFor(
          width: math.max(40, t.sizeHitTarget),
          height: math.max(40, t.sizeHitTarget),
        ),
        icon: KIcon(icon),
      ),
    );
  }
}
