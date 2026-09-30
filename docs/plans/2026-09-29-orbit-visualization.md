---
title: "Cross-platform interactive Orbit visualization"
date: 2026-09-29
---

# Cross-platform interactive Orbit visualization

## Outcome and approval boundary

Status: draft for Human Plan Approval. Regular planning requested on 2026-09-29.
Deliver KOrbit for React/Web and Flutter with matching visuals and interactions,
consumer-owned nodes, levels, relationships, selection and camera state.
This plan authorizes no implementation until approved. Website repository is
read-only reference. No commit, push or release is part of this planning task.

## Evidence

Observed https://knaack.it/ in Codex Browser: luminous bronze spherical center,
three inclined elliptical tracks, readable labels, depth fading, moving nodes.
Inspected D:/Development/KNAACK.IT-WEBSITE/app/public/orbit/orbit.js,
orbit-rotation.js and orbit-connections.js. Current source uses an orthographic
Three.js sphere, shared trigonometric projection, HTML labels, SVG quadratic
connections and travelling signal dots. Rotation has frame-independent inertia,
keyboard arrows and Home; touch rotation is deliberately excluded. No zoom is
implemented there. Three rings, colors and relationships are hardcoded.
Our library has no Orbit component or Three.js dependency. Reuse KIcon,
KAvatar, KIconButton and existing overlay/drawer components, not website UI.

## Architecture proposal

See accompanying Orbit rendering ADR. Use a deterministic projected scene:
identical TS/Dart formulas for 3D positions, orthographic projection, depth order,
curves and time. Web Canvas2D and Flutter CustomPainter draw tracks/signals;
accessible HTML/widget overlays draw labels and interactive node content.
A common analytic sphere fragment-shader formula preserves the rich center
(WebGL on Web, FragmentProgram in Flutter), with small platform wrappers.
No physics engine, graph-layout engine, embedded WebView or new 3D dependency.
First prove this renderer on both platforms; do not silently downgrade the
reference to flat circles if the shader comparison fails.

## Consumer contract
Proposed public names are KOrbit, KOrbitLevel, KOrbitNode, KOrbitConnection,
KOrbitViewState, KOrbitController and KOrbitSignal, equivalent on both platforms
with idiomatic callbacks. Reuse existing controller conventions where available.
- Levels: stable id, radius, inclination/azimuth, periodSeconds, label. Ordered
  levels around one center; arbitrary level count, no three-level assumption.
- Nodes: stable id, levelId (center has no level), optional parentId, label,
  description, Lucide icon/avatar content, phase, disabled state, semantic tone.
  parentId describes Team -> Project -> Issue -> Agent/Human, not a database.
  Relationships may cross levels. No recursive miniature solar systems in V1.
- Connections: stable id, sourceId, targetId, direction, label, semantic tone,
  lineStyle and signalStyle. Connections express relationships; signals are
  explicitly triggered visual events, never simulated network progress.
- Controlled selection and view (yaw, pitch, zoom, offset), initial defaults for
  uncontrolled use, onNodeActivate, onSelectionChange, onViewChange and
  onInteractionStart/End. Updates retain phase/selection by id. In uncontrolled
  mode removing the selected node clears selection; controlled mode notifies the
  consumer and renders no stale selected node. Animation never mutates host data.
- Consumer pause, speed, zoom bounds and accessible labels; system reduced-motion
  preference is respected. Consumer node/center content slots use screen-space
  sizes and documented bounds. Appearance uses shared tokens with host overrides.
- Duplicate IDs, missing levels/endpoints, cyclic parent chains, invalid radii or
  non-finite numbers produce actionable validation errors, never NaN rendering.
- Only demo composition opens a responsive side drawer / bottom sheet from an
  activation callback; core KOrbit has no router, fetching or product actions.

### Triggered communication

controller.triggerSignal({id, connectionId, durationMs?, style?}) triggers one
visual transmission on an existing directed connection. Consumers map their own
incoming events to this method. Stable controller identity and ordinary rebuilds
must not replay events. Reject a duplicate active signal ID; no unbounded event
history. Return accepted / capacity / invalid / inactive so suppression is visible
to the caller. Validation behavior and return values match across platforms.

Default sequence matches the website: source ping, travelling point on a curved
connection, destination ping. Duration is visual only: default travel 1200ms,
source/destination ping 240ms, all resolved from motion tokens. A signal may
override travel duration; global motionSpeed scales elapsed animation time.
Arrival means visual arrival only, never delivery acknowledgement. Expose
onSignalEnd(id, completed | cancelled); fire once for accepted signals. Removing
an endpoint/connection or explicitly cancelling via controller cancels its
signals and suppresses arrival pings. Dispose performs cleanup without callbacks.

