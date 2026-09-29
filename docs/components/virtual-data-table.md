# Virtual DataTable

KDataTable keeps its existing content-height mode. Pass viewport.height to opt in
to a bounded, virtualized table. KTable remains the small semantic table primitive.
Web uses TanStack Table 9.2.4 for its row model and TanStack Virtual 3.14.13 for
rendering. Flutter uses two_dimensional_scrollables 0.5.4 and a private
RenderTableViewport adapter to group cells into accessible semantic rows. The
adapter retains the upstream two-dimensional lazy layout engine; TableView.builder
alone does not provide the required semantic row parents. No vendor types leak
through the package API.

## Configuration

KDataTableViewport accepts height, rowHeight, groupHeight, footerHeight, overscan
and maxGroupDepth. Heights default to the shared density and text-scale geometry.
Virtual cells use single-line content; multiline layouts can use content-height
mode. Local groups infer a reserved indentation gutter from the whole model.
For external windows, specify maxGroupDepth when supplying nested groups so the
column tracks stay stable when a different window arrives. Group/footer entries
span columns. Virtual mode has one shared horizontal and vertical viewport.

The existing columns, cell renderer, rowId, sorting, filtering, group paths,
collapse state, toolbar and optional footer remain consumer-controlled. Configure
column widths and padding through the same KDataTableColumn API. Headers stay
hidden by default; showHeader=true enables the controlled, sortable header
specified in [DataTable headers](data-table-headers.md). Its horizontal position
follows the data viewport; it does not consume an external data index or reduce
the configured body height. Empty data retains the existing empty presentation.
On Web logical row counts/indices include the visible header for ARIA only;
Flutter exposes logical row identifiers/count plus table/row/cell semantics.
Native screen-reader traversal still requires device-level acceptance.

## External data

Pass rows:[], an externalWindow, queryRevision and onRangeRequest. A window has
queryRevision, totalCount (logical display entries), startIndex and entries.
Ranges have startIndex inclusive and endIndex exclusive. The caller owns fetching,
cancellation, caching and errors; supply the loading/error slots for presentation.
An empty initial window renders inert placeholders and requests the visible range.
A result with another revision is ignored. Keep totalCount and group counts in
sync with the server query; they describe groups and footers as well as data rows.

KDataTableEntry variants are item (id,row,depth,path), group
(id,label,count,groupKey,depth,path) and footer (id,rows,depth,path). IDs must be
stable and unique. External entries are already filtered, sorted and grouped;
the package never reprocesses only the loaded subset as if it were the full data.
The gallery simulates loading, error recovery and obsolete responses without a
backend. This contract enables large datasets; it does not guarantee a measured
capacity or latency. No hundred-thousand-row benchmark was performed.

## Editors and focus

Keep drafts in application state keyed by row ID and column ID, outside recycled
cell widgets. activeCell identifies the edited cell. onBeforeActiveCellExit asks
the caller to commit before scrolling/collapsing it away; returning false keeps
an invalid editor visible. Without this callback an active editor is retained.
focusCell requests scrolling/focus for a known local/loaded identity. External
navigation to an unloaded ID requires the application to resolve/load its range.

Cell content remains arbitrary ReactNode/Widget content. The form-cell gallery
shows KInput, KCheckbox, inline KSelect/KCombobox, date/time/datetime pickers and
KCurrencyInput. Checkbox cells toggle directly. Pickers accept presentation:inline
(Web) / KPickerPresentation.inline (Flutter): compact value at rest, first-click
modal action, existing keyboard and format/time-zone behavior. KEditableCell
composes custom display/editor states; it does not own persistence. Read displays
must not contain interactive descendants inside their activation button.

The exit guard covers viewport scrolling and built-in collapse actions. Before
replacing rows, filters or queryRevision independently, the consumer must run the
same commit/validation transaction. An application can otherwise remove its own
active row outside the viewport's control. Range requests wait for the active edit
to commit before asking for another external window.

## Evidence commands

Run pnpm verify after integrated changes, then the Storybook scripts
`data-table-browser.test.mjs`, `data-table-virtual-browser.test.mjs`,
`data-table-cells-browser.test.mjs`, `selection-overlay-browser.test.mjs` and
cross-platform geometry scripts with KDS_PLAYWRIGHT_MODULE pointing to Playwright.
Flutter virtual tests cover bounded building, merged groups/footer, semantics,
stale external windows and active-editor scrolling. The two galleries expose
matching data-table-virtual, data-table-external and data-table-cells fixtures.
