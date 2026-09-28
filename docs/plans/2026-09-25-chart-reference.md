---
title: "Cross-platform interactive chart reference"
date: 2026-09-25
---

# Cross-platform interactive chart reference

## Outcome and approval boundary

Regular delivery: one matching interactive line-chart reference in Storybook and Widgetbook, for human visual acceptance before expanding the chart catalog. User accepted this bounded direction on 2026-09-25; this exact Plan and proposed Decision 0009 still require Human Plan Approval before implementation. No chart code or dependencies are changed by this proposal.

## Scope

Implement KLineChart wrappers around a pinned published TanStack Charts release and fl_chart, subject to the capability check in [Decision 0009](../decisions/0009-chart-reference-adapters.md). Use [Decision 0005](../decisions/0005-tiered-design-token-contract.md) for appearance/content separation.

Reference fixture chart-line-reference: two named series, 14 explicit UTC dates and deterministic values/formatters; date and numeric axes, subtle grid, linear paths, selected-point indicator, shared value tooltip, legend to hide/show series and optional data-table alternative. Initial rendering is static; data/selection transition motion uses existing motion tokens and respects reduced motion.

Expose stable point/series IDs, immutable data, axis bounds/ticks, date/value formatters, labels, controlled selection and visible series with change callbacks. The consumer owns fetching, persistence and navigation. Use common token defaults for plot insets, series colors, line/point geometry and controls; add only source tokens needed by this fixture, with identical platform projections. Do not expose renderer-specific models as mandatory consumer inputs.

Desktop hover reveals values; click selects; keyboard arrows move between data points and Escape clears. Touch tap selects and outside tap clears; normal page scrolling remains available. Legend controls work with keyboard, mouse and touch. Tooltip content and selection callbacks describe the same point on both platforms. Empty/loading/error and all-series-hidden states use existing primitives. Missing values create gaps, not invented zeros.

Non-goals: candlestick and other chart types, zoom/pan/brush, streaming, exports, chart builder, arbitrary animation parity or WebView rendering. These require a later accepted slice after this reference succeeds.

## Paths and ownership

The initiating agent owns implementation and evidence. Allowed paths: packages/web/ui/src/charts and exports/styles, packages/flutter/k_design_ui/lib/src/charts and exports, their package manifests/tests, apps/storybook/src chart stories, apps/widgetbook/lib chart fixtures/gallery registration/tests, tokens source/projection generator support only when needed, generated token outputs through generators, shared chart fixture data under fixtures, lockfiles, and this plan/evidence. No unrelated component redesign or infrastructure changes.

## Work sequence

1. Verify the actual published package APIs, compatibility and licenses; install exact versions. Stop on a required capability gap rather than silently substituting an engine.
2. Define matching public contracts, deterministic fixture and source-token mapping. Add contract/interaction tests.
3. Implement both adapters and reusable legend/tooltip composition with existing primitives.
4. Open matching galleries and compare screenshots and interaction states at 375px, 768px and 1280px. Correct geometry and behavior before expanding scope.
5. Run final checks and present both demo links, evidence and any measured residual differences for Human Acceptance. No automatic follow-on chart families, commit or push.

## Acceptance and verification

- Matching plot bounds, tick positions, path/marker positions, typography, legend and tooltip padding. Shared deterministic fixture and explicit axes prevent engine auto-layout divergence. Record screenshot overlays; target at most 1 logical pixel geometry difference, recording font antialiasing differences separately. Do not claim pixel parity without this evidence.
- Cover Orbit Light/Dark, Reference theme and dense/standard/spacious. Screenreader labels and accessible table; mouse, keyboard and touch selection; outside dismissal; mobile page scrolling; long labels, empty data, gaps, negative values, data replacement and a 1000-point smoke fixture without creating 1000 focusable controls.
- Token overrides visibly update both platforms. Consumers can control/reset selection and visible series; callbacks fire once per committed interaction and use stable IDs.
- Iteration: pnpm build:web, pnpm typecheck:web, targeted Flutter tests/analyze, shared-fixture/contract tests and browser interaction checks on affected stories. Refresh package output for Storybook and hot-restart Widgetbook as needed.
- Final integrated gate: pnpm verify. Browser behavior and matching screenshots remain required in addition to automated checks. Native Android touch smoke on the connected OnePlus if available; otherwise explicitly report native-device verification missing, not as passed.
- Record exact commands, tested revision/diff and screenshots in a small evidence document. Human Acceptance follows successful checks; any unmet mandatory criterion stays open or needs an explicit named exception.

## Risks and deferred decisions

TanStack Charts is Alpha and its docs can be ahead of the published package. Axis auto-layout and native text measurement differ, so use explicit matching geometry for this reference. Accessibility is wrapper responsibility where engines differ. Do not generalize this proof to candlestick or the entire libraries. The next decision, after review, is whether the pair meets the design system standard and which chart family to add.
