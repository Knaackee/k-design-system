import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../primitives/k_icon.dart';

part 'k_agent_switcher_parts.dart';
part 'k_agent_switcher_scroll.dart';

enum KAgentConnection { online, offline, unknown, sleeping }

enum KAgentActivityState { idle, working, needsInput }

typedef KAgentUnreadLabel = String Function(int count);
typedef KAgentReorderAnnouncement =
    String Function(String name, int position, int count);

String _defaultUnreadMessages(int count) =>
    '$count unread ${count == 1 ? 'message' : 'messages'}';

String _defaultReorderAnnouncement(String name, int position, int count) =>
    '$name moved to position $position of $count';

class KAgentSwitcherLabels {
  const KAgentSwitcherLabels({
    this.agents = 'Agents',
    this.connectionPrefix = 'Connection',
    this.connectionOnline = 'Online',
    this.connectionOffline = 'Offline',
    this.connectionUnknown = 'Unknown',
    this.connectionSleeping = 'Sleeping',
    this.activityPrefix = 'Activity',
    this.activityIdle = 'Idle',
    this.activityWorking = 'Working',
    this.activityNeedsInput = 'Needs input',
    this.unreadMessages = _defaultUnreadMessages,
    this.reorderInstruction = 'Long press and drag, or use Alt and arrow keys',
    this.reorderAnnouncement = _defaultReorderAnnouncement,
  });

  final String agents;
  final String connectionPrefix;
  final String connectionOnline;
  final String connectionOffline;
  final String connectionUnknown;
  final String connectionSleeping;
  final String activityPrefix;
  final String activityIdle;
  final String activityWorking;
  final String activityNeedsInput;
  final KAgentUnreadLabel unreadMessages;
  final String reorderInstruction;
  final KAgentReorderAnnouncement reorderAnnouncement;

  String connectionLabel(KAgentConnection value) => switch (value) {
    KAgentConnection.online => connectionOnline,
    KAgentConnection.offline => connectionOffline,
    KAgentConnection.unknown => connectionUnknown,
    KAgentConnection.sleeping => connectionSleeping,
  };

  String activityLabel(KAgentActivityState value) => switch (value) {
    KAgentActivityState.idle => activityIdle,
    KAgentActivityState.working => activityWorking,
    KAgentActivityState.needsInput => activityNeedsInput,
  };

  String unreadLabel(int count) => unreadMessages(count);
}

class KAgentSwitcherItem {
  const KAgentSwitcherItem({
    required this.id,
    required this.name,
    this.avatar,
    this.nameContent,
    this.statusContent,
    this.badgeContent,
    this.semanticLabel,
    this.connection,
    this.activity,
    this.unread,
    this.connectionColor,
    this.statusColor,
    this.badgeColor,
    this.badgeForeground,
    this.selectedColor,
    this.showName = true,
  }) : assert(unread == null || unread >= 0, 'unread must not be negative'),
       assert(
         semanticLabel != null || statusContent == null || activity != null,
         'semanticLabel is required for custom statusContent without activity',
       ),
       assert(
         semanticLabel != null || badgeContent == null || unread != null,
         'semanticLabel is required for custom badgeContent without unread',
       );

  final String id;
  final String name;
  final Widget? avatar;
  final Widget? nameContent;
  final Widget? statusContent;
  final Widget? badgeContent;
  final String? semanticLabel;
  final KAgentConnection? connection;
  final KAgentActivityState? activity;
  final int? unread;
  final Color? connectionColor;
  final Color? statusColor;
  final Color? badgeColor;
  final Color? badgeForeground;
  final Color? selectedColor;
  final bool showName;
}

/// A controlled, horizontally scrolling switcher for parallel agent chats.
///
/// Selection and ordering only report intent. Starting, stopping, or resuming
/// agent work remains the consumer's responsibility.
class KAgentSwitcher extends StatelessWidget {
  const KAgentSwitcher({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.onManage,
    this.manageLabel = 'Agenten auswählen',
    this.labels = const KAgentSwitcherLabels(),
    this.onReorder,
    this.onLongPress,
    super.key,
  });

  final List<KAgentSwitcherItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onManage;
  final String manageLabel;
  final KAgentSwitcherLabels labels;
  final ValueChanged<List<String>>? onReorder;
  final ValueChanged<String>? onLongPress;

  @override
  Widget build(BuildContext context) {
    assert(
      items.map((item) => item.id).toSet().length == items.length,
      'KAgentSwitcher item ids must be unique.',
    );
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final reorderable = onReorder != null && items.length > 1;
    return Semantics(
      container: true,
      label: labels.agents,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLayoutGutter,
          vertical: tokens.spaceControlGap,
        ),
        decoration: BoxDecoration(
          color: tokens.colorSurfaceRaised,
          border: Border(
            bottom: BorderSide(
              color: tokens.colorBorderDefault,
              width: tokens.borderWidthDefault,
            ),
          ),
        ),
        child: _HorizontalAgentScroll(
          builder: (controller) => reorderable
              ? SizedBox(
                  height: _switcherContentHeight(context, tokens),
                  child: ReorderableListView.builder(
                    scrollController: controller,
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    itemCount: items.length + (onManage == null ? 0 : 1),
                    onReorderItem: (oldIndex, newIndex) =>
                        _reorder(context, oldIndex, newIndex),
                    onReorderStart: (index) {
                      if (index < items.length) {
                        onLongPress?.call(items[index].id);
                      }
                    },
                    proxyDecorator: (child, _, _) => child,
                    itemBuilder: (context, index) =>
                        _reorderableItem(context, index),
                  ),
                )
              : SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.spaceControlGap,
                    children: [
                      for (var index = 0; index < items.length; index++)
                        _bubble(context, index, reorderable: false),
                      if (onManage != null)
                        _ManageBubble(label: manageLabel, onPressed: onManage!),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _reorderableItem(BuildContext context, int index) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    if (index == items.length) {
      return Padding(
        key: const ValueKey('k-agent-switcher-manage-slot'),
        padding: EdgeInsetsDirectional.only(end: tokens.spaceControlGap),
        child: _ManageBubble(label: manageLabel, onPressed: onManage!),
      );
    }
    return ReorderableDelayedDragStartListener(
      key: ValueKey('k-agent-switcher-reorder-${items[index].id}'),
      index: index,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: tokens.spaceControlGap),
        child: _bubble(context, index, reorderable: true),
      ),
    );
  }

  Widget _bubble(
    BuildContext context,
    int index, {
    required bool reorderable,
  }) => _AgentBubble(
    item: items[index],
    index: index,
    selected: items[index].id == selectedId,
    labels: labels,
    itemCount: items.length,
    reorderable: reorderable,
    onSelect: () => onSelect(items[index].id),
    onLongPress: !reorderable && onLongPress != null
        ? () => onLongPress!.call(items[index].id)
        : null,
    onMovePrevious: reorderable && index > 0
        ? () => _move(context, index, index - 1)
        : null,
    onMoveNext: reorderable && index < items.length - 1
        ? () => _move(context, index, index + 1)
        : null,
  );

  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    if (oldIndex >= items.length) return;
    _move(context, oldIndex, newIndex.clamp(0, items.length - 1).toInt());
  }

  void _move(BuildContext context, int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final ids = items.map((item) => item.id).toList();
    final name = items[oldIndex].name;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    onReorder?.call(List.unmodifiable(ids));
    if (MediaQuery.supportsAnnounceOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        labels.reorderAnnouncement(name, newIndex + 1, items.length),
        Directionality.of(context),
      );
    }
  }
}
