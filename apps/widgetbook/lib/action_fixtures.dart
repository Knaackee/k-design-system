import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ActionFixture extends StatefulWidget {
  const ActionFixture({this.kind = 'toolbar', super.key});
  final String kind;
  @override
  State<ActionFixture> createState() => _ActionFixtureState();
}

class _ActionFixtureState extends State<ActionFixture> {
  String result = 'No action selected';
  void selected(String label) => setState(() => result = '$label selected');
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final actions = [
      KMenuAction(
        id: 'copy',
        label: 'Copy link',
        icon: KIconName.link,
        onSelect: () => selected('Copy link'),
      ),
      KMenuAction(
        id: 'duplicate',
        label: 'Duplicate',
        icon: KIconName.copy,
        onSelect: () => selected('Duplicate'),
      ),
      KMenuAction(
        id: 'export',
        label: 'Export',
        icon: KIconName.download,
        disabled: true,
        onSelect: () => selected('Export'),
      ),
      KMenuAction(
        id: 'archive',
        label: 'Archive',
        icon: KIconName.folder,
        separatorBefore: true,
        onSelect: () => selected('Archive'),
      ),
      KMenuAction(
        id: 'delete',
        label: 'Delete',
        icon: KIconName.trash,
        destructive: true,
        onSelect: () => selected('Delete'),
      ),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            KText(
              widget.kind == 'toolbar'
                  ? 'Workspace actions'
                  : widget.kind == 'menu'
                  ? 'Action menu'
                  : 'Icon actions',
              variant: KTextVariant.heading4,
            ),
            KToolbar(
              label: 'Workspace actions',
              children: [
                if (widget.kind == 'toolbar')
                  KButton(
                    label: 'New item',
                    onPressed: () => selected('New item'),
                  ),
                if (widget.kind != 'icon')
                  KMenuButton(label: 'Actions', actions: actions),
                if (widget.kind != 'menu')
                  KIconButton(
                    label: 'Refresh',
                    icon: KIconName.refreshCw,
                    onPressed: () => selected('Refresh'),
                  ),
                if (widget.kind == 'icon')
                  const KIconButton(
                    label: 'Unavailable',
                    icon: KIconName.download,
                    onPressed: null,
                  )
                else
                  KOverflowMenu(label: 'More actions', actions: actions),
              ],
            ),
            Semantics(liveRegion: true, child: KText(result)),
          ],
        ),
      ),
    );
  }
}
