# KRobotHead — restart handover, 15 October 2026

## Stop and resume boundary

The user requested a computer restart, this handover, and explicitly: **stop when
the handover is finished**. Implementation is stopped. All three workers stopped
at saved file boundaries. Do not continue until the user resumes the task.
No commit, push, dependency installation or computer restart was performed in
this turn. Uncommitted work must be preserved.

On resumption the accepted task is: port the completed Web `KRobotHead` to
Flutter with matching appearance, all microinteractions, consumer-controlled
audio and matching Widgetbook demos. Human visual acceptance is still required.
The former 60% Codex quota stop rule was explicitly revoked by the user.

## Repository and rules

- Workspace: `D:/Development/k-design-system`, PowerShell on Windows.
- Branch: `main`, HEAD `1d71d496e02046a5bfa696fae84907024031ccf1`.
- Main was pulled with `git pull --ff-only origin main` before Web implementation.
  Do not reset or blindly pull over the current uncommitted work.
- Skillset CLI: `D:/Development/tools/skillset.exe`; repository `.skillset` absent.
- Local collaboration, governed by repository AGENTS.md and
  `skillset ref read repository/local-development`.
- Loaded this turn: `dk-implement`, `repository/verification`,
  `coding/file-structure`, `repository/document-operations`.
- `README.md` and `docs/plans/0001-incremental-bootstrap.md` read.
- `pnpm verify` is required at the integrated finish. No visual baseline changes
  just to pass. Tokens/consumer API/platform behavior must remain explicit.
- Doc CLI supports outline/read/update, not creation; this new handover was
  created with the file tool. For later existing Markdown edits use supported
  Skillset dry-run/fingerprint/apply operations.

## Web implementation: complete, preserved, uncommitted

Source and documentation:

- `docs/plans/2026-10-15-robot-heads-cross-platform.md`: full research and Web scope.
- `docs/components/robot-head.md`: consumer contract, lifecycle and test evidence.
- `packages/web/ui/src/data-display/robot-head.tsx`: React wrapper.
- `packages/web/ui/src/data-display/robot-head-audio.ts`: audio frame/read API.
- `packages/web/ui/src/data-display/robot-head-engine/`: pinned upstream engine.
- `packages/web/ui/src/data-display/robot-head.css`: focus styling.
- `packages/web/ui/LICENSE.robot-heads`: MIT notice included in package files.
- `packages/web/ui/test/robot-head.test.mjs`: four focused tests.
- `apps/storybook/src/robot-head.stories.tsx`,
  `robot-head-audio-fixture.tsx`, `robot-head-fixture.css`: demos.
- Modified index/package/styles exports and docs catalog/plan index are expected.

Upstream is Fayaz Ahmed's robot-heads, pinned to
`58ebf6439a8125a769f63b22ffd35bc18834b1b5` (v0.3.0):
https://github.com/fayazara/robot-heads
and https://robot-heads.fayaz.workers.dev/.
Vendored engine retains geometry, lighting, textures, faces and simulation;
K changes add audio modulation, bounded caches and lifecycle handling.

Web URLs after restarting Storybook:

- http://localhost:6006/?path=/story/data-display-robothead--playground
- http://localhost:6006/?path=/story/data-display-robothead--controls
- http://localhost:6006/?path=/story/data-display-robothead--states
- http://localhost:6006/?path=/story/data-display-robothead--shapes
- http://localhost:6006/?path=/story/data-display-robothead--audio

### Existing evidence, before Flutter edits

- `pnpm verify` passed exit 0; log `.dart_tool/robot-head-verify.log`.
  Includes builds, generation, typechecks, 111 tooling tests, Flutter UI 575
  tests, Widgetbook 127 tests, consumer checks and tree-shaking (KButton 2,480 B).
- `node --test packages/web/ui/test/robot-head.test.mjs`: four passed.
- Browser: actual local WAV selection/playback, audio-driven mouth and equalizer,
  keyboard one activation per Enter/Space, shape/color switching, reduced motion.
- Two screenshots of a paused head were byte-identical (actual freeze).
- Desktop/light and mobile 390×844/dark inspected; Widgetbook root loaded.
- No native RobotHead visual or performance evidence exists yet.
- Old full-suite evidence does **not** verify the new partial Dart files.

