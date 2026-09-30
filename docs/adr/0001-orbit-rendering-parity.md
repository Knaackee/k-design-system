---
status: superseded
date: 2026-09-29
decision-makers: []
supersedes:
superseded-by: 0002
---

# 0001 Deterministic Orbit rendering across Web and Flutter

## Status

Proposed; requires Human Approval with the Orbit implementation plan.

## Context

Website reference uses Three.js geometry/shading plus SVG and HTML. KOrbit must
provide the same configurable levels, camera, animated communication, filtering
and accessible interaction on React and Flutter. The current library has neither
Three.js nor a Flutter 3D engine. Flutter FragmentProgram supports fragment shaders,
not direct reuse of the reference vertex shader and varying inputs.

## Decision proposed

Implement an orthographic projected scene with matching pure TS and Dart math.
Use Canvas2D / CustomPainter for sampled orbit segments and connection curves;
existing icon/avatar/text primitives provide accessible screen-space node content.
Depth-aware segment splitting and ordering handle center occlusion consistently.
Use an analytic sphere surface in a small GLSL fragment shader, with WebGL and
Flutter runtime-effect entry wrappers. Share lighting, noise, palette and time
semantics. Keep the shader source/formulas together with parity test vectors;
reuse existing token generation for platform projections. No independent visual
implementation decisions in the two renderers.

Node hierarchy is consumer-owned metadata using IDs/parentId and levelId. Visual
levels share one center in V1; recursive sub-orbits, physics simulation, graph
editing and backend communication are outside this accepted proposal.
Communication is visualized from explicit directed edges/activity input.

Use a single clock: level period and global multiplier determine angular motion;
view orientation/zoom is separate from orbital phase. Stable IDs determine
phase continuity through updates and token-timed entry/exit interpolation.

## Alternatives

Three.js plus a Flutter 3D package: convenient Web reference reuse, but two
unrelated renderers and dependency stacks do not establish parity; unnecessary
for circles, curves and a sphere. Revisit only for actual meshes/perspective.
WebView on Flutter: same browser renderer but poor native semantics, gestures,
packaging and offline expectations; rejected.
Rive/pre-rendered animation: useful fixed artwork, but arbitrary consumer levels,
nodes and edges do not fit a fixed authored scene; rejected for the core.
Flat gradients alone: smaller, but do not meet the reference material quality;
allowed only as a documented shader-unavailable fallback, not the default result.

## Consequences and proof before expansion

No new renderer dependency, but small projection and gesture implementations in
two languages need shared numerical vectors and screenshot comparisons.
A two-platform renderer spike must demonstrate sphere material, inclined rings,
occlusion and fixed-time communication on browser, Widgetbook and Android.
If material/performance parity fails, stop and propose a revised renderer decision
before full implementation. No claim of bit-identical GPU rasterization.

Keep accessible nodes functional on shader error/context loss. Respect motion
preferences and hidden/offscreen lifecycle. Validate scene inputs before drawing.
Final acceptance and verification are defined in the Orbit plan.

## Sources

https://docs.flutter.dev/ui/design/graphics/fragment-shaders
https://api.flutter.dev/flutter/rendering/CustomPainter-class.html
https://threejs.org/docs/pages/WebGLRenderer.html
D:/Development/KNAACK.IT-WEBSITE/app/public/orbit/orbit.js
D:/Development/KNAACK.IT-WEBSITE/app/public/orbit/orbit-rotation.js
D:/Development/KNAACK.IT-WEBSITE/app/public/orbit/orbit-connections.js
