# Orbit

`KOrbit` renders a consumer-owned hierarchy in React and Flutter. A node's
`parentId` is its moving spatial anchor, not merely grouping metadata. Its
`levelId` chooses the local orbit around that parent. Reuse a level for siblings,
or provide different levels for different radii, inclinations and speeds.

The gallery uses team → projects → issues → people/agents as sample data; none
of these domain concepts are built into the component. A node without a level
is at the scene center. Children require a level. IDs must be unique, all
references must exist, and parent cycles are rejected. When filtering a whole
branch, remove its descendants and connections as well.

## Consumer control

- Supply nodes, levels, connection definitions, labels and custom node content.
- Web: `node.radius` sets the sphere radius in world units, independently of its
  parent's size. The root need not be the largest planet. Each satellite orbit
  follows its moving parent; `level.radius` is the orbit radius, not planet size.
- Handle `onNodeActivate` to open your own detail UI. The demo composes the
  existing responsive drawer; the Orbit does not own application navigation.
- Set each node's `status` to idle, active, question or error. `statusLabel`
  supplies accessible explanatory text. `pulse` overrides the default pulse for
  active/question states. Web accepts `pulsePeriodMs`; Flutter accepts a
  `Duration` in `pulsePeriod`. These also work on the center node.
- Selection, camera and speed can be controlled by the application, with change
  callbacks. Each level supports explicit period and direction. `elapsedSeconds`
  holds orbital time at a deterministic value for comparison and testing.
- `KOrbitController.triggerSignal` starts a transient visual event on a connection;
  it does not represent network delivery. Override duration, style and endpoint
  pings per signal. Completion/cancellation callbacks are separate from node
  selection. Connection paths are transient unless `visible` is explicitly set.

## Appearance and accessibility

Orbit colors, line widths, particle sizes, node size, label size, hit-target size,
center radius ratio and animation durations are component tokens. Override them
in the consuming project's theme. The defaults use bronze sphere/track tokens;
question and error states use semantic status tokens, independently of branding.

Reduced motion uses static state indicators. Nodes have semantic labels and
keyboard access; arrows rotate, plus/minus zoom, Home resets and Escape clears
selection. Pointer/touch rotation and pinch/wheel zoom operate on the scene.

## Verification fixtures

Storybook and Widgetbook expose `orbit-team-projects`, `orbit-communication`, and
`orbit-deterministic`. The deterministic fixture freezes time at zero.
The September 30 planet-rendering revision is deliberately Web-only for visual
acceptance: shaded satellite spheres, explicit planet radii and depth-aware
occlusion. Widgetbook retains the previous rendering and fixture until approval;
visual parity is not claimed for this interim revision.

Web revision evidence (2026-09-30): 11 focused Orbit checks pass, including
four time samples of parent-relative motion, planet radius independence and
depth-ordered sphere painting. UI and Storybook type checks and the visual-token
audit pass. Browser checks at 375 px and desktop cover sphere/ring rendering,
Atlas detail activation, subtree filtering, signal completion, pointer rotation
and wheel zoom/reset. Screenshots are in `.runtime/orbit-proof/planets-web-*.jpg`.
Storybook serves emitted UI JavaScript; keep the UI TypeScript watcher running
when iterating, so new renderer source reaches the gallery. Flutter adoption is
the next step only after the user's visual acceptance of this Web revision.

Both projection test suites consume
`apps/storybook/src/orbit-parity.fixture.json`. The values cover a moving nested
chain and combined camera rotations. A separate test compares the material
equations in the Web and Flutter shaders. These checks establish numerical
parity; browser/device screenshots remain necessary for visual acceptance.

The current hierarchy decision is [ADR 0002](adr/0002-orbit-nested-hierarchy.md),
which supersedes the original common-center restriction without rewriting the
historical approved plan.

### Web command-center revision (September 30)

Approved scope: Web/Storybook only, pending visual acceptance before Flutter migration.

- Each node accepts `appearance` (`sphere`, `icon`, `avatar`), `content`, `radius`, semantic `tone`, and controlled `status` (`idle`, `active`, `question`, `error`, `completed`). Status markers remain distinct without relying only on color. Avatars can use consumer-supplied images or initials; no network asset is required.
- `labelVisibility` defaults to `interaction`: mouse hover, keyboard focus or selection reveal labels. `always` and `hidden` are explicit alternatives. Existing selection/activation callbacks remain the consumer integration points; the demo opens details through a separate action.
- `controller.triggerSignal({ id, nodeId, durationMs })` sends a local ping. Existing `connectionId` events communicate between nodes. Supply exactly one target. Status is updated through `nodes`, independently of transient events. Signals use wall time, including while orbital motion is paused; hidden scenes cancel them. Reduced-motion mode uses a static acknowledgement.
- Insertions grow with a bounded back-ease overshoot; removals reverse that motion before unmounting. Interrupted filter changes reverse from the current size. Surviving nodes retain their orbital phase and the scene does not zoom in when filtering removes a branch. Ring visibility follows the presence of its children. Motion duration uses the existing orbit transition token.
- The main fixture is Team → Issues → Agents. A separate Deep Hierarchy story demonstrates five levels. Filtering includes ancestors so consumers can retain a valid tree.
- Verification: model/drawing checks cover reversible size transitions and node-only pings alongside recursive geometry. This revision does not claim Flutter visual parity yet.

