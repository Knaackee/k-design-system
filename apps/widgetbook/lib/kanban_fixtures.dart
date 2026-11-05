import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

@immutable
class _DemoCard {
  const _DemoCard({
    required this.id,
    required this.title,
    required this.priority,
    required this.project,
    this.tag,
  });

  final String id;
  final String title;
  final String priority;
  final String project;
  final String? tag;
}

class KanbanFixture extends StatefulWidget {
  const KanbanFixture({this.selection = false, super.key});

  final bool selection;

  @override
  State<KanbanFixture> createState() => _KanbanFixtureState();
}

class _KanbanFixtureState extends State<KanbanFixture> {
  late List<KKanbanColumn<_DemoCard>> _columns;
  late Set<String> _selected;
  String _message = 'Drag a card or open it';

  @override
  void initState() {
    super.initState();
    _selected = widget.selection ? {'ISS-326'} : <String>{};
    _columns = const [
      KKanbanColumn<_DemoCard>(
        id: 'backlog',
        title: Text('Backlog'),
        leading: KIcon(KIconName.circleAlert, size: 16),
        addLabel: '+ Add issue',
        items: [
          _DemoCard(
            id: 'ISS-311',
            title: 'Unify navigation patterns',
            priority: 'Medium',
            project: 'Orbit',
          ),
          _DemoCard(
            id: 'ISS-326',
            title: 'Improve sign-in feedback',
            priority: 'Low',
            project: 'Orbit',
          ),
          _DemoCard(
            id: 'ISS-343',
            title: 'Plan browser extension',
            priority: 'Medium',
            project: 'Workspace',
            tag: 'Research',
          ),
        ],
      ),
      KKanbanColumn<_DemoCard>(
        id: 'todo',
        title: Text('To do'),
        leading: KIcon(KIconName.circleCheck, size: 16),
        addLabel: '+ Add issue',
        items: [
          _DemoCard(
            id: 'ISS-389',
            title: 'Refresh repository list',
            priority: 'High',
            project: 'Orbit',
          ),
          _DemoCard(
            id: 'ISS-390',
            title: 'Add nested context menus',
            priority: 'Medium',
            project: 'Web',
          ),
        ],
      ),
      KKanbanColumn<_DemoCard>(
        id: 'progress',
        title: Text('In progress'),
        leading: KIcon(KIconName.clock, size: 16),
        addLabel: '+ Add issue',
        items: [
          _DemoCard(
            id: 'ISS-354',
            title: 'Refine project dialog',
            priority: 'Medium',
            project: 'Orbit',
            tag: 'Question',
          ),
          _DemoCard(
            id: 'ISS-360',
            title: 'Polish Markdown rendering',
            priority: 'Medium',
            project: 'Editor',
            tag: 'Review',
          ),
        ],
      ),
      KKanbanColumn<_DemoCard>(
        id: 'blocked',
        title: Text('Blocked'),
        leading: KIcon(KIconName.triangleAlert, size: 16),
        addLabel: '+ Add issue',
        items: [
          _DemoCard(
            id: 'ISS-334',
            title: 'Align mobile bottom sheet',
            priority: 'Urgent',
            project: 'Mobile',
          ),
        ],
      ),
    ];
  }

  void _move(KKanbanMove<_DemoCard> move) {
    setState(() {
      final next = [
        for (final column in _columns)
          KKanbanColumn<_DemoCard>(
            id: column.id,
            title: column.title,
            items: List.of(column.items),
            leading: column.leading,
            trailing: column.trailing,
            addLabel: column.addLabel,
          ),
      ];
      final source = next.firstWhere(
        (column) => column.id == move.sourceColumnId,
      );
      final target = next.firstWhere(
        (column) => column.id == move.targetColumnId,
      );
      source.items.removeAt(move.sourceIndex);
      target.items.insert(move.targetIndex, move.item);
      _columns = next;
      _message = '${move.itemId} moved to ${move.targetColumnId}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight - tokens.spaceLayoutGutter * 2
            : 640.0;
        final height = available.clamp(480.0, 680.0).toDouble();
        // The board keeps its height; the page scrolls when large text
        // makes the status line below it taller than the remaining space.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KKanban<_DemoCard>(
                columns: _columns,
                itemId: (item) => item.id,
                itemLabel: (item) => item.title,
                selectedItemIds: _selected,
                onSelectionChanged: (value) =>
                    setState(() => _selected = value),
                onCardOpen: (item, _) =>
                    setState(() => _message = 'Opened ${item.id}'),
                onAddCard: (columnId) =>
                    setState(() => _message = 'Add requested for $columnId'),
                onCardMove: _move,
                height: height,
                cardBuilder: (context, card) => _KanbanCard(
                  item: card.item,
                  selected: card.selected,
                  onSelected: card.toggleSelected,
                  onAction: () => setState(
                    () => _message = 'Actions requested for ${card.item.id}',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceLayoutGutter,
                ),
                child: Semantics(liveRegion: true, child: Text(_message)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final _DemoCard item;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final metaStyle = TextStyle(
      color: tokens.colorTextMuted,
      fontFamily: tokens.fontFamily,
      fontSize: tokens.fontBodySmallSize,
      height: tokens.fontBodySmallLineHeight / tokens.fontBodySmallSize,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => onSelected(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: tokens.spaceControlGap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: tokens.colorTextPrimary,
                    fontFamily: tokens.fontFamily,
                    fontSize: tokens.fontLabelSize,
                    fontWeight: FontWeight.w600,
                    height: tokens.fontLabelLineHeight / tokens.fontLabelSize,
                  ),
                ),
              ),
            ),
            KIconButton(
              icon: KIconName.ellipsis,
              label: 'Actions for ${item.title}',
              onPressed: onAction,
            ),
          ],
        ),
        SizedBox(height: tokens.spaceControlGap),
        Wrap(
          spacing: tokens.spaceControlGap,
          runSpacing: tokens.spaceControlGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(item.id, style: metaStyle),
            Text(item.priority, style: metaStyle),
            if (item.tag != null) Text(item.tag!, style: metaStyle),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KIcon(KIconName.folder, size: 16, color: tokens.colorTextMuted),
                const SizedBox(width: 4),
                Text(item.project, style: metaStyle),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
