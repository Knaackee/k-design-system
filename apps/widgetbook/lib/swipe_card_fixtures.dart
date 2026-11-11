import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

// Decision 0016: swipe actions on list rows and KCard border effects.
// Storybook twins: src/swipe-card.stories.tsx (same fixture ids).

const _people = [
  ('Mara Feld', 'Moved the appointment to Thursday 14:00'),
  ('Jonas Kühn', 'Question about invoice 2026-118'),
  ('Lea Brandt', 'New booking: cut & blow-dry'),
  ('Tom Seidel', 'Thanks, see you next week!'),
];

class SwipeListFixture extends StatefulWidget {
  const SwipeListFixture({super.key});

  @override
  State<SwipeListFixture> createState() => _SwipeListFixtureState();
}

class _SwipeListFixtureState extends State<SwipeListFixture> {
  final _rows = _people.map((p) => p.$1).toSet();
  String _log = 'Swipe a row, or hover it with a pointer.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: KStack(
          gap: KLayoutGap.action,
          align: KLayoutAlign.stretch,
          children: [
            KList(
              children: [
                for (final (name, text) in _people)
                  if (_rows.contains(name))
                    KListItem(
                      key: ValueKey(name),
                      title: name,
                      description: text,
                      onPressed: () => setState(() => _log = 'Opened $name'),
                      leadingActions: [
                        KSwipeAction(
                          id: 'read',
                          label: 'Read',
                          icon: KIconName.mailOpen,
                          tone: KSwipeActionTone.info,
                          onSelect: () =>
                              setState(() => _log = 'Marked $name as read'),
                        ),
                      ],
                      trailingActions: [
                        KSwipeAction(
                          id: 'flag',
                          label: 'Flag',
                          icon: KIconName.flag,
                          tone: KSwipeActionTone.warning,
                          onSelect: () =>
                              setState(() => _log = 'Flagged $name'),
                        ),
                        KSwipeAction(
                          id: 'delete',
                          label: 'Delete',
                          icon: KIconName.trash,
                          tone: KSwipeActionTone.destructive,
                          fullSwipe: true,
                          onSelect: () => setState(() {
                            _rows.remove(name);
                            _log = 'Deleted $name';
                          }),
                        ),
                      ],
                    ),
              ],
            ),
            KText(_log, variant: KTextVariant.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KButton(
                label: 'Reset list',
                variant: KButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _rows.addAll(_people.map((p) => p.$1))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _effects = [
  (KCardBorder.pulse, 'Waiting for you', 'A question or approval needs input.'),
  (
    KCardBorder.spin,
    'Agent working',
    'A process runs until its result arrives.',
  ),
  (KCardBorder.aurora, 'AI input active', 'Composer while the agent responds.'),
  (KCardBorder.flame, 'Urgent', 'A deadline or critical error. Use sparingly.'),
  (KCardBorder.dashed, 'Drop here', 'Drop zone while dragging a file.'),
  (KCardBorder.shimmer, 'Loading', 'Content arrives in a moment.'),
  (KCardBorder.success, 'Saved', 'One pulse after a successful action.'),
];

Widget buildCardBorders(BuildContext context) => SingleChildScrollView(
  padding: const EdgeInsets.all(24),
  child: Wrap(
    spacing: 24,
    runSpacing: 24,
    children: [
      for (final (border, title, text) in _effects)
        SizedBox(
          width: 260,
          child: KCard(
            border: border,
            title: title,
            description: border.name,
            child: KText(text, variant: KTextVariant.bodySmall),
          ),
        ),
    ],
  ),
);

Widget buildCardHeader(BuildContext context) => Padding(
  padding: const EdgeInsets.all(16),
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 360,
      child: KCard(
        title: 'Rocky',
        description: 'Agent · working for 4 min',
        menu: const [
          KMenuAction(id: 'edit', label: 'Edit', icon: KIconName.pencil),
          KMenuAction(
            id: 'duplicate',
            label: 'Duplicate',
            icon: KIconName.copy,
          ),
          KMenuAction(
            id: 'delete',
            label: 'Delete',
            icon: KIconName.trash,
            destructive: true,
          ),
        ],
        actions: [
          KButton(label: 'Open', onPressed: () {}),
          KButton(
            label: 'Pause',
            variant: KButtonVariant.secondary,
            onPressed: () {},
          ),
        ],
        child: const KText(
          'Groups the feedback entries from the sheet by theme.',
          variant: KTextVariant.bodySmall,
        ),
      ),
    ),
  ),
);

/// Playground: border effect, colour and speed are parameters.
Widget buildCardBorderPlayground(BuildContext context) {
  final border = context.knobs.object.dropdown<KCardBorder>(
    label: 'Border',
    options: KCardBorder.values,
    initialOption: KCardBorder.spin,
    labelBuilder: (value) => value.name,
  );
  final color = context.knobs.colorOrNull(label: 'Colour');
  final duration = context.knobs.int.slider(
    label: 'Duration (ms, 0 = token)',
    initialValue: 0,
    max: 8000,
    divisions: 80,
  );
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 360,
        child: KCard(
          key: ValueKey('$border-$duration'),
          border: border,
          borderColor: color,
          borderDuration: duration == 0
              ? null
              : Duration(milliseconds: duration),
          title: 'Configurable border',
          description:
              'Effect, colour and duration are parameters; defaults come '
              'from component.cardBorder tokens.',
        ),
      ),
    ),
  );
}