Use maxActiveSignals (default 32) and no pending queue: reject excess new signals
with capacity rather than retaining a backlog. Existing signals finish normally.
Explicit pause/zero speed freezes accepted signals and rejects new triggers as
inactive; resume continues their remaining visual time. Hidden/offscreen scenes
cancel transient signals once and reject new ones; resume never replays a burst.
Reduced motion shows a static destination emphasis for the same configured visual
lifetime, with no travelling dots, expanding pings or animation ticker. Expiry uses
bounded scheduled cleanup. It retains the same completed/cancelled semantics.

### Styles and design tokens

V1 named line styles: solid, dashed, dotted. Default orbit track is solid; default
communication path is dashed. V1 signal styles: travelling point with endpoint
pings (default), short travelling trail with endpoint pings, endpoint pings only.
Source and arrival pings can independently be disabled. Optional style selection
is global with per-connection/per-signal overrides; no user-authored shader API.
Line width, dash/gap lengths, caps, opacity, colors, glow, particle size, trail
length, ping radius, durations and easing resolve through component tokens using
existing semantic/foundation aliases. Appearance is not hardcoded in event data.
Zoom transforms geometry; stroke width, particles, labels and hit targets remain
screen-space sizes. Both engines share curve sampling, dash phase, interpolation
and ping easing for deterministic comparison. Cache arc-length samples until a
curve changes; do not independently approximate motion timing on each platform.

Native drawing covers these styles without another animation library. Canvas2D
provides setLineDash; Flutter provides PathMetric/extractPath. Use a shared sampled
segmentation algorithm only where native output fails the measured parity target.
Sources: https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setLineDash
and https://api.flutter.dev/flutter/dart-ui/PathMetric/extractPath.html

### Additional acceptance cases

Communication demo offers event trigger, burst trigger, style selection, duration
and speed controls built from existing primitives. Test source/arrival pings at
fixed clock positions, overlapping signals, active-ID deduplication, capacity,
pause/resume, cancellation, filter removal, disposal and hidden-view lifecycle.
Verify styles in both themes, densities and at minimum/maximum zoom. Add reduced
motion and full/reduced effects screenshots. Quality reduction may reduce glow
and particle detail, never alter event semantics or node interaction.
Measure reference and burst workloads on a named older midrange Android device
when available. If only a recent device/emulator is available, disclose the gap;
GPU-backed painting alone is not performance evidence. No universal device claim.
## Interaction specification

Drag background with mouse or one finger to rotate in dedicated/full-page mode;
threshold separates tap from drag. Pinch zooms; wheel zooms when stage is engaged.
Embedded mode preserves one-finger page scroll and uses two-finger manipulation;
visible focus/activation affordance and instructions explain this distinction.
Keep pinch focal point stable using a bounded view offset shared by both engines;
include that offset in view state. Clamp pitch/zoom and reset all view fields.
Release inertia must not trigger node activation. Pointer cancel, lost capture,
second-pointer transitions and resize must leave no stuck gesture.
Keyboard: focusable nodes activate via Enter/Space; stage arrows rotate, +/- zoom,
Home resets, Escape clears selection. Provide visible Reset/Zoom/Pause controls
using existing buttons, with optional consumer visibility and localized labels.
Pause orbital motion during focus/interaction; reduced motion removes auto motion,
inertia and travelling particles while retaining connections and all actions.
Foreground hit targets win by projected depth. Labels stay upright; selected and
focused labels have priority in deterministic overlap handling. Hide only excess
visual labels, never lose accessible node access: provide an equivalent node list.
Touch targets use the design-system minimum; do not enlarge the drawn planet.

## Visual and performance contract

Shared clock/phase, same fixtures, same font/icon assets, tokens and camera.
Track segments, nodes and connections have consistent front/back ordering around
the sphere. Lighting/noise palette comes from tokens rather than bronze literals.
Density changes labels/targets consistently, not orbital topology.
No random per-platform layout, frame-count-based motion or rebuild of the whole
React/Flutter tree every frame. Stop animation offscreen, hidden or disposed.
Cache geometry/text measurements; cap rendering DPR via quality policy. Consumer
may choose full or reduced effects without changing layout or available actions.
Reference budget: 50 nodes, 6 levels, 100 edges; stress fixture 200/12/400. Measure
frame times on the connected Android device and desktop (profile/release, not
Widgetbook debug). Target p95 <= 16.7ms for reference; report device and traces.
Do not claim unlimited scalability. Do not introduce virtualization preemptively.

## Implementation sequence and ownership

Use GPT-5.6 Sol Medium for bounded implementation work as requested. Initiating
agent owns integration. Optional GPT-6 Astra Medium final review is authorized;
AI review is not Human Acceptance. No autonomous persisted task DAG.
1. Shared contract and parity proof: one center, two levels, fixed clock, rotation,
   one connection and matching shader samples in both platforms. Owner: one Sol
   agent for coupled math/shader contract. Compare before full component work.