Browser verification for this revision: 375px and desktop; selection, status changes, local ping accepted/completed while paused, add/remove, ancestor-preserving questions filter, selection clearing, and details drawer. Thirteen targeted model/drawing tests, Web TypeScript, Storybook TypeScript, and style-token audit pass. Full cross-platform release verification was not run for this Web-only visual iteration. Evidence: `.runtime/orbit-proof/command-center-deep.jpg` and `.runtime/orbit-proof/command-center-mobile.jpg`. Next action: user visual acceptance of the Web demos.

### Flat Web appearance (September 30)

Following visual feedback, the Web default is now a flat `icon` circle. Team initials, issue icons and agent avatars use existing semantic surface/status background and foreground tokens. Sphere shading is opt-in with `appearance: "sphere"`; flat nodes never invoke the sphere shader or center glow. Missing flat-node content falls back to two label characters. Selection uses the existing focus color and a subtle surface overlay; static status rings no longer draw a second pulse ring. Existing orbital geometry, gestures and signal/filter transitions are unchanged. Main, communication and deep-hierarchy demos all use the flat default. Flutter remains unchanged pending Web acceptance.

Verification: 14 targeted tests (including default flat rendering without shader/gradient/glow), Web and Storybook TypeScript, style-token audit, Dark/Light browser inspection. Screenshot: `.runtime/orbit-proof/orbit-flat-dark.jpg`. No release build or commit in this visual iteration.

Contour refinement: the persistent node boundary now carries the status color directly. The former offset status outline is removed; only transient attention/communication pulses expand outside the node. A regression test checks one persistent contour for idle, active, question, completed and error states (15 targeted tests pass).

### Web node configuration and bounded motion (2026-09-30)

Approved scope: Web library and Storybook only; Flutter remains pending visual acceptance.
Each level accepts `periodSeconds` and `direction`; each node can override both.
The default period is now 60 seconds, independent of hierarchy depth. The example
uses 90/60/50/45 seconds. `motionSpeed` multiplies angular velocity, then
`maxAngularSpeed` caps each node's local orbit in degrees/second (default 12).
Zero pauses orbital motion; the cap does not bound inherited parent translation
or camera rotation. Live speed/period changes integrate from the current angle,
without teleporting. Camera geometry and parent-relative rings stay unchanged.

Nodes accept `backgroundColor` and `borderColor` as CSS colors, including consumer
`var(--token)` references. Omission preserves the existing semantic token defaults.
`content` supplies text, an icon or avatar. `badge: { content, label, tone }`
overrides the status badge, `badge: null` hides it, and omission derives it from
status. Include `badge.label` for meaningful non-text content; badge content is
presentational, while node activation remains the interactive target.
`pulse`, `pulsePeriodMs` and `pulseIntensity` (0–1) independently control attention.
Reduced motion suppresses continuous pulses. Controller-triggered pings remain
separate from persistent status.

Storybook now demonstrates token color overrides and a custom count badge, a
maximum-speed slider, and selected-node period, pulse and badge controls.
Verification: 17 focused Orbit tests, Web/UI and Storybook TypeScript, visual-literal
audit. No commit requested and no full cross-platform release verification run.

### Compact Web review workspace

Storybook-only layout refinement: the demo occupies its viewport. At widths below
900px the canvas stays above an independently scrolling controls panel; wider
views use a canvas and right-side controls. Scene gestures no longer stand in the
way of reaching the controls. A node selector and radius slider demonstrate the
existing per-node world-unit size API (the demo slider range is 2–80, not a library
limit). Node radius is independent of orbit radius; no new component API or Flutter
changes. Verified at 423×772: controls scroll while canvas top and height remain
unchanged, and signal activation still reports accepted/completed.

### Web pointer mapping and details

Approved follow-up: primary mouse drag pans the canvas, secondary mouse drag
rotates yaw/pitch; the stage suppresses the native context menu. Rotation inertia
is retained only for rotation; pointer cancellation clears it. Existing single
finger rotation and pinch zoom remain unchanged. Activating a node invokes the
consumer callback as before; the demo now directly opens KResponsiveDrawer
(bottom sheet below 600px, right drawer otherwise). The configuration selector
only selects a node, without opening details.

