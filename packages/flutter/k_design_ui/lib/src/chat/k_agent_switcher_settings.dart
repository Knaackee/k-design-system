part of 'k_agent_switcher.dart';

extension _AgentSwitcherSettings on KAgentSwitcher {
  Widget _settingsList(BuildContext context, KDesignTokens tokens) => Semantics(
    container: true,
    label: labels.agents,
    child: ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: (oldIndex, newIndex) {
        if (items[oldIndex].reorderable && onReorder != null) {
          _move(context, oldIndex, newIndex);
        }
      },
      proxyDecorator: (child, _, _) => child,
      itemBuilder: (context, index) {
        final item = items[index];
        final enabled = item.reorderable && onReorder != null;
        final handle = Semantics(
          label: '${item.name}: ${labels.reorderInstruction}',
          child: IconButton(
            tooltip: '${item.name}: ${labels.reorderInstruction}',
            onPressed: enabled ? () {} : null,
            icon: const KIcon(KIconName.gripVertical),
          ),
        );
        return Padding(
          key: ValueKey('k-agent-settings-${item.id}'),
          padding: EdgeInsets.symmetric(vertical: tokens.spaceControlGap),
          child: Row(
            spacing: tokens.spaceControlGap,
            children: [
              SizedBox.square(
                dimension: tokens.componentAvatarSizeMedium + tokens.spaceTight,
                child: item.avatar ?? const KIcon(KIconName.bot),
              ),
              Expanded(child: item.nameContent ?? Text(item.name)),
              if (item.controlContent != null) item.controlContent!,
              CallbackShortcuts(
                bindings: enabled
                    ? {
                        const SingleActivator(
                          LogicalKeyboardKey.arrowUp,
                          alt: true,
                        ): () => _move(
                          context,
                          index,
                          (index - 1).clamp(0, items.length - 1),
                        ),
                        const SingleActivator(
                          LogicalKeyboardKey.arrowDown,
                          alt: true,
                        ): () => _move(
                          context,
                          index,
                          (index + 1).clamp(0, items.length - 1),
                        ),
                      }
                    : {},
                child: enabled
                    ? _AgentReorderDragStartListener(
                        index: index,
                        child: handle,
                      )
                    : handle,
              ),
            ],
          ),
        );
      },
    ),
  );
}
