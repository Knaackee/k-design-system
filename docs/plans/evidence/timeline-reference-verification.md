# Timeline reference: candidate preflight

Date: 2026-09-25. Regular mode. The user approved the exact reference Plan with
"ja freigabe erteilt". Approval and implementation-start receipts are recorded
by the Plan CLI. The approved Plan body is unchanged.

## Initial preflight outcome

The renderer source preflight found a blocking mismatch in flutter_gantt 1.2.2
before adding it to either gallery. This is not a completed Timeline component
or a visual-parity claim. No production or gallery source/dependencies changed.
Existing uncommitted chart work remains intact.

## Web candidate

vis-timeline 8.5.4 was downloaded into a temporary inspection directory. Its
package and shipped license files offer Apache-2.0 OR MIT. In the distributed
esnext/esm/vis-timeline-graph2d.js, onMoving changes temporary item data and
onMove accepts data or rejects with callback(null), restoring the initial data.
These permit a separate renderer dataset and canonical consumer records.

The source provides range resize, custom snapping, groups and per-item
editable=false. Escape/interrupted-gesture cancellation and accessible editing
require adapter work. No browser behavior or visual equivalence was verified.

## Flutter candidate

The exact pub.dev archive for flutter_gantt 1.2.2 has SHA256
7a5147e40cb9e898f63ac27dbf1601e82c2b9bde620f960ad622269c87869b62.
The shipped LICENSE is BSD-3-Clause, despite its README saying MIT.

Source findings:

- lib/src/widgets/row.dart keeps daysDelta across drag start/end; only the
  pointer offsets are reset. A second gesture can emit a stale proposal.
- The same file wraps the custom cell builder with its own draggable and two
  handles. Handles are hardcoded to width 4 and translucent white, without a
  public handle-builder or hit-target option.
- Movement is horizontal. There is no group-change proposal in the callback;
  the callback contains only the activity and optional start/end dates.
- enableDraggable is controller-wide. GanttActivity has no per-item editable
  property. Date limits are not equivalent to a complete read-only contract.
- Date ranges are inclusive, requiring translation from our half-open records.

## Reproduction

The standalone probe is preserved at
artifacts/timeline-reference/flutter-probe. It is deliberately not a dependency
of the design-system workspace. Copy it to a temporary directory, then run
`flutter pub get` and `flutter test --reporter expanded` there.

The test mounts the package's actual GanttActivityRow and invokes its registered
drag callbacks. First propose a one-day move, leave canonical data unchanged
(consumer rejects), then start/end a second drag without an update. Expected:
one proposal total. Actual: two. Final test exit code: 1, the intended reproduced
upstream behavioral failure. This is a callback-level widget probe, not a
physical-pointer or native-device test.

Two initial probe harness errors were corrected before reaching this result:
DraggableDetails is not const; package dates are UTC-normalized, so date-only
assertions now compare year/month/day. Neither was an upstream defect.

## Recommendation at preflight

The accepted Plan explicitly requires a revised decision if a candidate fails.
Recommendation: retain vis-timeline for Web evaluation and evaluate a native
Flutter timeline surface composed from existing scroll/layout primitives, with
owned hit-testing, previews and controlled proposals. This requires additional
scope approval and an architecture proposal; it is not implemented here.

A maintained fork of flutter_gantt is an alternative, but would need changes
to interaction state, hit targets, permission handling and group movement.
Merely changing theme values cannot meet the agreed behavior.

## Initial verification boundary

Plan CLI check: zero errors, existing legacy-provenance warnings. The isolated
Flutter probe reproduces the failure. Gallery screenshot matrix, 500-item
performance measurements and integrated pnpm verify have not been run for this
unfinished slice. Native Android remains unavailable without a host. No
readiness, Human Acceptance, commit or push is claimed.

## Web-first continuation

The user accepted the revised direction and explicitly requested a visible Web
Timeline first, before further Flutter implementation. The reference is now at
Storybook `data-display-timeline--reference`. This is a gallery prototype, not a
published component API or a completed cross-platform Timeline/Gantt slice.

Changed paths: apps/storybook/package.json, pnpm-lock.yaml,
apps/storybook/src/timeline.stories.tsx, apps/storybook/src/timeline/,
fixtures/timeline-reference.json and tooling/timeline-reference.test.mjs.
vis-timeline 8.5.4 is pinned in the gallery only. Existing chart work is preserved.

The gallery composes existing buttons, surface, dialog, inputs and select with
a token-styled renderer. React owns accepted data; renderer writes are rejected
and proposals go through the controlled immutable model. Twelve records cover
three groups, overlapping ranges, a point milestone and a read-only range.

Browser evidence on 2026-09-25:

- Research dragged from Sep 21–24 to Sep 23–26 (inclusive display dates).
- Its right handle extended the end to Sep 27; the detail dialog showed
  start 2026-09-23 and last day included 2026-09-27.
- The demo's decline option rejected a detail-edit save with explicit feedback.
- A blank-on-reload issue was reproduced: vis kept its root visibility hidden
  until its delayed initial-range lifecycle completed. One initial range-event
  redraw fixes it; subsequent desktop and compact reloads rendered correctly.
- Compact 375px initially crowded day labels. Responsive tick spacing now
  measures available width; snapping remains daily independently of axis ticks.
- Screenshots: artifacts/timeline-reference/web-compact.png and web-desktop.png.

Checks: four Timeline model/fixture tests pass; targeted strict TypeScript and
new-source Prettier checks pass. The verification steps generate:check,
test:tooling, audit:styles, build:web, typecheck:web, analyze:flutter,
test:flutter, build:storybook and build:widgetbook passed before the final
adapter polish. The affected Storybook build is repeated after that polish.
Widgetbook's normal Web build succeeds with existing Wasm dry-run/font warnings.

