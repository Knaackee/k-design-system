import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ContextMenuFixture extends StatefulWidget {
  const ContextMenuFixture({super.key});

  @override
  State<ContextMenuFixture> createState() => _ContextMenuFixtureState();
}

class _ContextMenuFixtureState extends State<ContextMenuFixture> {
  String result = 'No action selected';

  void selected(String value) => setState(() => result = value);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final actions = [
      KMenuAction(
        id: 'copy',
        label: 'Copy link',
        icon: KIconName.copy,
        onSelect: () => selected('Copy link selected'),
      ),
      KMenuAction(
        id: 'move',
        label: 'Move to',
        icon: KIconName.folder,
        children: [
          KMenuAction(
            id: 'project-orbit',
            label: 'Orbit',
            icon: KIconName.folder,
            onSelect: () => selected('Moved to Orbit'),
          ),
          KMenuAction(
            id: 'project-design',
            label: 'Design system',
            icon: KIconName.folder,
            onSelect: () => selected('Moved to Design system'),
          ),
        ],
      ),
      const KMenuAction(
        id: 'share',
        label: 'Share',
        icon: KIconName.link,
        disabled: true,
      ),
      KMenuAction(
        id: 'delete',
        label: 'Delete',
        icon: KIconName.trash,
        destructive: true,
        separatorBefore: true,
        onSelect: () => selected('Delete selected'),
      ),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Context menu', variant: KTextVariant.heading4),
            KContextMenu(
              label: 'Document actions',
              actions: actions,
              child: MouseRegion(
                cursor: SystemMouseCursors.contextMenu,
                child: KCard(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80),
                    child: KStack(
                      gap: KLayoutGap.control,
                      children: const [
                        KText('Project brief', variant: KTextVariant.label),
                        KText(
                          'Right-click or long-press this card.',
                          variant: KTextVariant.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Semantics(liveRegion: true, child: KText(result)),
          ],
        ),
      ),
    );
  }
}
