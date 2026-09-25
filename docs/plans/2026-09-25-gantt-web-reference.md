---
title: "Gantt Web reference"
date: 2026-09-25
---

# Gantt Web reference

## Outcome

Create a Web-first Gantt reference in Storybook using SVAR React Gantt 2.7.3. The user accepted the proposed scope on 2026-09-25: "Das klingt doch hervorragend. Bitte mache das." Flutter follows only after visual acceptance of the Web reference.

## Scope

The initiating agent owns integration and verification. Allowed paths: apps/storybook/src/gantt/, apps/storybook/src/gantt.stories.tsx, apps/storybook/package.json, pnpm-lock.yaml, fixtures/gantt-reference.json, tooling/gantt-*.test.mjs, artifacts/gantt-reference/, and this Plan's evidence. Preserve all existing Timeline and chart work.

This is a gallery-only evaluation, not a production renderer commitment or public package export. No Flutter changes, infrastructure changes, new token axes, commit or push. No production ADR is selected by this probe.

## Implementation

1. Pin the MIT core package after inspecting its archive and license. Prove accepted and rejected changes, repeated drag after rejection, cancellation, external updates and touch activation before expanding the reference.
2. Provide a hierarchical task table and synchronized time chart, expandable summary rows, task bars, progress, milestones and dependency arrows. Use configurable columns and a resizable table region.
3. Provide day/week/month scales and navigation. Keep task identity and canonical data consumer-owned; emit proposals and apply only accepted updates. Temporary drag/resize previews must not reorder unrelated tasks.
4. Desktop supports mouse editing. Compact portrait uses scrolling, short tap for details and long press for editing with usable resize targets, for mouse and touch. Offer accessible date inputs as an alternative to dragging.
5. Use existing design tokens and primitives for controls, dialogs, typography, icons and density. All records, labels, columns, selection, expansion, permissions and callbacks are external adapter inputs.
6. Use date-only half-open ranges, explicit milestones, stable IDs and a deterministic shared fixture. Render dependencies initially; advanced scheduling and dependency authoring are deferred.

## Decision and risks

SVAR is the initial candidate rather than a permanent package dependency. Frappe remains a simpler alternative; Bryntum offers a broader product. SVAR PRO scheduling, critical path, baselines, calendars and other licensed additions are excluded.

The inspected 2.7.3 source starts bar touch editing after 300 ms and mouse editing immediately, while row touch reorder uses 500 ms. Our consistent compact long-press activation therefore needs an adapter, not an assumption about the library default. The API can intercept actions, but cancellation and rejection must be verified at runtime including transient geometry. If public APIs cannot provide this reliably, stop and report the limitation before changing renderer strategy.

## Verification

Record exact package version and license. Test accepted/rejected date and progress proposals, repeated interactions, stable IDs, exclusive ends, invalid dates, read-only records, Escape/pointer cancellation and incoming external state. Verify short tap versus hold and scroll before activation.

Run focused Node tests, TypeScript checks and Storybook smoke checks. Inspect 375/425 px and desktop in light/dark and Dense/Standard/Spacious. Exercise both resize edges after scrolling, task dragging, group expansion, dependency alignment and detail controls. Record screenshots and distinguish automated pointer evidence from manual visual evidence.

Run pnpm install for the dependency change and the final pnpm verify program. The existing immutable Timeline Plan formatting failure is a known blocker, not permission to modify the approved document. Report it separately from affected checks. Flutter and native-device checks are not applicable to this Web-only slice.

## Acceptance

Deliver the Storybook link, observable results, screenshots and named limitations for Human Acceptance. Do not claim native Flutter parity or complete accessibility from Web screenshots. Continue with Flutter only after the user's Web acceptance.
