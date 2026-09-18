# Table

`KTable` is a presentational table for Web and Flutter. It composes existing
controls without owning application data, sorting, filtering or selection.

## Contract

Both platforms take a required accessible `label`, `columns` and `rows`.
Columns have a stable unique `id`, a `header`, an optional fixed `width`,
`minWidth` (default 160), `flex` (default 1) and `align` (`start`, `center`, `end`).
Rows have a stable unique `id` and one cell per column. Web cells are React nodes;
Flutter cells are widgets. A row has no implicit click action. Cells keep their
own labels, callbacks and keyboard behavior.

A fixed width overrides minWidth and flex. Other columns first receive their
minimum width and share surplus parent width in proportion to flex. When every
column is fixed, the table retains the sum of those widths. Below the summed
minimum width, the table scrolls horizontally rather than hiding cells or
changing into cards. Flutter requires a bounded parent width.

Widths include cell padding. Padding uses control inline inset and control gap;
the minimum row height is control size + twice control gap + default border
width. Content can increase the row height. Text wraps, cells align vertically
in the middle, and numeric content can align to the logical end. Cell content
must respect its column constraints; a deliberately oversized custom child is
not automatically resized. No values or labels are translated by the table.

The header uses the subtle surface, muted body text and label weight. Body rows
use the canvas surface and body typography. Every row has a bottom divider.
Density, theme, type scale and text scale come from the existing token contract.
Web uses native table, column-header and cell semantics; Flutter uses native
Table semantics. Web makes a horizontally overflowing region keyboard-focusable.
This is not an ARIA interactive grid and does not add arrow-key cell navigation.

## Examples

```tsx
<KTable
  label="Projects"
  columns={[
    { id: "name", header: "Project", minWidth: 240, flex: 2 },
    { id: "budget", header: "Budget", width: 120, align: "end" },
  ]}
  rows={[{ id: "atlas", cells: ["Atlas website", "€12,000"] }]}
/>
```

```dart
KTable(
  label: 'Projects',
  columns: const [
    KTableColumn(id: 'name', header: Text('Project'), minWidth: 240, flex: 2),
    KTableColumn(id: 'budget', header: Text('Budget'), width: 120,
      align: KTableAlign.end),
  ],
  rows: const [
    KTableRow(id: 'atlas', cells: [Text('Atlas website'), Text('€12,000')]),
  ],
)
```

## Gallery and verification

Both galleries register `Data display / Table / table-basic` and `table-cells`.
The basic fixture demonstrates fixed and flexible tracks, end alignment and
wrapping. The cells fixture embeds existing Select and OverflowMenu components;
its local callbacks report changes without navigating or modifying application
data. There is no duplicate toolbar or filter implementation.

- `node --test tooling/table-layout.test.mjs`
- `flutter test test/table_test.dart` in the Flutter UI package
- `flutter test test/table_fixture_test.dart` in Widgetbook
- `node apps/storybook/src/table-browser.test.mjs` with KDS_PLAYWRIGHT_MODULE and
  KDS_PARITY_OUTPUT set, using the running Storybook on port 6006
- `pnpm verify`

## Deferred

KDataTable owns the next composed slice: sorting/filter controls, groups and
subgroups, selection, pagination and a compact narrow-width presentation.
KBottomNavigation is separate. Sticky headers, virtualization, column resizing,
row reordering and spreadsheet navigation are not implemented in KTable.
Physical-device screen-reader verification and human visual acceptance remain
separate from automated geometry and widget tests.
