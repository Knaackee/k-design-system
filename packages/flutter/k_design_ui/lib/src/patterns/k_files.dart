import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_leading.dart';
import '../primitives/k_text.dart';
import '../primitives/k_button.dart';
import '../forms/k_input.dart';
import '../forms/k_select.dart';
import '../primitives/k_file_icon.dart';
import '../actions/k_menu_button.dart';
import '../actions/k_context_menu.dart';
import '../actions/k_icon_button.dart';

part 'k_file_transfer_panel.dart';
part 'k_file_storage.dart';
part 'k_file_share.dart';

class KFileNode {
  const KFileNode({
    required this.id,
    required this.name,
    this.folder = false,
    this.icon,
    this.detail,
    this.children = const [],
  });
  final String id;
  final String name;
  final bool folder;
  final KIconName? icon;
  final Widget? detail;
  final List<KFileNode> children;
}

/// Controlled tree: routing, permissions and mutations belong to the host.
class KFileTree extends StatelessWidget {
  const KFileTree({
    required this.nodes,
    required this.expandedIds,
    required this.onSelect,
    required this.onExpandedChange,
    this.selectedId,
    this.label = 'Dateien',
    this.emptyContent,
    this.actions,
    this.menuActions,
    super.key,
  });
  final List<KFileNode> nodes;
  final Set<String> expandedIds;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<Set<String>> onExpandedChange;
  final String label;
  final Widget? emptyContent;
  final Widget Function(KFileNode)? actions;
  final List<KMenuAction> Function(KFileNode)? menuActions;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    List<Widget> rows(List<KFileNode> items, int depth) => [
      for (final node in items) ...[
        _FileTreeRow(
          node: node,
          depth: depth,
          selected: node.id == selectedId,
          expanded: expandedIds.contains(node.id),
          actions: actions?.call(node),
          menuActions: menuActions?.call(node) ?? [],
          onSelect: () => onSelect(node.id),
          onToggle: () {
            final next = {...expandedIds};
            if (!next.remove(node.id)) next.add(node.id);
            onExpandedChange(next);
          },
        ),
        if (expandedIds.contains(node.id)) ...rows(node.children, depth + 1),
      ],
    ];
    return Semantics(
      label: label,
      child: nodes.isEmpty
          ? Padding(
              padding: EdgeInsets.all(t.sizeIconDefault),
              child:
                  emptyContent ??
                  const Center(child: Text('Noch keine Dateien')),
            )
          : Column(mainAxisSize: MainAxisSize.min, children: rows(nodes, 0)),
    );
  }
}

class _FileTreeRow extends StatefulWidget {
  const _FileTreeRow({
    required this.node,
    required this.depth,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
    required this.menuActions,
    this.actions,
  });
  final KFileNode node;
  final int depth;
  final bool selected, expanded;
  final VoidCallback onToggle, onSelect;
  final List<KMenuAction> menuActions;
  final Widget? actions;
  @override
  State<_FileTreeRow> createState() => _FileTreeRowState();
}