The top-level pnpm verify remains blocked by Prettier formatting of the already
approved Plan. Its immutable bytes have deliberately not been rewritten.
Logs are in the system temp directory: timeline-web-verify.log,
timeline-web-remaining-checks.log and timeline-web-final-build.log.

Not claimed: complete gesture/keyboard/device matrix, interrupted-pointer
coverage, 500-item performance measurements, native Android verification,
Flutter parity, Gantt readiness, Human Acceptance, commit or push. Next action:
user visually evaluates the Web reference before the next implementation slice.

## Mobile interaction follow-up

User requested calendar-equivalent mobile editing. The Web gallery adapter now
uses the same compact-portrait boundary (width below 600px and portrait) and a
500ms hold. Short taps invoke optional onItemOpen; the demo opens its existing
detail dialog. Movement before the hold cancels activation and preserves panning.
The editing selection is separate from consumer selection and ends after drop,
Escape, pointer cancellation or an outside pointer press. Desktop selection is
unchanged. Touch resize targets are 44px, with centered visible grips.

Five model/interaction tests pass, including tap vs hold, panning cancellation,
read-only behavior, drop dismissal and switching back to desktop. Strict targeted
TypeScript, source formatting and Storybook build pass. The known immutable Plan
formatting issue still blocks top-level pnpm verify. The actual short tap and
absence of premature handles were verified at 375px in the Codex browser.
The browser tool cannot hold a pointer; actual long-press/drag verification is
pending user-assisted inspection. No native touch-device parity is claimed.

User reported misplaced active handles. Source diagnosis found vis-timeline's
max-width:20% still capped the target despite its 44px width. Removing that cap
in the mobile override restores the shared center calculation for both grips.
This final CSS correction passes formatting; active visual measurement is pending.

## Flutter reference implementation

The user accepted the Web interaction refinement ("Okay, das können wir erstmal
so lassen") and authorized the Flutter port on 2026-09-25. This continues the
reference-gallery slice; production exports and the Gantt component remain out
of scope. The native Flutter canvas uses no flutter_gantt dependency.

Files: apps/widgetbook/lib/timeline_fixture.dart, lib/timeline/{timeline_model,
timeline_canvas,timeline_painter}.dart, test/timeline_{model,canvas}_test.dart,
fixtures/timeline-reference.json, main.dart registration and pubspec asset.
The fixture copy matches the shared twelve-record reference. Consumer-owned
items, groups, selection, visible dates, selection/open/proposal/window callbacks
remain separate from transient gesture state. Date-only arithmetic uses calendar
indices and end-exclusive ranges. Rejected proposals retain original data.

Native pointer handling activates after 500ms with mouse or touch, supports
same-gesture moves and subsequent edge resize, groups, panning, Escape and pointer
cancellation. A raw gesture recognizer prevents an ancestor ScrollView stealing
active drags; the surface handles its own vertical panning. Semantics exposes
item open/long-press actions; the demo also provides item selection and date/group
editing through existing controls and a KDialog.

Visual comparisons were made in the Codex browser at 375px standard/dark against
Storybook. Adjustments include 64px axis, 38px standard bars,48px lane pitch,
96px compact labels, responsive date ticks, visible gap-aware packing, clipped
text,month/year captions and the today line. Gallery chrome differs between
Storybook and Widgetbook. Pixel-identical rendering across engines is not claimed.

Initial focused verification:7 model tests and15 actual pointer-widget tests
passed, including mouse/touch hold, both handles, rejected consecutive gestures,
read-only, Escape/cancel and group movement inside an ancestor ScrollView.
Flutter-wide analyze and tests pass (1+16+350+78 tests); the final targeted analyzer
also passes. The normal Widgetbook build is running in timeline-flutter-checks.log
in the system temp directory. The unchanged approved Plan's Prettier issue still
blocks top-level pnpm verify; no accepted document bytes were changed.

The development server was restarted and the registered Widgetbook route is
`data-display/timeline/timeline-reference`; hot reload session71293 stays running.
Short-tap details were verified in the browser. Native device testing and the
complete reference performance matrix remain outstanding. User visual acceptance
of the Flutter reference is pending; no commit or push was requested or made.

Final Flutter follow-up: all26 focused Timeline tests pass, including four
1024px light/dark dense/spacious cases. The final Widgetbook release Web build
completed successfully (exit0), with the same existing Wasm/font warnings.
Screenshot saved at artifacts/timeline-reference/flutter-compact.png. Final
painter changes include year captions, short-bar label clipping and an axis-wide
today marker. The documented pnpm verify Plan-format blocker is unchanged.

## Stable Web drag preview

User preferred Flutter's stable lanes during gestures. Web now rejects transient
vis onMoving writes, stores the latest proposal and paints a separate clipped,
noninteractive70%-opacity clone. Canonical renderer records and all other lanes
remain unchanged until onMove hands the proposal to the consumer. Accepted data
then restacks normally; rejection/cancel/dispose removes the clone and restores
the original. Proposal geometry uses the current renderer window and measured
plot/group bounds, not unscrolled coordinate assumptions.

Six targeted Web tests and strict TypeScript pass. New regression test covers
independent clone geometry and cleanup without changing source geometry.
An actual desktop drag/drop was exercised in the browser; Research moved to
Sep24–27 and the accepted-data message updated. Held intermediate gestures
cannot be captured by the available browser tool; no full mid-drag visual
verification claim is made. The affected Storybook build is recorded in
system-temp timeline-stable-preview-build.log. Flutter files are unchanged.
The known full-verify immutable Plan-format blocker remains unchanged.
