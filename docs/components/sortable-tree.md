# KSortableTree

Controlled sortable hierarchy for Web and Flutter. The consumer owns nodes,
product actions, persistence, confirmation and undo. Gallery fixtures demonstrate
these actions with KMenuButton, KDialog, KAlertDialog and KToast.

## Shared contract

- `KSortableTreeNode`: stable unique `id`, `label`, optional `data`, optional
  `children`. An empty children collection represents an empty container.
- `KSortableTreeMove`: `id`, nullable `parentId`, destination `index` **after**
  removing the source. `onMove` does not mutate the supplied nodes.
- `moveKSortableTree` rejects cycles, leaf destinations, invalid indices and
  moves exceeding `maxDepth`. `flattenKSortableTree` rejects duplicate IDs.
- `expandedIds` / `onExpandedChange` control real containers. Omit the value to
  manage expansion inside the component.
- `renderContent`, `renderActions`, `getActions`, `canMove`, `disabled`, `labels`
  and `ariaLabel` provide consumer customization.
- Web callbacks receive a context; Flutter render callbacks additionally receive
  BuildContext. Flutter uses Set<String> for expanded IDs and List for nodes.

## Uncategorized offers

Set `ungroupedLabel` (for example, `Ohne Kategorie`) to show root leaves together
in a fixed visual group after real root containers. It appears only when there
are root leaves, starts expanded and can be collapsed. It has no edit/delete menu
and cannot be dragged. Its folder button toggles expansion.

The group is not a data node. Moves into it still emit `parentId: null` and real
root indices. Its local expansion state is separate from real category IDs.
Omit `ungroupedLabel` for a deliberately flat list without categories.

## Interaction and appearance

Rows share a height; indentation expresses hierarchy. A category's surface and
short handle click toggle expansion. Holding the handle for 300 ms starts drag.
The feedback uses the same row content. Insertion uses a straight line; dropping
inside a category highlights its full row. The menu also supports moving without
dragging. Destructive actions are last and separated from movement actions.

Typography, row insets, indentation, surfaces and motion use K tokens. Increased
text scale, density, theme and reduced-motion preferences remain effective.

## Gallery scope

Matching cases: categories, mobile, tablet, ungrouped, flat, deep and empty.
This revision is authorized for Storybook and Widgetbook; integration into the
Onzeit onboarding and administration screens is a separate step.

## Verification (2026-10-27)

- Web type checks and six model tests passed.
- Flutter: eight tree tests, nineteen menu regression tests and three gallery
  fixture tests passed, including 320 px and 900 px layouts at 150% text scale.
- Browser checks: virtual group collapse/expand, nested move, remove confirmation,
  and undo; light/dark gallery rendering. Visual-literal audit passed.
- Shared nested menus use the same surface in KMenuButton and KContextMenu.
- This verifies gallery implementations, not an installed Onzeit application.
