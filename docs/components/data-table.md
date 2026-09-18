# DataTable

KDataTable composes KTable with controlled sorting, filtering and nested groups.
The accepted pattern has **no visible column headers**. Applications place sort
and filter controls in the toolbar slot; the gallery reuses KFilterBar,
KSearchField, KSelect and KMenuButton. The simple KTable retains its headers.

## Contract

Both platforms accept rows, a stable rowId function, columns, an accessible
label, an empty widget/node and an optional toolbar. Each column specifies id,
label, cell renderer, optional comparator and the same fixed/flexible track
settings as KTable. Column labels remain available to assistive technology.
Cells can compose existing inputs, selectors and menus.

Sort is null or a columnId plus ascending/descending direction. The consumer
owns that state and its controls. A comparator is required for the chosen
column. Comparators must implement a consistent ordering; Web rejects nonfinite
results. Equal values preserve input order. Input collections are never mutated.

An optional filter predicate applies before grouping and sorting. Applications
own search syntax, domain values, fetching and remote query execution. The
example combines a title/owner search and status filter. Reset clears these
filters without changing row edits, sorting or collapsed groups.

Groups are an ordered list of definitions with stable id, a value function and
an optional value-to-label function. Group order follows first appearance in
filtered input. Sorting affects leaf rows only. Counts include all filtered
rows below that group, including collapsed descendants. Nested groups have
independent controlled expansion state. Keys are JSON arrays of [group id,
value] pairs along the full path, preventing collisions between equal subgroup
names. onCollapsedGroupsChange (Web) / onCollapsedGroupsChanged (Flutter)
returns a new set; the caller passes it back as collapsedGroups. Without a
callback, headings are noninteractive and the supplied state is still respected.

### Optional section footer

Web renderFooter and Flutter footerBuilder receive a KDataTableSection with
visible sorted rows and the full path of KDataTableGroupValue entries (id, raw
value, display label). The consumer returns arbitrary content and owns every
callback, label, creation rule and persistence operation. No footer is rendered
when the builder is omitted.

The footer appears after the last row of each visible leaf group, at the same
indentation as those rows. Collapsed groups hide it. For an empty result it is
called once with empty rows/path, allowing creation of a first item without
inventing missing groups. A footer must not be interpreted as a data row by
sorting, filtering or selection code.

The gallery creates provisional projects with an empty title and inherited group
status/platform. Consumer code snapshots all default values, chooses the initial
cell by row and column identity, and supplies a focused editor through
KEditableCell. The example exposes its add label, default-row factory and initial
column choice; these are gallery configuration, not project-specific library APIs.
Custom consumers can compose any editable cell and its focus behavior.

Escape in the title or leaving the entire new row removes it when every value still matches
the default snapshot. Changed new drafts are retained, including on Escape;
Escape on an existing row continues to cancel that edit. The example accepts a
changed draft locally, while applications own validation and persistence.
Moving between cells or interacting with a cell-owned popup keeps the row provisional.
Provisional rows bypass the example filter until the row is left so a search
cannot hide the editor immediately. Once accepted, normal filtering applies.

### Pointer and focus behavior

Clicking or tapping outside an editor releases its focus without restoring the
cell trigger. The supplied editor decides whether focus loss commits or cancels;
the gallery commits. Enter/Escape can return focus to the display trigger, while
an explicitly clicked external control keeps its focus and action.

KSelect is select-only: pointer cursor, no caret and no selectable input text.
KCombobox remains editable, with text cursor and selection for its search query.

## Appearance and accessibility

Group headings use existing ghost buttons, chevrons and density spacing.
Each child level, including its data rows, indents by the control inline inset.
The optional groupIndent property overrides that step in logical pixels on both
platforms; zero disables indentation. Values must be finite and nonnegative.
Headings at depth zero remain flush; a leaf at depth two receives two steps.
The available table viewport shrinks by the indentation and keeps overflowing
columns inside its horizontal scroll area. Grouped views currently have
independent leaf scroll positions. There is no platform-dependent switch to cards.

Cell content remains entirely consumer-defined through the column cell renderer.
The reusable KEditableCell accepts display, editor, editing, label and onEdit;
it owns no value, draft or persistence. Omitting onEdit gives read-only display.
The consumer supplies focus, validation and commit/cancel behavior in its editor.
The trigger supports pointer and keyboard activation and restores focus after
editor removal without intentionally taking focus from another control.
The display slot must not contain nested interactive controls.

The example shows a 48-pixel leading KIconButton column with an independent
callback and live action feedback. Titles start as single-line text and enter a
KInput editor on activation. The example commits on Enter or focus loss and
cancels on Escape; drafts do not reorder/filter rows before commit. Stable row
IDs preserve identity. Icon, column width, display/editor content, accessible
labels, validation, read-only/disabled state and persistence remain application
choices. Flutter editors retain/dispose their controllers and focus nodes.

KSelect and KCombobox accept presentation=inline (Flutter:
KSelectPresentation.inline). The resting control has a transparent surface and
border and hides its chevron. Focus/open state uses the normal control styling;
padding and hit geometry remain stable. Option icons, images and callbacks keep
the existing API. Standard presentation is unchanged. The example uses inline
status cells that open the existing selection popup on the first activation.

Web retains visually hidden native column headers. Flutter omits the visual
header row and labels each semantic cell with its column label. Both retain
native table/row/cell roles. Group buttons expose expanded state and support
keyboard activation. Consumers supply their own localized labels; KDataTable
contains no application-specific messages. Native-device accessibility review
remains separate from the automated checks.

Column width and paddingInline are independently configurable. The icon column
uses width=48 and paddingInline=0, preserving the button hit target without
extra table padding. Omitted paddingInline uses the theme control inline inset;
explicit values must be finite and nonnegative.

KDataTable hides row dividers by default; showRowDividers=true enables them.
KTable keeps its visible dividers by default. Hiding divider paint retains its
reserved geometry, so switching the property does not shift row positions.

## Verification and review

Matching fixtures: Patterns / DataTable / data-table-rows and data-table-groups.
They use six fictional projects, editable status cells, title/budget sort actions,
combined filters, an empty result and nested status/platform groups.

- node --test tooling/data-table-model.test.mjs
- flutter test test/data_table_test.dart test/table_test.dart (Flutter UI)
- flutter test test/data_table_fixture_test.dart (Widgetbook)
- node apps/storybook/src/data-table-browser.test.mjs
- node apps/storybook/src/data-table-parity.test.mjs
- pnpm verify

Browser scripts use KDS_PLAYWRIGHT_MODULE, and parity captures also require
KDS_PARITY_OUTPUT. Both gallery services must run on ports 6006 and 6007.

The optional virtual viewport, external data windows and loading/error slots
are documented in [Virtual DataTable](virtual-data-table.md). Without a viewport,
the original content-height table remains available. Selection, sticky columns,
resizing, persisted views and floating mobile navigation remain separate work.
Human visual acceptance is required after automated verification.