## Flutter: exact saved checkpoint

Only these three new files were added during this turn, all first-pass,
**unformatted, unanalyzed and untested**:

1. `packages/flutter/k_design_ui/lib/src/data_display/robot_head/types.dart`
   - `KRobotHeadShape`: rectangle, square, circle, hexagon.
   - `KRobotHeadState`: idle, thinking, searching, listening, speaking, working,
     happy, error, sleeping.
2. `packages/flutter/k_design_ui/lib/src/data_display/robot_head/faces.dart`
   - Nine face algorithms and state lights, `cols=22`, `rows=14`, `FaceParams`,
     `Grid`/`Float32List`, `makeGrid`, maps `faces` and `lights`, `StateLight`.
   - JS-compatible rounding via floor(x + .5); optional audioLevel/audioBands.
   - `Grid.ox/oy` integers because grid expansion is even.
   - Audit nullable `FaceParams.copyWith`: currently cannot explicitly clear
     nullable audio fields; wrapper should clear mutable fields directly or fix
     semantics if copyWith needs to clear them.
3. `packages/flutter/k_design_ui/lib/src/data_display/robot_head/geometry.dart`
   - First-pass shapes/SDF/path, transforms, body/lathe meshes, ears/collar caches.
   - Known broken import: currently `import '../robot_head.dart';` must point to
     same-directory `types.dart` (verify before correction).

Nothing is exported into the public Dart library yet. Widgetbook has no
RobotHead entry yet. No Flutter wrapper, simulation, renderer, audio helper,
gallery files or tests were created. No pubspec/lock changes were made this turn.

## Implementation contracts agreed between workers

These are planned interfaces, not implemented public promises yet. Preserve Web
behavior and avoid introducing arbitrary differences.

### Engine

- `RobotSim(double seed, KRobotHeadState state)` with state/shown/previous,
  switched/age/time/since, `RobotPose pose`, `FaceParams face`, `Offset? pointer`;
  setState/poke/hop/update and top-level restPose.
- RobotPose: yaw, pitch, roll, x, lift, sx, sy, antennaX, antennaZ.
- Port JS uint32/Math.imul RNG exactly, including Dart JS compiler behavior.
- `getShape(KRobotHeadShape)` and `frameFor(shape, antenna, box)`.
- Frame doubles: box, padTop, padBottom, padSide, unit, cx, cy.
- `RobotRenderer({VoidCallback? onInvalidate})` and `dispose()`; async texture
  images must trigger repaint and be disposed/cached with bounds.
- Suggested draw contract: `draw(Canvas, Frame, double dpr, RobotPose,
RobotSim?, KRobotHeadState, Shape, Palette, RenderOptions)`.
- Canvas uses logical coordinates; do not multiply global Canvas coordinates by
  DPR as if it were an HTML backing canvas. DPR may control baked texture density.
- Preserve original rolled shell, ears, screws/vents, recessed glass, grain,
  LED grid, additive bloom, antenna springs and floor shadow. No WebView and no
  approximate replacement drawing.
- Parent wrapper can translate `-padSide,-padTop` inside a resting square while
  rendering the padded frame, preserving deliberate overflow for hops/glow.
- Ported large upstream modules may retain boundaries as documented vendor-port
  exceptions; split new handwritten responsibilities coherently below 500 lines.

### Public Flutter wrapper to create

Suggested `lib/src/data_display/k_robot_head.dart`, exported from k_design_ui:

- shape/state enums above, size default 160 (16–1024), seed 0…1.
- Color color/trimColor/screenColor; default artwork #2b49a3/#93a6c8/#e8f2ff,
  matching Web; externally overrideable, focus styles from existing DS tokens.
- speed capped 4; paused truly freezes current frame; reducedMotion honors OS
  and disables reactions; interactive controls auto tracking/reaction only.
- antenna/floorShadow independent options.
- normalized `Offset? target` (-1…1, x right/y down) plus `trackPointer=true`;
  external target wins, false + null disables tracking.
- `audio: KRobotHeadAudioFrame?` and/or
  `audioSource: KRobotHeadAudioFrame? Function()?`.