class _FileTreeRowState extends State<_FileTreeRow> {
  bool hovered = false, focused = false, menuOpen = false;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final touch = MediaQuery.sizeOf(context).width < 600;
    return KContextMenu(
      label: widget.node.name,
      actions: widget.menuActions,
      child: Focus(
        onFocusChange: (value) => setState(() => focused = value),
        child: MouseRegion(
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: Material(
            color: widget.selected ? t.colorSurfaceRaised : Colors.transparent,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: t.spaceTight + widget.depth * t.spaceSmallInset,
                end: t.spaceTight,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: t.componentFilesIconSize + t.spaceTight * 2,
                    height: t.sizeControl,
                    child: widget.node.folder
                        ? InkWell(
                            key: ValueKey('files-toggle-${widget.node.id}'),
                            onTap: widget.onToggle,
                            child: Center(
                              child: KIcon(
                                widget.expanded
                                    ? KIconName.chevronDown
                                    : KIconName.chevronRight,
                                size: t.componentFilesIconSize,
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: t.spaceMicro),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onSelect,
                      child: SizedBox(
                        height: t.sizeControl,
                        child: Row(
                          children: [
                            if (widget.node.icon != null)
                              KIcon(widget.node.icon!, size: 16)
                            else
                              KFileIcon(
                                name: widget.node.name,
                                folder: widget.node.folder,
                                expanded: widget.expanded,
                              ),
                            SizedBox(width: t.spaceSmallInset),
                            Expanded(
                              child: Text(
                                widget.node.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: t.fontControlSize),
                              ),
                            ),
                            if (widget.node.detail != null)
                              DefaultTextStyle.merge(
                                style: TextStyle(
                                  fontSize: t.fontCaptionSize,
                                  color: t.colorTextMuted,
                                ),
                                child: widget.node.detail!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.actions != null) widget.actions!,
                  if (!touch && widget.menuActions.isNotEmpty)
                    Visibility(
                      visible: hovered || focused || menuOpen,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: KMenuButton(
                        label: '${widget.node.name}: Aktionen',
                        overflow: true,
                        actions: widget.menuActions,
                        onOpenChange: (value) =>
                            setState(() => menuOpen = value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KFileTransfer {
  const KFileTransfer({
    required this.id,
    required this.name,
    required this.progress,
    required this.status,
    this.error,
    this.canPause = true,
    this.canResume = true,
    this.canCancel = true,
  });
  final String id;
  final String name;
  final double progress;
  final String status;
  final String? error;
  final bool canPause, canResume, canCancel;
}

class KTransferList extends StatelessWidget {
  const KTransferList({
    required this.items,
    this.onPause,
    this.onResume,
    this.onCancel,
    super.key,
  });
  final List<KFileTransfer> items;
  final ValueChanged<String>? onPause, onResume, onCancel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontControlSize,
        color: t.colorTextPrimary,
        height: t.componentFilesTextLineHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.spaceLayoutGutter,
                vertical: t.spaceControlInsetInline,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      KFileIcon(name: item.name, size: 16),
                      SizedBox(width: t.spaceControlInsetInline),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              item.status,
                              style: TextStyle(
                                fontSize: t.fontCaptionSize,
                                color: t.colorTextMuted,
                              ),
                            ),
                            SizedBox(height: t.spaceSmallInset),
                            LinearProgressIndicator(
                              value: item.progress.clamp(0, 1),
                              minHeight: t.sizeProgressThin,
                              color: t.colorTextPrimary,
                              backgroundColor: t.colorBorderDefault,
                            ),
                          ],
                        ),
                      ),
                      if (item.progress >= 1) ...[
                        SizedBox(width: t.spaceControlInsetInline),
                        const KIcon(KIconName.check, size: 16),
                      ],
                    ],
                  ),
                  if (item.error != null) Text(item.error!),
                  if ((onPause != null && item.canPause) ||
                      (onResume != null && item.canResume) ||
                      (onCancel != null && item.canCancel))
                    Wrap(
                      children: [
                        if (onPause != null && item.canPause)
                          KButton(
                            label: 'Pausieren',
                            variant: KButtonVariant.ghost,
                            onPressed: () => onPause!(item.id),
                          ),
                        if (onResume != null && item.canResume)
                          KButton(
                            label: 'Fortsetzen',
                            variant: KButtonVariant.ghost,
                            onPressed: () => onResume!(item.id),
                          ),
                        if (onCancel != null && item.canCancel)
                          KButton(
                            label: 'Abbrechen',
                            variant: KButtonVariant.ghost,
                            onPressed: () => onCancel!(item.id),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class KFileInfo extends StatelessWidget {
  const KFileInfo({
    required this.name,
    required this.properties,
    this.actions,
    super.key,
  });
  final String name;
  final Map<String, String> properties;
  final Widget? actions;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontControlSize,
        height: t.componentFilesTextLineHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KIcon(KIconName.fileText, size: 24, color: t.colorTextMuted),
              SizedBox(width: t.spaceControlInsetInline),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceLayoutSectionGap),
          for (final property in properties.entries)
            Padding(
              padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
              child: LayoutBuilder(
                builder: (context, bounds) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width:
                          ((bounds.maxWidth - t.spaceControlInsetInline) *
                                  .65 /
                                  1.65)
                              .clamp(90, bounds.maxWidth),
                      child: Text(
                        property.key,
                        style: TextStyle(color: t.colorTextMuted),
                      ),
                    ),
                    SizedBox(width: t.spaceControlInsetInline),
                    Expanded(child: SelectableText(property.value)),
                  ],
                ),
              ),
            ),
          ?actions,
        ],
      ),
    );
  }
}
