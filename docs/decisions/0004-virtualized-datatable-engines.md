# ADR 0004 — Virtualized DataTable engines and cell contracts

Status: Proposed
Date: 2026-09-17

## Context

The accepted small-table slice has arbitrary cell renderers, nested groups and
controlled edits but eagerly renders all supplied rows on both platforms. The user
now requests TanStack Table on Web and a scalable Flutter design while retaining
the gallery appearance. Current code cannot substantiate a hundred-thousand-item
performance claim. New dependencies and external-data boundaries are material
architectural choices; this proposal does not change accepted token/layout ADRs.

## Proposed decision

Keep KTable presentational. Add an explicit bounded virtual KDataTable mode using
TanStack Table plus TanStack Virtual on Web and Flutter TableView.builder from
two_dimensional_scrollables. Keep upstream types private behind K-owned APIs.
Use stable logical entries for groups, rows and optional add-item footers, one
shared horizontal viewport and matching fixed extents based on density/text scale.
Existing content-height mode remains available for small/multiline tables.

Support local processing and a consumer-owned external window of display entries.
Query revision, total logical entry count and requested ranges are explicit;
networking, cancellation, caching and server aggregation remain in the application.
Virtualization bounds mounted UI, not the cost of sorting all local data. Consumer
edit state is keyed by row and column IDs and survives recycling. Invalid edits
keep their editor visible; an unmounted anchor cannot leave a detached popup.

Form cells are composition examples using existing controlled components and
KEditableCell, not a closed enum of hardcoded cell types. Add KCurrencyInput to
Forms as nullable exact signed minor units within Web safe-integer bounds, with
locale, currency code and fractionDigits. Locale parsing does not silently round
or convert currency. Read display, draft, commit and validation stay separate.

## Alternatives

- Continue eager rendering: smallest change, suitable for small tables, cannot
  satisfy the requested large-data rendering direction.
- Build custom virtualization on both platforms: complete control, but duplicates
  viewport, recycling and accessibility work that maintained engines provide.
- Use default native/material data grids: useful standard behavior, but their
  visuals, grouping and cell interaction contracts differ from the accepted design.
- Use TanStack Table alone: provides a row model but no built-in virtualization;
  it does not solve mounted DOM growth on its own.

## Consequences and confirmation

New dependencies and adapter code are required. Existing public small-table APIs
remain supported; new external/viewport types must not expose vendor types.
Fixed row extents constrain arbitrary multiline editors in virtual mode. Screen
reader semantics, spanning group/footer rows, focus recycling and active popup
placement are explicit implementation checks, not assumed engine guarantees.
A compatibility spike must prove those checks before broad migration. If TableView
cannot meet the group/footer or accessibility contract, report the evidence and
revise this proposal; do not silently substitute another engine.

Verify deterministic model parity, viewport-bounded mounted counts, external
revision races, draft/focus persistence, all form-cell interactions and gallery
geometry. Run pnpm verify and browser/parity checks. No large-volume benchmark is
required by the user; no unmeasured capacity/latency guarantee may be published.
Human approval of this proposal and its paired Plan is required before migration.

## Sources

- [TanStack virtualization](https://tanstack.com/table/latest/docs/framework/react/guide/virtualization)
- [Client/server processing](https://tanstack.com/table/latest/docs/guide/client-side-vs-server-side)
- [Flutter TableView](https://pub.dev/documentation/two_dimensional_scrollables/latest/two_dimensional_scrollables/TableView-class.html)