Verification: 18 focused tests and UI/Storybook TypeScript pass. Browser primary
drag moved the root exactly +80/+40px; desktop drawer and 423×772 bottom sheet
were visually checked. Secondary-drag math is covered by a runnable test; the
browser automation API does not expose a held right-button drag. Screenshots:
`.runtime/orbit-proof/orbit-compact-workspace.jpg`, `orbit-node-drawer.jpg`, and
`orbit-node-bottomsheet.jpg`. Next action: user visual acceptance of Web.

### Badge projection

Web badges now scale from the rendered node radius relative to the existing
orbit-node-size token. This scales badge text, padding and border together with
zoom, node sizing, viewport projection and presence animation, instead of keeping
a fixed screen size. UI TypeScript passes. Browser measurement for all five
visible badges: a 1.12× zoom produced 1.12× node and badge dimensions (rounding
error below 0.000003). Evidence: `.runtime/orbit-proof/orbit-badge-zoom.jpg`.

### Web icon scaling and consumer zoom bounds

The node content now renders inside a token-sized local coordinate box, scaled
by the same projected radius as the circle. This handles KIcon inline dimensions,
text and avatar content consistently through zoom and size/presence changes.
Non-avatar child content fits within 70% of the local box to avoid corner clipping;
avatars retain full circular coverage. Labels and interactive hit targets remain
screen-sized for usability.

Existing `zoomBounds={[minimum, maximum]}` applies to wheel, pinch, keyboard,
reset and controlled views, including live bound changes. Invalid/non-finite,
non-positive or reversed bounds throw an explicit error. Storybook exposes both
limits as sliders (demo ranges are not library limits). Verified 0.1–1 bounds in
the browser: repeated zoom input stops at each endpoint, radii ratio exactly 0.1;
icons track node zoom at 1.12× and fit at the minimum. 19 focused tests, UI and
Storybook TypeScript and visual-literal audit pass. Flutter unchanged.

### Web node following and progress

`pinnedId` is controlled independently of selection. Keep it in consumer state
and handle `onPinnedChange` (reset or removal requests `null`). The demo provides
Follow node in the existing responsive details drawer and Stop following in the
configuration panel. Following centers the projected node including its moving
ancestors; zoom and rotation remain available, while manual panning is disabled.
Unpinning returns to the central node and `defaultView`, with zero pan offset.
Removing/filtering the followed node performs the same reset and clears inertia.

Optional node `progress` accepts finite values from 0 to 100. Its arc starts at
12 o'clock on the existing contour, inherits the node's border/status color, and
scales with the node. `--k-component-orbit-progress-line-width` defaults to the
existing focus-border token, falling back to the strong-border token. Value transitions and the camera return use the
existing Orbit transition duration; reduced motion snaps to the new state.
The demo exposes Node progress and starts Release readiness at 42%.

Verification: 22 focused tests and UI/Storybook TypeScript pass. Browser checks
cover following under zoom/inclination, restoring the center, filtering the
followed node and changing progress to 50%. This addition is Web-only; it does
not establish a Flutter API or implementation commitment.

### Flutter transfer approved after Web review

On 2026-09-30 the user approved transferring the current Web Orbit to Flutter,
after backup commit `823eb16`. Scope: recursive geometry and motion limits,
flat node presentation, per-node content/colors/badges/pulses/progress, animated
filter presence, zoom/pan/rotation, node following and the matching Widgetbook
demonstrations. Web remains the visual reference.

Flutter consumers control `pinnedNodeId` and `onPinnedChange`, independently of
selection. Unpinning or removing the target restores `initialViewState` and zero
pan. Node `progress` is nullable (0–100); `visualStyle.progressLineWidth` falls
back to `borderWidthStrong`. `showBadge: false` explicitly hides automatic or
custom badges; otherwise `badge` overrides the status badge. Colors accept
consumer token values, content and badge content accept widgets. `labelVisibility`
defaults to interaction. Signals target exactly one `nodeId` or `connectionId`.

Verification on 2026-09-30: the 17 focused Flutter Orbit tests cover recursive
projection, capped motion, reversible presence, progress transitions, following
through zoom/rotation, unpin/filter reset, mouse pan/rotation, touch/pinch and
local signal completion while paused, accessible activation and proportional
content/badge zoom. Widgetbook release build succeeds;
browser checks confirm the new command center and responsive detail/follow flow.
Visual acceptance remains with the user; this is not a claim of a completed
pixel-diff baseline between the platforms.
