# Gantt Web reference verification

## Scope and approval

User approved `docs/plans/2026-09-25-gantt-web-reference.md` with
"Ja, ich gebe den Plan frei." on 2026-09-25. The Plan is in progress;
visual Human Acceptance remains pending. No Flutter files, public package
exports, production renderer decision, commit or push are part of this slice.

## Implementation

- Pinned gallery dependency `@svar-ui/react-gantt@2.7.3`. Inspected the npm
  archive's actual MIT license before installation; transitive versions remain
  locked by pnpm.
- SVAR renders the hierarchical table, task bars, progress, milestones,
  dependency arrows and synchronized scrolling. Existing design tokens project
  into SVAR CSS variables. Existing K controls provide navigation and details.
- Native SVAR mutation gestures are disabled with the public `readonly` option.
  The adapter uses pointer capture and a temporary DOM ghost, preserving
  canonical records until the consumer accepts a proposal. This avoids relying
  on SVAR's differing 300 ms bar and 500 ms row touch delays. No renderer fork
  or private store writes are used.
- Compact portrait uses the public chart/grid display modes, exposed as
  Timeline/Tasks buttons. SVAR otherwise replaces the chart with its table at
  narrow widths. Desktop retains the side-by-side resizable table.
- Compact mouse and touch gestures share a 500 ms hold, scroll-before-hold,
  short tap for details, 44 px resize targets, Escape/cancel and drop cleanup.
- Date-only half-open ranges, immutable proposals and duration-weighted summary
  progress are external to the renderer. Locale, column definitions, labels,
  records, selection, expansion and callbacks are adapter inputs.

## Verified behavior

- Actual desktop browser drag moved Research from September 21 to September 23.
  The status showed the corresponding date range. Right resize increased its
  last included day from September 25 to September 26; left resize changed its
  start from September 23 to September 22.
- A subsequent drag with demo rejection enabled retained its original geometry
  and emitted the declined status. Further accepted resize still worked.
- At 375 px, dragging before activation scrolled the axis without a proposal;
  a short tap opened the existing KDialog with the original dates/progress.
- The Tasks switch and Design group collapse removed its children from the
  visible rows and corresponding chart. The chart container remains bounded
  and its content scrolls independently.
- Screenshots in `artifacts/gantt-reference`: compact dark standard, compact
  light spacious (425 x 550), and desktop dark dense. These cover both themes
  and all densities, not every Cartesian combination.

## Commands and limitations

- `pnpm --filter @k-design-system/storybook add --save-exact @svar-ui/react-gantt@2.7.3`: passed.
- Focused strict TypeScript check of `apps/storybook/src/gantt.stories.tsx`: passed.
- `node --test tooling/gantt-model.test.mjs tooling/gantt-gestures.test.mjs`:
  20 tests passed, including signed resizing, minimum duration, DST, short tap,
  mouse/touch hold, panning, cancellation, read-only, and repeat after rejection.
- `pnpm test:tooling`: 96 passed on the final integrated state.
- `pnpm generate:check`, `pnpm audit:styles`, `pnpm build:web`,
  `pnpm typecheck:web`: passed.
- `pnpm build:storybook`: passed; final build log is
  `%TEMP%/gantt-storybook-final.log`.
- `pnpm verify`: blocked at formatting by the approved immutable Gantt and
  Timeline Plan documents. Their bytes were preserved. This is not a clean
  full verification result; `%TEMP%/gantt-verify.log` records the failure.
- Browser tooling cannot hold a pointer indefinitely. Long-press timing is
  tested using deterministic pointer-event tests, not claimed as a native-phone
  visual check. Native Flutter is intentionally deferred.
- SVAR emits a development React missing-key warning from an internal render
  component (`Lt`). No package fork or warning suppression was introduced.
- The accessibility adapter corrects the renderer's grid/treegrid role and
  zero-based ARIA row indices, hides the inactive compact grid, and makes chart
  scrolling/task detail activation keyboard accessible. Storybook's final
  compact chart scan reports zero violations (one inconclusive); the compact
  task-table scan reports zero violations and zero inconclusive findings.
- Compact mode is width-based rather than requiring a portrait aspect ratio:
  Storybook's addon panel reduces iframe height independently of its requested
  viewport height. This also keeps narrow landscape embeds usable.
- Dependency authoring, automatic scheduling and PRO features are excluded.
  Full keyboard/screen-reader certification and a complete theme/size matrix
  remain production gates; accessible detail fields offer a drag alternative.

## Next action

### Component-only demo follow-up

- At the user's request, removed the Gantt Timeline/Tasks switch, visible task
  table, and period/scale toolbars from both Web reference demos. Demo headings,
  footers and check panels are removed; click-to-open detail dialogs remain.
- Gantt defaults to chart-only, with display mode, scale and dates supplied
  externally. Existing component data/callback and token inputs are retained.
- Confirmed both 425 px dark previews in the browser, including a fresh Gantt
  reload. Strict TypeScript checks for both stories and 25 Gantt tests passed.
- These references still live in Storybook under the approved reference scope;
  this change does not claim a production package export or Flutter update.

### Mobile scrolling follow-up

- Chart-only mode now reduces the unused four-pixel grid splitter to the
  existing border-width token and hides its unused expand affordance.
- Pointer panning now starts on empty chart areas and the time scale as well
  as on inactive bars. Mouse and touch use the same path; native controls and
  scrollbars remain outside this gesture handler.
- In the live 425 px Storybook view, dragging empty space moved the scale
  from x=18.01 to x=-133.99; a vertical drag moved the chart area from
  y=281.60 to y=162.40 without submitting a task edit.
- Focused model/gesture suite: 25/25 passed, including empty plot/scale mouse
  and touch cases and native-control exclusion. Strict story TypeScript check
  passed. Native finger behavior remains covered by pointer tests rather than
  a physical-device test. The previously recorded full-suite limitation remains.

User visual review of Storybook `data-display-gantt--reference`, especially
long-press activation and resize handles. Address feedback before a Flutter port.