- `KRobotHeadAudioFrame(level: double, bands: List<double>?)`, finite normalized
  0…1; absence uses synthetic face animation, supplied silence stays silence.
- Attack 35 ms/release 90 ms smoothing in real frame time, independent of speed.
- `KRobotHeadController.react(): bool`, `.reset()`.
- onActivate/onReactionStart/onReactionEnd and semanticsLabel.
- One activation per click/touch/Enter/Space; paused/reduced still activates,
  but does not react. Reaction lasts 1.6 simulation seconds; repeated calls
  extend without duplicate start; reset/dispose cancels without end event.
- Repaint via Listenable/CustomPainter, not per-frame widget builds; pause for
  app lifecycle/TickerMode/offscreen where possible and release listeners/caches.
- No component-owned media playback, microphone permission or stream ownership.

### Widgetbook demo to create

Worker inspected current controls and Web fixtures but made **no edits**.

- `apps/widgetbook/lib/robot_head_fixture.dart`, cohesive audio/parser files,
  focused tests, minimal main.dart import and RobotHead use cases.
- Match playground/states/shapes/audio fixture IDs and controls; small phone
  layouts use scrolling and wrapping without overflow.
- Existing `audioplayers: 6.8.1` in Widgetbook. Official `file_selector: ^1.1.0`
  was researched and is compatible with repo Flutter 3.44/Dart 3.12 and supports
  Windows/Android/iOS/Web. It has **not** been added or installed.
- Candidate demo implementation: local uncompressed PCM WAV chooser,
  RIFF fmt/data parsing, RMS/bands sampled at actual playback position via
  AudioPlayer and BytesSource; reject unsupported compression explicitly.
  This WAV-only demo is a proposed implementation shortcut, **not** a user
  decision to restrict the public audio API or all Flutter media support.
  Evaluate before finalizing; don't silently present it as full Web format parity.
- Silence when paused/seeking/ended; dispose streams/player/blob resources.
- Consumer frame API remains independent of file format/playback library and
  supports streams or live measurements supplied by consuming apps.

## Resume sequence

1. Read this handover and `git status`; preserve all Web and partial Flutter work.
2. Fix the saved geometry import, inspect/format/analyze faces/types/geometry.
3. Finish exact sim/light/render/texture ports with numeric fixtures from the
   pinned JS source. Wrapper can proceed against the agreed contracts.
4. Add wrapper exports, native MIT attribution, focused lifecycle/interaction/
   audio tests and Widgetbook demos. Do not claim pixel parity from numeric tests.
5. Restart galleries, show actual RobotHead story/usecase, compare same shape,
   palette, size, seed, time/pose and target at identical viewport. Test audio.
6. Verify native Windows or Android as well as Widgetbook Web preview. User's
   actual Flutter targets are Windows, Android and iOS; Web preview alone is not
   native evidence. iOS cannot be validated on this Windows host.
7. Run integrated checks including `pnpm verify`, update consumer docs and
   evidence, return working links for user visual acceptance. No auto commit/push.

## Gallery restart and tool notes

Before restart Storybook was on 6006 and Widgetbook on 6007. Processes/session
IDs and browser bindings must be treated as stale after reboot.

```powershell
# From repository root
pnpm storybook

# Separate process, working directory apps/widgetbook
flutter run -d web-server --web-port 6007 --web-hostname 127.0.0.1
```

Open Storybook RobotHead URLs above and http://127.0.0.1:6007/ in separate Codex
browser tabs. Use the CUA API documentation before browser interaction; after a
context summary call `await cua.rewriteDocumentation()` if continuing an existing
CUA session. Fresh sessions follow the first-call entry-point rule.

Ignored useful artifacts remain in `.dart_tool/`:

- `robot-head-reference-58ebf643/`: raw pinned upstream source.
- `robot-head-audio-test.wav`: generated 12-second mono WAV, silence at ends,
  amplitude-modulated 220/660 Hz in the middle.
- `robot-head-verify.log`: passing pre-Flutter full suite.

The active Codex tab showing DiceBear/Widgetbook does not change this task:
the accepted component is **KRobotHead**, not another DiceBear change.