2. Web component: owner limited to packages/web/ui/src/data-display/orbit*, public
   exports and apps/storybook Orbit stories. Implement agreed interaction spec.
3. Flutter component: owner limited to packages/flutter/k_design_ui/lib/src/
   data_display/orbit*, shaders/pubspec/exports and apps/widgetbook Orbit fixtures.
   Steps 2 and 3 may run in parallel only after shared contract is fixed.
4. Integration: initiating agent owns tokens source/generation, fixtures,
   component catalog, documentation, consumer examples and final checks.
Each implementation agent receives this plan, ADR, exact fixture and math test
vectors; it must not independently redesign API, colors, timing or gestures.
Allowed supporting paths: tokens/, tooling/ existing generators/checks, docs/,
examples/ and relevant package manifests/tests. Never edit generated files by hand.
No changes to KNAACK.IT-WEBSITE, unrelated controls or existing visual baselines.

## Demonstrations and acceptance

Matching Storybook/Widgetbook stories: Reference, TeamProjects, Communication,
Controlled, ReducedMotion, DenseGraph, Empty. TeamProjects shows center Team,
projects, issues and agent/human nodes, adding/removing levels/nodes externally,
selection and responsive detail drawer with event log. All labels configurable.
Test 375x812, 768x1024 and 1440x900; light/dark, all densities and token override.
Freeze clock at 0 and 2 seconds; compare at default and rotated/zoomed states.
Geometry anchors must agree within 1 logical pixel; inspect screenshot differences
for labels, glow, depth, lines and focus. Rasterizer antialiasing differences must
be reported rather than promising byte-identical pixels. Human visual acceptance
on both platforms is mandatory before claiming pixel parity.

## Verification

Math tests share vectors for projection, parent validation, depth, curve progress,
zoom focal anchoring and frame-rate-independent inertia. Interaction tests cover
mouse/touch/keyboard, scroll arbitration, tap-after-drag suppression, controlled
updates, node deletion, reduced motion and cleanup. Shader failure fallback must
retain nodes/actions and show a stable token-driven center on both platforms.
Run focused tests/typecheck/analyze while iterating; integrated final pnpm verify.
Verify package consumer exports/tree-shaking and shader asset packaging, launch
both galleries, exercise real browser drag and Android pinch with screenshots.
Planning-only checks: skillset plan check and skillset adr check. No build needed
for this document-only task. Record any unrelated legacy checker findings.

## Research

- https://docs.flutter.dev/ui/design/graphics/fragment-shaders (FragmentProgram;
  fragment-only constraints mean Three.js vertex shaders cannot be copied).
- https://api.flutter.dev/flutter/rendering/CustomPainter-class.html (drawing and
  semantics; reuse repaint scheduling rather than rebuilding widget trees).
- https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html (pan/zoom
  reference; not a complete replacement for orbit rotation gesture arbitration).
- https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events/Pinch_zoom_gestures
  (multi-pointer bookkeeping and cancellation).
- https://threejs.org/docs/pages/OrbitControls.html (3D controls alternative;
  rejected as the sole contract because Flutter parity would still need a port).

## Refinements requested during planning

Each level has independent plane orientation (inclination and azimuth), direction
and optional periodSeconds. Use periodSeconds as the public speed input (not a
second ambiguous angularSpeed input); derive angular velocity as 2*pi/period.
If omitted, derive a documented outer-slower period from radius, e.g.
basePeriod*(radius/baseRadius)^1.5; this is a visual default, not a physics claim.
Global motionSpeed multiplies orbital/signal time (0 pauses), without phase jumps
when changed. Expose onMotionSpeedChange and an optional KSlider + Pause control;
consumer may render controls elsewhere. Motion amplitude/glow remains token-driven.
Controls are optional; demo shows speed, reset and a host-owned active-only filter.

Filter updates animate entry/exit (opacity and modest scale), incident connections
and changed orbit geometry over token duration/easing. Stable IDs preserve phase
of remaining nodes; exit nodes stop accepting interaction immediately, and focus
moves predictably if the focused node is removed. Rapid toggling interrupts from
the current interpolated state, never queues stale animations. New levels expand
the scene bounds smoothly without unsolicited camera reset. Filter logic belongs
to the consumer; KOrbit animates changes to supplied data. Reduced motion applies
changes immediately. Test remove/reinsert, filtering during rotation/pinch,
selected-node removal, live speed changes and zero-speed updates in both engines.

Browser verification: focused the reference stage and used Right/Up; screenshot
confirmed a changed yaw/pitch and different projected ring angles. Existing
reference keyboard interaction is functional. Zoom remains a new capability.

