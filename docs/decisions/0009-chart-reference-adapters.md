# Decision 0009 — Cross-platform chart reference adapters

> Status: accepted
> Date: 2026-09-25

## Context

The design system needs matching interactive charts for React/Web and native Flutter. The user accepted a reference-chart-first evaluation on 2026-09-25, before expanding the catalog. Existing Decision 0005 continues to govern tokens. This proposal does not promise arbitrary renderer pixel identity.

## Decision

Evaluate an exactly pinned published @tanstack/charts release behind a Web KLineChart adapter and exactly pinned fl_chart behind a Flutter KLineChart adapter. Verify published exports, license and compatibility before adding dependencies; documentation for TanStack follows unreleased main and its API is Alpha. If required public capabilities are absent, report the concrete gap before selecting another engine.

Expose matching domain concepts (series/point IDs, numeric values, explicit date timestamps, formatter callbacks, controlled selection and visible series) instead of requiring consumers to import engine models. Consumer data stays immutable. Appearance is sourced from shared design tokens. Build tooltip and legend with existing design-system primitives; supply native keyboard/semantics behavior where an engine lacks it. No WebView in Flutter.

Explicit identical axis bounds/ticks, plot insets and linear interpolation define the first visual comparison. Local time-zone defaults must not cause different dates; the fixture uses explicit UTC values and deterministic formatting. Density changes labels and controls without changing data.

## Alternatives

- graphic: flexible grammar and custom marks, retained as a fallback if fl_chart blocks required parity.
- Syncfusion: extensive chart types, but adds commercial/community licensing requirements for downstream consumers.
- One Web renderer inside Flutter WebView: closer renderer identity but compromises native interaction and accessibility.
- Full custom renderer: too much chart behavior to recreate for this bounded reference.

## Consequences and confirmation

TanStack Alpha may require adapter maintenance; pin and test upgrades. Native SVG/Canvas/text rasterization can differ, so shared geometry and behavior need measured comparison rather than a blanket pixel-perfect claim. Prove line-chart parity before adopting more types. Zoom/pan, candlestick, live streaming and additional chart families are deferred. Accessibility includes keyboard selection, spoken values and an optional accessible data-table alternative.

Sources: https://tanstack.com/charts/latest/docs/stability ; https://tanstack.com/charts/latest/docs/overview ; https://pub.dev/packages/fl_chart ; https://pub.dev/packages/graphic

