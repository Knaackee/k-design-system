---
title: "Virtualized DataTable and composable form cells"
date: 2026-09-17
---

# Virtualized DataTable and composable form cells

## Outcome

Preserve the accepted appearance of KTable/KDataTable while making the large-data
pattern virtualized on Web and Flutter. All cell contents remain consumer-owned.
Add matching examples for checkbox, text, selection, date, time, datetime and
currency cells. KCurrencyInput belongs to Forms, not Primitives.

## Status and authorization

Draft for Human Plan Approval. The user requested a Regular plan for TanStack Table
on Web and a virtualized Flutter implementation on 2026-09-17. This authorizes
planning only. Existing Rapid menu/cursor corrections are a separate delivery.
No benchmark with hundreds of thousands of items was requested; make no throughput
or latency guarantee. Approval of this plan and its proposed ADR precedes work.

## Current evidence

Web KTable renders a native semantic table. KDataTable owns a small local
filter/group/sort model; neither package currently depends on TanStack Table.
Flutter KTable eagerly builds Table rows. Neither implementation is virtualized.
Both accept arbitrary ReactNode/Widget cell content. KEditableCell already exposes
controlled display/editor slots. Icons use the shared assets/icons/lucide source.
Keep that public composition capability and shared density/geometry contract.

## Scope and boundaries

Allowed paths: packages/web/ui, packages/flutter/k_design_ui, apps/storybook,
apps/widgetbook, tooling table tests, docs/components, and dependency manifests
and lockfiles required by this feature. Tokens and existing approved ADR/Plan
bodies remain unchanged. No Bullets application mutation, backend, export,
aggregation, spreadsheet navigation, column resizing/reordering or app bar work.

## Proposed implementation

1. Preserve simple KTable as the presentational, nonvirtualized primitive.
   Introduce an explicit virtual viewport mode on KDataTable with a bounded
   height supplied by the consumer. Keep the existing content-height mode for
   small tables and migration compatibility. Do not infer mode from device type.
2. Use TanStack Table internally for the Web row model and TanStack Virtual for
   viewport rendering. Pin compatible stable package versions during implementation.
   Public contracts expose K types, not upstream library types. Preserve existing
   comparator, insertion-order group, full-path key and filter-before-group rules
   with contract tests; adapt upstream behavior rather than silently changing them.
3. Use Flutter TableView.builder from two_dimensional_scrollables behind the same
   conceptual contract. Render only visible rows/cells plus bounded overscan.
   Flatten expanded groups into stable display entries (group, item, footer).
   Group headings and add rows span columns. A single horizontal/vertical viewport
   replaces independent scrolling of leaf groups in virtual mode on both platforms.
4. Provide local and externally processed data modes. Local mode runs filter,
   grouping and sorting on supplied rows. External mode takes an explicit ordered
   display-entry window, total entry count, query revision and range-request
   callback; the consumer owns fetching, cancellation and caching. Entries have
   stable IDs, kind, depth and group path. Unknown unloaded entries render inert
   placeholders, never editable fake rows. Older query revisions cannot replace
   current windows. Group counts come from the consumer in external mode.
5. Keep sorting/filter controls outside the headerless pattern. Maintain stable
   focus/edit identities by row ID + column ID, never viewport index. Store drafts
   outside recycled cell instances. Before an active row leaves the viewport,
   request consumer commit; validation failure keeps the editor visible. Escape
   cancels. Scrolling closes popups when their anchor disappears. Pointer-outside
   behavior must remain consistent, including menu selection inside an editor.
6. For virtual mode, use a documented uniform item height derived from density and
   text scale, optionally overridden by the consumer. Group/footer extents are
   explicit. Single-line read displays truncate visually with an accessible full
   value. Custom multiline content uses content-height mode until variable-height
   parity is separately designed. Keyboard focus can scroll an offscreen item into
   view; semantic row counts/indices represent the logical data, not mounted count.
7. Demonstrate compact read displays and click/keyboard activation with existing
   KInput, KSelect/KCombobox and date/time/datetime pickers. Checkbox cells toggle
   directly on activation; they need no artificial text edit mode. Display slots
   must not nest interactive widgets inside the KEditableCell trigger. Editable,
   disabled and read-only states, empty values, validation and accessible labels
   are controlled by consumers. Reuse existing locale/format/time-zone parameters.
8. Add KCurrencyInput to Forms with the same controlled value/callback, disabled,
   read-only, label and validation conventions as other inputs. Use nullable
   signed integer minor units (safe-integer range shared with Web), explicit
   currency code, locale and fractionDigits (default 2, caller overrides for
   currencies such as JPY). Separate localized display and draft text; never do
   binary-floating-point money arithmetic or exchange conversion. Reject excess
   fractional digits rather than rounding silently. Currency changes do not
   convert amounts. Test negative, zero, empty and incomplete drafts and paste.
   Currency cell read mode formats the amount; activation opens KCurrencyInput.

## Acceptance and verification

- Match fixture IDs and categories on both galleries, with read/edit examples for
  every included form cell, local grouping and external-window loading states.
- Preserve existing sorts, nested collapse, indentation, icon action, optional
  footers and custom cell renderers through the engine migration.
- Test viewport recycling with a moderate synthetic dataset: mounted row/cell
  counts bounded by viewport + overscan, scroll to later IDs, edits survive
  recycling, no stale query results, collapse while editing, and empty/loading/error.
  This is a structural correctness check, not a 100,000-item performance claim.
- Keyboard/screen-reader smoke checks: labels, logical row indices/counts, tab
  into/out of editors, Escape, focus after scrolling, popup clipping/position.
- Geometry comparison at 375/700/1024, Dense/Standard/Spacious, light/dark and
  100/200 percent text size. Compare row tracks, group indentation, active inputs
  and popup anchoring within 0.5 logical px where measurable; review screenshots
  for font rasterization and native interaction differences.
- Targeted Web browser/model tests and Flutter widget tests during work; run
  pnpm install and dart pub get after manifest changes, then final pnpm verify
  plus the updated gallery interaction and parity scripts on the integrated build.
- Native touch/assistive technology checks require an available device/emulator;
  document unavailable coverage. Do not claim production-scale performance from
  browser geometry or unit tests. Human visual acceptance follows verification.

## Decision bundle and sources

Approve together with the proposed ADR 'Virtualized DataTable engines and cell
contracts'. Its alternatives cover eager rendering, custom virtualization and
platform-native default grids. No accepted ADR is superseded.

- [TanStack virtualization](https://tanstack.com/table/latest/docs/framework/react/guide/virtualization)
- [Client/server processing](https://tanstack.com/table/latest/docs/guide/client-side-vs-server-side)
- [Flutter TableView](https://pub.dev/documentation/two_dimensional_scrollables/latest/two_dimensional_scrollables/TableView-class.html)
