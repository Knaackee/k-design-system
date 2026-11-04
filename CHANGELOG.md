# Changelog

All notable changes to supported K Design System releases will be documented in
this file. The project follows semantic versioning once the first supported
version is tagged.

## Unreleased

- Final visual acceptance and the release tag remain pending.
- **Breaking (Decision 0010):** adaptive axes now resolve at runtime from the
  available window and platform (`applyKAdaptive`, `resolveKAdaptive`,
  `KAdaptiveTheme`, `resolveKAdaptiveConfiguration`). Galleries default to the
  same resolution. Migration: Flutter apps wrap their app in `KAdaptiveTheme`
  instead of passing `KDesignConfiguration.mobileApp`; Web apps call
  `applyKAdaptive(document.documentElement)`.
- **Breaking:** `KDesignConfiguration.mobileApp` is Standard density with the
  new `mobile` type ramp (H1 28/34, body and controls 16) instead of Spacious.
- **Breaking:** removed `font.microSize` and `font.microLabelSize` (8/9 px);
  use `font.caption2Size` (11 px). Off-grid spacing roles snap to the 4 px grid.
- Added per-role system text-scale caps (`text.scaleMax.*`): headings 1.4,
  controls 1.6, body 2.0. Fixed balanced headings measuring with an unclamped
  text scaler.
- Added opt-in follow-up submission during active chat responses on Web and
  Flutter, preserving the stop action and submission controls.
- Made standard presentation cards compact with accessible icon actions while
  preserving full content and cover-card actions.
- Added expanded select popups with optional option descriptions on Web and
  Flutter, bounded by the viewport.

## 1.0.0-rc.1 - 2026-09-25

- Established public Web and Flutter package boundaries for the first release
  candidate, including Timeline and Gantt.
- Added standalone Web and Flutter consumer examples with host-owned token
  overrides and state/event integration.
- Added Web ESM, package-content and tree-shaking verification.
- Added the supported Git-submodule integration and migration workflow.
- Added a reusable consumer-agent skill with explicit token-ownership gating.

No supported release has been published from this changelog yet.
