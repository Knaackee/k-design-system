# KRobotHead

Web and Flutter review candidate, 15 October 2026. Both galleries contain the
component; human visual acceptance remains pending.

## Source and scope

Canvas renderer adapted from Fayaz Ahmed's MIT-licensed
[robot-heads](https://github.com/fayazara/robot-heads/tree/58ebf6439a8125a769f63b22ffd35bc18834b1b5),
commit `58ebf6439a8125a769f63b22ffd35bc18834b1b5`. The engine is vendored so the
audio extension can modify the actual LED mouth and equalizer; a React wrapper
around the published package cannot access those internals. The package ships
`LICENSE.robot-heads`. There is no remote service, runtime asset download or new
runtime dependency.

The vendored geometry, lighting, simulation and renderer intentionally retain
their upstream module boundaries, including files above 500 lines. K changes:
ESM import extensions, formatting, optional audio face/antenna parameters and a
bounded texture cache. The shared ticker and React lifecycle are K-owned. Keep
the upstream source pin when porting the engine to Flutter.

## Consumer API

```tsx
import { KRobotHead, type KRobotHeadHandle } from "@k-design-system/ui";
import { useRef } from "react";

function AssistantAvatar() {
  const robot = useRef<KRobotHeadHandle>(null);
  return (
    <KRobotHead
      ref={robot}
      state="listening"
      shape="rectangle"
      size={160}
      seed={0.42}
      aria-label="Open assistant"
      onActivate={() => openAssistant()}
    />
  );
}
```

- Shapes: `rectangle`, `square`, `circle`, `hexagon`.
- States: `idle`, `thinking`, `searching`, `listening`, `speaking`, `working`,
  `happy`, `error`, `sleeping`. Working progress is decorative, not task progress.
- `size`: resting layout square, clamped to 16–1024 CSS pixels (default 160).
  Hops, shadow and glow overflow the square; avoid clipping parent containers.
- `color`, `trimColor`, `screenColor`: CSS colors, including CSS variables.
  Optional scoped overrides `--k-robot-head-color`, `--k-robot-head-trim-color`,
  `--k-robot-head-screen-color` retain the upstream artwork colors as fallbacks.
  Focus styling uses existing design tokens; the gallery uses existing controls.
- `speed`: animation-time multiplier, capped at 4; zero/negative stops animation.
  `paused` freezes the current pose rather than returning to the upstream rest
  pose. Pausing the robot does not pause consumer-owned media.
- `reducedMotion`: rest pose, no click reaction. The OS preference is always
  respected and updates live. Activation events still work.
- `interactive`: automatic pointer/touch tracking and click reaction. It does not
  disable autonomous movement or consumer activation callbacks.
- `target`: omitted uses the document pointer; `null` disables tracking; an
  object `{x, y}` supplies a consumer-owned normalized target in -1…1. External
  targets take precedence. Positive X points right; positive Y points down.
  The original tracking states remain idle/listening/speaking/happy. No camera or
  face tracking is included. Touch end/cancel clears the automatic target.
- `antenna`, `floorShadow`: independent visual options. As upstream, disabling
  the antenna retains its knob and reframes the head.
- `seed`: 0…1. A new seed resets the deterministic simulation. Identical seed
  alone does not imply identical frames across different input/timestep sequences.
- `onActivate`: once per mouse, touch, Enter or Space activation. `onClick` can
  prevent default to suppress reaction and activation. Interactive heads are
  focusable buttons; passive heads without callbacks use image semantics.
- Ref `react()` triggers the same temporary happy reaction; returns false when
  motion is stopped/reduced. `reset()` restores time/seed and cancels a reaction.
  `onReactionStart` fires once for a reaction; repeated triggers extend it.
  `onReactionEnd` fires on completion in simulation time, not on reset/unmount.

Hidden documents and offscreen heads stop ticking. Texture caches are bounded.
Native GPU performance and Web/Flutter pixel parity have not yet been measured.

## Real audio

`audio` accepts `{level, bands?}` or a function returning that object (or `null`
for silence). Values are normalized 0…1. A reader avoids React rerenders for each
sample. Omit `audio` to retain the original synthetic animation; `level: 0` is
real silence, not an instruction to fall back to synthetic motion.

The consumer owns playback, microphone permission, tracks, CORS, AudioContext,
graph connections and disposal. The component never opens a microphone or plays
audio. The same analyser can be fed by a media file, streamed playback or a
MediaStream. Use a read function that returns silence when paused, ended,
buffering, disconnected or seeking, rather than feeding stale analyser samples.

```tsx
import { createKRobotHeadAudioReader, KRobotHead } from "@k-design-system/ui";

// In a user-initiated consumer setup, once per HTMLMediaElement:
const context = new AudioContext();
const source = context.createMediaElementSource(audioElement);
const analyser = context.createAnalyser();
analyser.fftSize = 1024;
source.connect(analyser);
analyser.connect(context.destination);
const sample = createKRobotHeadAudioReader(analyser, {
  gain: 3,
  bandCount: 12,
});
const read = () =>
  audioElement.paused || audioElement.ended ? { level: 0 } : sample();

// Resume the AudioContext and play in response to a user gesture.
// Dispose your source/analyser/context when the consumer unmounts.
<KRobotHead state="speaking" audio={read} aria-label="Assistant speaking" />;
```

`speaking` uses a smoothed amplitude envelope for mouth opening and antenna
brightness. `listening` uses optional frequency bands for its equalizer, falling
back to the envelope if bands are absent. This is audio-reactive animation, not
phoneme recognition or lip synchronization. Audio sampling uses real frame time,
independent of the robot's animation-speed multiplier.

## Review and verification

Storybook: `Data Display/RobotHead` → Playground, Controls, States, Shapes, Audio.
Audio includes a local file chooser, native playback/pause/seeking and a switch
back to synthetic motion. Files use local blob URLs, never network uploads.

Focused checks: Web build, Storybook typecheck, `node --test
packages/web/ui/test/robot-head.test.mjs`, style audit, browser interaction and
local WAV playback. Full repository verification is recorded in the execution
handoff; this document does not mark unperformed checks as passed.

### Execution evidence — 15 October 2026

Baseline: main at `1d71d49`, plus the uncommitted Web-first working tree. No commit or push was requested or performed.

- `pnpm verify`: passed (exit 0). Includes formatting, generation/drift checks, 111 tooling tests, style audit, Web builds/typechecks, Web consumer/tree-shaking, Flutter consumer analysis/tests/release build, workspace Flutter analysis/tests and both gallery production builds. KButton-only bundle remains 2,480 bytes. Flutter UI: 575 tests; Widgetbook: 127 tests.
- `node --test packages/web/ui/test/robot-head.test.mjs`: 4 passed. Covers all 36 shape/state SSR combinations, accessibility semantics, real silence versus loud mouth/equalizer input, analyser RMS/gain/FFT resizing, seed determinism and reaction return to the consumer state.
- Browser: local 12-second generated WAV selected through the actual file chooser; blob URL confirmed, playback time advanced, status showed Audio läuft, and the equalizer mode switched during playback. No warning/error console entries in the test tab.
- Browser: Enter and Space each produced one consumer activation. Color and hexagon form switched visibly. Reduced-motion and pause/resume controls exercised. Two cropped screenshots of the paused head were byte-identical, confirming actual frame freeze.
- Responsive inspection: Audio story checked at 390 × 844 and desktop width in dark mode; light-mode Playground also inspected. Viewport override restored afterward. Storybook and existing Widgetbook both loaded in Codex browser tabs.

New handwritten source remains below 500 lines per file (largest component: 417 lines); the large pinned upstream engine modules are the documented vendored-source exception. Consumer documentation and scope notes were updated after the full suite; only Markdown formatting changed afterward. Native RobotHead parity, native performance and human visual acceptance remain pending. Next action: user reviews Playground/Audio in Storybook, then authorizes any adjustments or the Flutter port.

### Flutter implementation — 15 October 2026

The user subsequently authorized the Flutter port. `KRobotHead` is exported from
`package:k_design_ui/k_design_ui.dart`; it renders with native Canvas/CustomPainter,
not a WebView. Geometry, lighting, face grids and seeded motion use the same
calculations as Web. All four shapes and nine states are supported.

Consumer controls include `shape`, `state`, `size`, `speed`, `seed`, `color`,
`trimColor`, `screenColor`, `antenna`, `floorShadow`, `paused`, `reducedMotion`,
`interactive`, `trackPointer`, and normalized `Offset? target`. Use
`KRobotHeadController.react()` / `reset()` for imperative reactions and
`onActivate`, `onReactionStart`, `onReactionEnd` for events. Pointer tracking
accepts mouse and touch; an explicit target overrides it. Accessibility settings
and app/ticker lifecycle suspend motion appropriately.

For audio, pass `KRobotHeadAudioFrame(level: ..., bands: ...)` through `audio`,
or supply an `audioSource` getter. The consumer owns playback, microphone access,
and analysis; the UI package opens no microphone and fetches no media. Explicit
silence differs from absent audio, which enables synthetic animation. The native
Widgetbook Audio fixture demonstrates local uncompressed PCM WAV playback with
RMS and frequency analysis; this demo format restriction does not limit the
component's frame API.

Widgetbook: Data display / RobotHead / robot-head-playground, robot-head-states,
robot-head-shapes, robot-head-audio. Native rendering has a bounded relief cache
and disposes cached raster images when the final renderer is removed.

Focused verification: seven Dart tests compare simulation, faces, geometry and
lighting with JavaScript numeric fixtures; four widget tests exercise rendering,
keyboard/tap callbacks, reactions and lifecycle; three WAV parser tests pass.
These checks establish algorithmic agreement, not identical GPU rasterization
or native-device performance. Final visual acceptance remains with the user.

Restart verification: the repository verification run passed 586 UI tests, 131 Widgetbook tests, analysis, Web builds, consumer builds and tree-shaking checks. Its final Widgetbook build caught a transient renderer edit; the corrected release build passed separately. After the final compositing correction, the 11 focused RobotHead tests and renderer analysis passed again. Storybook and Widgetbook were opened in the Codex browser. Native device performance and human pixel-parity acceptance remain pending. The renderer caches premultiplied raster textures and isolates additive glow from the parent surface.

### Recovery on current main — 10 November 2026

Recovered the Web and Flutter component, gallery fixtures, tests, upstream notices,
and original plan/handover from local stash a0e1119. The untracked snapshot matches
the earlier ea41c43 stash. Both stashes remain untouched and a verified local Git
bundle preserves their history. Current main was fast-forwarded to 57c9468 before
integration; no newer main changes were replaced.

The public exports, CSS entry, Widgetbook registration and audio file-selector
integration are restored. RobotHead Web tests now run in the standard verification
pipeline. Gallery controls use current K controls, including a single labelled
switch and tokenized Flutter layout. The recovered native performance benchmark
is retained; this recovery does not claim to resolve its device CPU/frame-time
issues. Native performance and final human visual acceptance remain separate.
