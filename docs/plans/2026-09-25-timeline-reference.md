---
title: "Timeline reference and renderer evaluation"
date: 2026-09-25
---

# Timeline reference and renderer evaluation

## Summary

## Outcome

Prove one interactive planning timeline in matching Web and Flutter gallery prototypes before choosing production renderer dependencies. This is the first bounded slice toward KTimeline and KGantt; it does not approve full Gantt implementation or a public component API.

## Human intent

On 25 September 2026 the user accepted Regular mode and the proposed timeline-first approach: "Okay, das machen wir so. Fangen wir bitte an." This authorizes preparing the Plan, not approval of its exact implementation bundle.

## Scope and ownership

The initiating agent owns integration and evidence. Compare vis-timeline for Web and flutter_gantt for Flutter using the same deterministic fixture. Inspect package source and licenses before introducing pinned gallery-only dependencies. A failed candidate is reported; replacing it with a custom renderer or another dependency requires a revised decision.

Allowed paths: apps/storybook timeline prototype and package manifest; apps/widgetbook timeline prototype, registration, assets and manifest; shared fixtures/timeline-reference.json; dependency lockfiles; targeted tests; artifacts/timeline-reference; docs/plans/evidence/timeline-reference-verification.md. Existing chart work remains intact. No production package exports, accepted ADR edits, generated-source edits, infrastructure changes, commit or push.

## Reference behavior

- One horizontal planning timeline with three named groups, twelve stable-ID items, a point milestone, overlapping ranges and a read-only item.
- Day/week/month zoom controls, Today action, fixed group labels, synchronized scrolling and selected-item details composed from existing primitives.
- Mouse and touch scrolling; item movement and start/end resizing with visible previews, date snapping and cancellation. Scrolling must not unintentionally mutate items.
- Consumer-owned canonical records. Preview state is temporary. A commit callback proposes old/new range and group; accepting updates the fixture, rejecting restores the original. No renderer mutation may silently become canonical data.
- All text, labels and item content configurable in the prototype adapter; styling uses existing tokens and density values. No new token axis in this evaluation.
- Date-only half-open intervals [start, end) for the initial fixture. Display exclusive end as the previous included day when appropriate. Keep all-day dates distinct from UTC instants. Time-of-day scheduling remains outside this slice.
- Compact view remains a usable horizontally scrollable timeline with a narrow label column. Include selection/date controls as alternatives to drag, keyboard focus and accessible labels.

## Decision inventory

No production renderer or public API is selected by this Plan. Evaluate library suitability for controlled updates, deterministic geometry, customization, scrolling, accessibility, performance and licensing. Record limitations and recommend an explicit production ADR after the comparison. Do not infer that successful screenshots establish complete parity.

Alternatives: two thin library adapters (preferred evaluation); a shared behavioral specification with native custom rendering (more maintenance, only if candidates fail); WebView reuse (not proposed because it changes native behavior and integration).

Gantt hierarchy, dependency editing, automatic scheduling, critical path, baselines, large-scale performance guarantees and public KGantt delivery are excluded.

## Verification and acceptance

Before implementation record tested package versions and license files. Add targeted tests for accepted/rejected edits, cancellation, stable IDs, overlapping ranges, exclusive end and month boundaries. Exercise drag and resize after horizontal scrolling, both edges, read-only items and changing external records while idle.

Compare matching 375px and tablet-width screenshots in Light/Dark and Dense/Standard/Spacious; test pointer scrolling and browser touch emulation where supported. Measure representative initial rendering and scrolling with an additional 500-item fixture; report actual results rather than promise a performance threshold without a baseline.

Use affected Web typechecks and Flutter analyze/tests during iteration. Run pnpm install and dart pub get if manifests change; final integrated pnpm verify is required. Browser checks cover Storybook and Flutter Web. Native device testing requires a runnable Android host; the current Widgetbook has none, so do not claim native touch verification or scaffold a host within this slice. Report this release limitation explicitly.

Deliver screenshots, observed interaction results, limitations and a renderer recommendation for Human Acceptance. No automatic review, commit or push.

