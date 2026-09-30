---
status: accepted
date: 2026-09-29
decision-makers: []
supersedes: 0001
superseded-by:
---

# 0002 Nested Orbit hierarchy and parity

## Decision

This supersedes ADR 0001's restriction to concentric levels around one center.
The user explicitly clarified nested team -> projects -> issues -> agents/people
and approved implementation with "go, rapid, go!" on 2026-09-29. Other renderer,
accessibility, token, and consumer-control decisions in ADR 0001 remain applicable.

`parentId` is a spatial anchor. A node's world position is its parent's position
plus its local orbit vector. `levelId` describes that local orbit's radius,
inclination, azimuth, period and direction. Parented nodes require a level;
cycles and missing anchors are rejected. Unique (parentId, levelId) pairs draw
one moving track each. Nodes without a parent retain the shared scene origin.

Local coordinates are (r*cos(a), r*sin(a)*cos(i), r*sin(a)*sin(i)), rotated about
Z by azimuth. The summed world coordinate is rotated about X by camera pitch,
then Y by camera yaw; screen Y is negated. Default yaw/pitch are zero. Scene
extent is the maximum sum of radii along a parent chain. Scale is
max(1, min(width,height)-64)/(2*extent)*zoom. Explicit periods win; the default
is 18*(radius/maxLevelRadius)^1.5 seconds. Zoom bounds default to 0.65..2.2.

Every node, including the center, supports idle/active/question/error status,
consumer status text, optional pulse and configurable pulse period. Appearance
comes from tokens; reduced motion keeps a static indicator. Communication is
explicitly triggered, with paths visible while signals run unless configured
otherwise. Selection events continue to be consumer-owned.

Web Canvas/WebGL and Flutter CustomPainter/runtime shaders share geometry,
material equations, timing, signal sizing, and camera gestures. `elapsedSeconds`
allows fixed-time previews. Shared numerical fixtures and browser screenshots
must demonstrate nested anchoring and rendering parity. GPU rasterization is
not promised bit-identical. Visual acceptance remains with the user.

## Scope and verification

Allowed paths are the Orbit component implementations, shaders, matching gallery
fixtures, focused tests, Orbit tokens/generated projections, and this evidence.
No website reference edits, new renderer dependency, commit or push is authorized.
Use focused model/widget tests, type/analyzer/style checks, and live screenshots
at matching dimensions/time/camera. Preserve approved historical documents.
