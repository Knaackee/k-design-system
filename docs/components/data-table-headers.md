# DataTable headers

Rapid slice authorized on 2026-09-29: extend existing KTable/KDataTable in Web
and Flutter, demonstrate in both galleries, then wait for human visual acceptance
before migrating Assetry. No new dependency, token or separate table component.

## Contract

- KDataTable `showHeader` defaults to false. KTable keeps its existing true default.
- A comparator and `onSortChange` (Web) / `onSortChanged` (Flutter) make a column
  interactive. Consumer-owned `sort` remains the source of truth.
- Repeated activation cycles ascending, descending, original order. Switching
  columns starts ascending. Equal values retain stable order.
- Columns without a comparator show plain labels. A controlled sort without a
  callback remains read-only, including its direction indicator.
- Existing KButton and arrow icons provide pointer/keyboard interaction.
  Active editors can veto sorting through the existing exit callback.
- Groups repeat headers in each existing leaf table. Single-column lists retain
  their headerless presentation. Empty datasets retain their empty presentation.
- Virtual headers follow horizontal scrolling above the body viewport. External
  range indexes and configured body height do not change. External consumers
  must update their query revision/window in response to a sort request.
- Web announces direction through aria-sort; Flutter uses its semantic value.
  Native screen-reader acceptance is still a separate human check.

## Scope and verification

Allowed paths: existing Web/Flutter table components, their gallery fixtures,
targeted tests and this documentation. Existing primitives, tokens, comparators
and table layout calculations are reused. Assetry integration is deferred.

Matching fixture IDs:

- `data-table-headers`
- `data-table-grouped-headers`
- `data-table-virtual-headers`

Checks: dependency resolution without upgrades; Web model sort-cycle regression;
Flutter header/editor/virtual regressions; Codex-browser sort interaction in both
galleries and Web grouped/virtual alignment; integrated `pnpm verify`.

Human visual acceptance, commit/push and consumer migration remain pending.
Verified 2026-09-29: pnpm install --frozen-lockfile and dart pub get succeeded;
Web sort-cycle regression passed (5 model tests), Flutter header tests passed (8),
and integrated pnpm verify exited 0. Documentation formatting was checked again
after the final documentation edits; git diff --check passed.

Codex Browser confirmed Web ascending/descending/original ordering by keyboard,
shared grouped header state and virtual horizontal alignment; Flutter header
activation reordered the rendered rows. Screenshots are retained in the consumer
workspace at tmp/table-headers/storybook.png and tmp/table-headers/widgetbook.png.
These are smoke checks, not a pixel-diff or native-screen-reader acceptance.

Alignment correction (2026-09-29, approved Rapid follow-up): sortable start-aligned
headers place the arrow after the label; end-aligned headers place it before the
label. Flutter KButton now supports an optional trailing widget alongside leading.
Editable cells inherit the column text alignment in both regular and virtual
layouts. A column may set headerContentInset to account for padding inside its
consumer-rendered controls (CSS length on Web, logical pixels in Flutter).
The gallery uses this for editable title/budget cells and the inline status select.

The Widgetbook regression checks the actual title left edge and budget right edge
against their headers with a one-pixel tolerance, and checks the trailing icon.
Both corrected gallery views were visually inspected in Codex Browser.

Alignment follow-up verification: integrated pnpm verify exited 0 on 2026-09-29.
The final Web DOM measurement found identical project-header/title left edges and
identical budget-header/value right edges. Updated screenshots are
`tmp/table-headers/storybook-aligned.png` and `tmp/table-headers/widgetbook-aligned.png`
in the consumer workspace. Visual acceptance remains pending.

### Text overflow follow-up — 29 September 2026

The user approved single-line headers and text cells, full-text disclosure, intact
important values/actions, and explicitly configurable multiline columns. Rapid
scope: existing Web/Flutter tables and buttons, internal overflow helpers,
matching gallery fixture and focused tests; no token changes or host migration.

KTable and KDataTable columns expose overflow: ellipsis (default), wrap or visible.
Headers always remain single-line. Sort icons, leading/trailing button icons and
loading indicators do not shrink. Buttons keep their full accessible names while
the visible label truncates. Clipped content is revealed on hover and keyboard
focus; Flutter also supports long press. Escape dismisses the Web disclosure.

Consumers must allocate suitable widths and use visible for complete amounts,
status and action cells. The overflow policy does not infer semantics from text.
Custom Flutter cell widgets retain their own controls and disclosure behavior;
automatic measured disclosure covers Text cells and header/button labels. Web
keeps original React content and interactions. Fixed-height virtual rows remain
single-line even when wrap is requested; use nonvirtual KTable for multiline
content. Visible values still require sufficient column width in both modes.

Matching fixture: data-table-overflow. Covers a long header/name, amount, action
button and explicit multiline description. Storybook play checks real clipping,
CSS ellipsis, keyboard disclosure, unchanged accessible button name, Escape and
sorting. Flutter regressions cover layout, tooltip focus/hover/touch, button
activation and retained icons/loading. Full integrated verification and visual
review are recorded below after completion. Assetry adoption, commit and push
remain pending.
