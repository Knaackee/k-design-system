# DataTable draft lifecycle

`KDataTableDraftController<T>` is optional, consumer-owned state for **new,
unsaved rows**. Instantiate it outside recycled cells and dispose it with its
owner. KTable stays presentational. No project names, persistence, actions or
form schema are built into the controller.

## Consumer contract

Provide `rowId`, `cloneRow`, `isEqual` and `onCommit(row, snapshot)`. The consumer
creates a complete default row and passes it to `begin`, with `initialColumnId`
and the current section's `originPath`. `cloneRow` must isolate mutable data and
preserve identity; `isEqual` defines domain equality, including nested values.
Use stable unique IDs through the entire save operation.

The controller exposes `get(id)`, `drafts`, `update`, `commit`, `cancel`, `leave`
and `retainInteraction`. Subscribe to changes on Web; listen to the
ChangeNotifier on Flutter. Render draft snapshots separately from committed
application rows. Apply `acceptedRow` to application data on the `committed`
event; the table does not fetch or persist data itself.

`onEvent` reports `started`, `changed`, `commitRequested`, `committed`, `cancelled`
and `error`, with `snapshot`, `reason` and an accepted row on success. Reasons
identify programmatic actions, Enter, Escape, row exit or explicit action buttons.
Snapshots carry the baseline, current row, stable ID, initial column, origin and
status: `pristine`, `dirty`, `saving` or `error`. Labels and error presentation
belong to the consumer.

## Saving and cancellation

The default save policy is `explicit`. A dirty draft survives focus changes and
row exit. Consumers map Enter or their own Save action to `commit`; a custom
editor or open dropdown handles its own Enter first. Optional `rowExit` policy
requests a save when a changed row is left. Leaving a pristine new draft cancels
it, using `isEqual` rather than focus alone to determine whether it changed.

`onCommit` may return synchronously or asynchronously. Returning an accepted row
ends the draft; rejection keeps values in `error` for retry. While saving,
mutation and cancellation are blocked and duplicate commit calls reuse the same
request. Disposing the controller suppresses stale completions; it does not
cancel a server operation. Applications must reconcile server state themselves.

Escape mapped to `cancel` discards a new unsaved draft even when dirty. It never
deletes a saved application row. A popup consumes Escape first. Existing-row
editing remains a separate consumer policy. Saving and cancellation are explicit
operations, not side effects of mounting or recycling a cell.

## Interaction ownership

Wrap a draft's cells with Web `KDataTableDraftInteraction`, or Flutter
`KDataTableDraftCellBoundary` sharing one `KDataTableDraftBoundary`. Keep the
controller and Flutter row boundary outside recycled cells. Same-row transfers
and an owned selection popup do not end the draft.

For an external portal or modal route, retain interaction before opening and
release it after value updates and focus restoration. `retainInteraction(id)`
returns an idempotent release callback. Date, Time and DateTime pickers expose
`onOpenChange(bool)` for this purpose; notifications are paired even if the picker
is removed. A lease vetoes row-exit cleanup while the overlay owns interaction;
releasing it does not replay a stale exit from when the modal first opened.

## Placement, filters and virtualization

Pass local draft projections through optional `KDataTable.draftRows`. Each entry
contains `row` and captured `originPath`. Drafts remain at the end of that leaf
section regardless of their edited grouping values, current sort or filters.
After successful save, remove the draft and let normal application data processing
place the accepted row. Active drafts cannot be silently hidden by collapsing
their containing group.

External windows additionally require `originIndex` and `originQueryRevision`.
The index is an insertion anchor in the server's logical entry sequence, including
groups and footers. It must be within the server count and match the active query.
Local drafts do not change server range indices or mutate server entries. On a
query change, the consumer must deliberately reconcile or temporarily detach
local draft projections while retaining controller state; an old anchor must not
silently bind to a new query.

## Actions and examples

No add action appears unless the consumer supplies its footer/action content.
Consumers supply labels, icons, callbacks, visibility, permissions and custom
cell editors. The gallery uses an optional Add Project action, empty title,
status inherited from the creation group, configurable save policy and explicit
Save/Cancel controls. These are example application choices, not package defaults.

## Verification and sources

Model tests cover defaults, mutable snapshots, value comparison, cancellation,
asynchronous errors, duplicate saves, disposal and leases. Placement tests cover
local grouping and external range mapping; interaction tests cover real pointer
and keyboard transfers, dropdown cancellation, grouping after save and pickers.
`pnpm verify` is the final integrated check, followed by the gallery browser and
geometry checks. Human visual acceptance remains separate; no 100,000-row
performance guarantee is implied.

The externally controlled state and event separation follow established patterns
in [KendoReact editing](https://www.telerik.com/kendo-react-ui/components/grid/editing)
and [MUI editing persistence](https://mui.com/x/react-data-grid/editing/persistence/).
The governing architecture remains [ADR 0004](../decisions/0004-virtualized-datatable-engines.md).
