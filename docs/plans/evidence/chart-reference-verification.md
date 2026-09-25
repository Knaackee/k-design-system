# Chart reference verification — 2026-09-25

## Scope and authority

Regular-mode implementation of `2026-09-25-chart-reference.md` and Decision 0009. Human approval: “Ja, ich gebe den Plan frei.” Approval does not imply acceptance, commit or push. Base commit: `dee4b9788ab4fe0ea5667dc5017e6f1d3f1fe122`; chart work is the uncommitted diff on top.

One `KLineChart` adapter per platform: published MIT packages `@tanstack/charts@0.18.0` and `fl_chart: 1.2.0`. Renderer models remain internal. Inputs own data, IDs, axes, formatters, labels, visibility, selection, state content and callbacks; shared semantic/component tokens own appearance. Candlestick and other chart families remain deferred.

## Verification evidence

- Web model tests cover gaps, invalid/out-of-domain points, distinct series at the same x, immutability and explicit numeric domains. A fixture parity test compares the canonical JSON with Widgetbook's bundled asset. Flutter cannot safely bundle a path containing `../..`; its local asset copy is deliberately checked against the canonical fixture.
- Flutter chart tests cover controlled selection/visibility/reset, keyboard arrows/Home/End/Escape, repeated-event deduplication, transient hover, outside dismissal, data table, hidden series, missing/negative values, 1000 points, long labels and plot geometry at 375/768/1280 across three densities. A Widgetbook test loads the actual fixture asset and opens its table.
- Browser: Web Home selects 1 Sep (42/35), Right selects 2 Sep (58/40), Escape clears; hiding both series displays the empty state, and showing them restores both paths. The table contains all 14 canonical rows. Flutter tap at the seventh sample displays 7 Sep (68/64). Light, Dark and Reference Light were opened and visually compared.
- Both engines use explicit axis domains, shared insets, linear interpolation and the same UTC fixture. Initial drawing is static; data updates use `motionFast` and respect reduced motion. Hover remains transient; selection is controlled.
- `pnpm verify` completed successfully before the asset-path correction; the final integrated rerun is recorded below when complete. Existing Flutter release warnings about Wasm and Cupertino font discovery are not chart errors; the JavaScript release build succeeded.

## Geometry and images

Screenshots and measurements are under `artifacts/chart-reference/`. `comparison-375.png` shows Web left and Flutter right; `overlay-375.png` superimposes the cropped views. These are inspection artifacts, not accepted golden baselines.

The Web DOM reports a standard-density plot offset of x=40.000004/y=68 relative to the chart, height=208. Flutter's render-object tests report x=40/y=68, height=208. Dense/spacious offsets are y=56/84 and heights=224/192 on both. The right inset is 16. The browser's effective 0.8px border at its device scale yields a 253.6px plot in the compact demo versus Flutter's 253px: below 1 logical pixel for this measured geometry. Text rasterization remains visibly different. This is not a claim of pixel identity across every device or state.

## Remaining validation and next action

The OnePlus is connected, but this Widgetbook checkout has no Android host. Native-device touch, platform screen-reader behavior and the complete platform screenshot matrix are not certified. Flutter browser screenshots cover the compact fixture; larger Flutter plot geometry is covered by tests, not a full screenshot matrix. Do not mark full Plan acceptance from the available evidence.

Next action: human visual review of the reference, then resolve the remaining native/visual verification before expanding chart families. No commit or push was performed for this slice.

## Final check result

Final `pnpm verify` exited 0: formatting, generated-file consistency, 61 tooling tests, style audit, Web build/typecheck, Flutter analysis, all Flutter tests (1 glass + 16 tokens + 336 UI + 48 Widgetbook), Storybook production build and Widgetbook JavaScript release build passed. The final Web adapter rebuild also exited 0 after the keyboard fallback refinement; its output preceded the successful Storybook production build. `git diff --check` and `skillset plan check` passed (three historical provenance warnings on unrelated older plans). Dev Widgetbook was restarted with the corrected bundled fixture and confirmed rendering in the browser. Native-device and full visual-matrix limitations above remain open.

This verification note is not a Plan lifecycle transition. The installed CLI refuses generic `doc update` under `docs/plans`, including this evidence note, so its result was recorded with native file editing; the approved Plan and lifecycle receipts were not modified.

## Data-table dialog follow-up

User approved the reference visually and requested the chart demos to open their data table in the existing modal. Both gallery fixtures now compose KDialog and KTable; the chart package API is unchanged. The fixture button is optional and its label/title can be supplied externally (also exposed as Storybook controls). Chart data, series labels, axis domains/ticks and tick formatters remain consumer inputs.

Browser checks: Web modal contains 14 data rows plus its header and closes with Escape. Flutter modal opens, scrolls through 14 September and dismisses on an outside click. The chart remains in place instead of growing an inline table. The Flutter fixture test checks row count, modal dismissal and preserved chart. Widgetbook dev server restarted to load the changed demo. The repository verification rerun is logged at the system temporary path chart-modal-verify.log.

Follow-up verification: pnpm verify exited 0, including all 401 Flutter tests, 61 tooling tests, Web build/typecheck, both gallery builds and Flutter analysis. No commit or push performed.
