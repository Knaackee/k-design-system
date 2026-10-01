import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { drawKOrbit } from "../../../packages/web/ui/dist/data-display/orbit/orbit-draw.js";
import {
  KOrbitController,
  kOrbitDefaultView,
} from "../../../packages/web/ui/dist/data-display/orbit/orbit-model.js";
import {
  layoutKOrbitLabels,
  resolveKOrbitPointerNode,
  isKOrbitNodeOccluded,
} from "../../../packages/web/ui/dist/data-display/orbit/orbit-label-layout.js";
import {
  kOrbitConnectionPoint,
  kOrbitLevelPeriod,
  kOrbitSceneExtent,
  kOrbitZoomAt,
  projectKOrbitPoint,
  projectKOrbitScene,
  validateKOrbit,
} from "../../../packages/web/ui/dist/data-display/orbit/orbit-model.js";

const level = {
  id: "outer",
  label: "Outer",
  radius: 2,
  inclination: 0.3,
  azimuth: -0.2,
  periodSeconds: 20,
};

test("follow extent includes complete descendant orbits but excludes ancestors and siblings", () => {
  const levels = [
    { id: "projects", radius: 500 },
    { id: "issues", radius: 100 },
    { id: "agents", radius: 30 },
  ];
  const nodes = [
    { id: "w", radius: 28 },
    { id: "p", parentId: "w", levelId: "projects", radius: 18 },
    { id: "i", parentId: "p", levelId: "issues", radius: 13 },
    { id: "a", parentId: "i", levelId: "agents", radius: 9 },
  ];
  assert.equal(kOrbitSceneExtent(levels, nodes), 639);
  assert.equal(kOrbitSceneExtent(levels, nodes, "p"), 139);
  assert.equal(kOrbitSceneExtent(levels, nodes, "i"), 39);
  assert.equal(kOrbitSceneExtent(levels, nodes, "a"), 9);
});
const parityFixture = JSON.parse(
  readFileSync(new URL("./orbit-parity.fixture.json", import.meta.url), "utf8"),
);

test("Orbit validation rejects missing endpoints and parent cycles", () => {
  assert.throws(
    () =>
      validateKOrbit(
        [level],
        [{ id: "a", label: "A", levelId: "outer", parentId: "a" }],
        [],
      ),
    /parent cycle/,
  );
  assert.throws(
    () =>
      validateKOrbit(
        [level],
        [{ id: "a", label: "A" }],
        [{ id: "c", sourceId: "a", targetId: "missing" }],
      ),
    /missing endpoint/,
  );
  assert.throws(
    () =>
      validateKOrbit(
        [level],
        [
          { id: "parent", label: "Parent" },
          { id: "child", label: "Child", parentId: "parent" },
        ],
        [],
      ),
    /must reference a level/,
  );
  assert.throws(
    () =>
      validateKOrbit([level], [{ id: "a", label: "A", pulsePeriodMs: 0 }], []),
    /pulsePeriodMs/,
  );
});

test("Orbit projection, curve progress and focal zoom stay deterministic", () => {
  const point = projectKOrbitPoint(
    level,
    0.7,
    2,
    kOrbitDefaultView,
    800,
    600,
    2,
  );
  assert.deepEqual(
    Object.values(point).map((value) => Number(value.toFixed(6))),
    [512.443756, 69.19818, 0.286875],
  );
  const midpoint = kOrbitConnectionPoint(
    { x: 0, y: 0, depth: -1 },
    { x: 100, y: 0, depth: 1 },
    0.5,
  );
  assert.deepEqual(midpoint, { x: 50, y: 9, depth: 0 });
  const zoomed = kOrbitZoomAt(
    kOrbitDefaultView,
    2,
    { x: 300, y: 200 },
    { x: 200, y: 150 },
  );
  assert.deepEqual(zoomed.offset, { x: -100, y: -50 });
});

test("Orbit recursively anchors child positions and only creates used rings", () => {
  const levels = [
    { id: "parent", label: "Parent", radius: 100, periodSeconds: 20 },
    { id: "child", label: "Child", radius: 50, periodSeconds: 20 },
    { id: "unused", label: "Unused", radius: 200, periodSeconds: 20 },
  ];
  const nodes = [
    { id: "root", label: "Root" },
    { id: "parent", label: "Parent", levelId: "parent", phase: 0 },
    {
      id: "child",
      label: "Child",
      parentId: "parent",
      levelId: "child",
      phase: Math.PI / 2,
    },
  ];
  const scene = projectKOrbitScene(
    levels,
    nodes,
    kOrbitDefaultView,
    0,
    600,
    400,
  );
  assert.equal(kOrbitSceneExtent(levels, nodes), 150);
  assert.equal(
    kOrbitLevelPeriod({ id: "derived", label: "Derived", radius: 50 }, 100),
    60,
  );
  assert.deepEqual(scene.points.get("root"), { x: 300, y: 200, depth: 0 });
  assert.deepEqual(scene.points.get("parent"), {
    x: 412,
    y: 200,
    depth: 0,
  });
  assert.deepEqual(scene.points.get("child"), {
    x: 412,
    y: 144,
    depth: 0,
  });
  assert.deepEqual(
    scene.rings.map(({ parentId, level, anchor }) => ({
      parentId,
      levelId: level.id,
      anchor,
    })),
    [
      {
        parentId: undefined,
        levelId: "parent",
        anchor: { x: 0, y: 0, z: 0 },
      },
      {
        parentId: "parent",
        levelId: "child",
        anchor: { x: 100, y: 0, z: 0 },
      },
    ],
  );
});

test("Planet sizes are independent of hierarchy and nested systems follow moving parents", () => {
  const levels = [
    { id: "planet", label: "Planet", radius: 100, periodSeconds: 40 },
    { id: "moon", label: "Moon", radius: 35, periodSeconds: 10 },
    { id: "satellite", label: "Satellite", radius: 12, periodSeconds: 3 },
  ];
  const nodes = [
    { id: "root", label: "Root", radius: 10 },
    {
      id: "planet",
      label: "Planet",
      parentId: "root",
      levelId: "planet",
      radius: 20,
    },
    {
      id: "moon",
      label: "Moon",
      parentId: "planet",
      levelId: "moon",
      radius: 5,
    },
    {
      id: "satellite",
      label: "Satellite",
      parentId: "moon",
      levelId: "satellite",
      radius: 2,
    },
  ];
  for (const time of [0, 2, 7, 19]) {
    const scene = projectKOrbitScene(
      levels,
      nodes,
      kOrbitDefaultView,
      time,
      600,
      600,
    );
    assert.equal(scene.radii.get("planet"), scene.radii.get("root") * 2);
    for (const node of nodes.slice(1)) {
      const child = scene.points.get(node.id),
        parent = scene.points.get(node.parentId);
      const orbit = levels.find(({ id }) => id === node.levelId);
      assert.ok(
        Math.abs(
          Math.hypot(child.x - parent.x, child.y - parent.y) -
            orbit.radius * scene.scale,
        ) < 1e-9,
      );
      const ring = scene.rings.find(
        ({ parentId }) => parentId === node.parentId,
      );
      assert.ok(Math.abs(ring.anchor.x * scene.scale + 300 - parent.x) < 1e-9);
      assert.ok(Math.abs(300 - ring.anchor.y * scene.scale - parent.y) < 1e-9);
    }
  }
  assert.throws(
    () => validateKOrbit(levels, [{ id: "bad", label: "Bad", radius: -1 }], []),
    /radius/,
  );
  const scene = projectKOrbitScene(
    levels,
    nodes,
    kOrbitDefaultView,
    0,
    600,
    600,
  );
  scene.points.set("moon", { ...scene.points.get("planet"), depth: -1 });
  assert.equal(isKOrbitNodeOccluded("moon", scene), true);
  assert.equal(isKOrbitNodeOccluded("planet", scene), false);
});

test("The renderer paints every planet at its projected position and size", () => {
  const levels = [
    { id: "orbit", label: "Orbit", radius: 100, inclination: 0.5 },
  ];
  const nodes = [
    { id: "root", label: "Root", radius: 15 },
    {
      id: "front",
      label: "Front",
      parentId: "root",
      levelId: "orbit",
      radius: 25,
      phase: Math.PI / 2,
    },
    {
      id: "back",
      label: "Back",
      parentId: "root",
      levelId: "orbit",
      radius: 10,
      phase: -Math.PI / 2,
    },
  ];
  const scene = projectKOrbitScene(
    levels,
    nodes,
    kOrbitDefaultView,
    0,
    400,
    400,
  );
  const context = new Proxy({}, { get: () => () => {} });
  const palette = new Proxy(
    {},
    { get: (_, key) => (key === "centerRadiusRatio" ? 0.296 : 1) },
  );
  const painted = [];
  drawKOrbit(
    context,
    { width: 400, height: 400 },
    levels,
    nodes.map((node) => ({ ...node, appearance: "sphere" })),
    [],
    [],
    kOrbitDefaultView,
    0,
    palette,
    false,
    true,
    undefined,
    undefined,
    (node, point, radius) => {
      painted.push(node.id);
      assert.deepEqual(point, scene.points.get(node.id));
      assert.equal(radius, scene.radii.get(node.id));
      return true;
    },
  );
  assert.deepEqual(painted, ["back", "root", "front"]);
});

test("Orbit camera rotation matches the shared parity fixture", () => {
  const scene = projectKOrbitScene(
    [
      {
        id: "camera",
        label: "Camera",
        radius: 100,
        inclination: Math.PI / 2,
        periodSeconds: 20,
      },
    ],
    [
      {
        id: "camera",
        label: "Camera",
        levelId: "camera",
        phase: Math.PI / 2,
      },
    ],
    {
      yaw: Math.PI / 2,
      pitch: 0,
      zoom: 1,
      offset: { x: 0, y: 0 },
    },
    0,
    400,
    400,
  );
  assert.deepEqual(scene.points.get("camera"), {
    x: 368,
    y: 200,
    depth: 0,
  });
});

test("Orbit matches every shared Web and Flutter numeric golden", () => {
  validateKOrbit(parityFixture.levels, parityFixture.nodes, []);
  for (const fixtureCase of parityFixture.cases) {
    const scene = projectKOrbitScene(
      parityFixture.levels,
      parityFixture.nodes,
      {
        yaw: fixtureCase.yaw,
        pitch: fixtureCase.pitch,
        zoom: 1,
        offset: { x: 0, y: 0 },
      },
      fixtureCase.time,
      parityFixture.size.width,
      parityFixture.size.height,
    );
    assert.equal(scene.sceneExtent, parityFixture.extent);
    assert.equal(scene.scale, parityFixture.scale);
    assert.ok(Math.abs(scene.centerRadius - parityFixture.centerRadius) < 1e-9);
    assert.equal(scene.rings.length, parityFixture.ringCount);
    for (const [id, expected] of Object.entries(fixtureCase.points)) {
      const actual = scene.points.get(id);
      assert.ok(actual, `missing projected node ${id}`);
      [actual.x, actual.y, actual.depth].forEach((value, index) =>
        assert.ok(
          Math.abs(value - expected[index]) < 1e-9,
          `${id}[${index}] expected ${expected[index]}, got ${value}`,
        ),
      );
    }
    if (fixtureCase.time === 1 && fixtureCase.yaw === 0) {
      const issueRing = scene.rings.find(({ level }) => level.id === "issues");
      const peopleRing = scene.rings.find(({ level }) => level.id === "people");
      assert.ok(issueRing && peopleRing);
      assert.ok(Math.abs(issueRing.anchor.x - Math.sqrt(50)) < 1e-9);
      assert.ok(Math.abs(issueRing.anchor.y - Math.sqrt(50)) < 1e-9);
      assert.ok(Math.abs(peopleRing.anchor.x - Math.sqrt(50)) < 1e-9);
      assert.ok(Math.abs(peopleRing.anchor.y - (Math.sqrt(50) + 3)) < 1e-9);
    }
  }
});

test("Web and Flutter center shaders keep the shared material block", () => {
  const web = readFileSync(
    new URL(
      "../../../packages/web/ui/src/data-display/orbit/orbit-shader.ts",
      import.meta.url,
    ),
    "utf8",
  );
  const flutter = readFileSync(
    new URL(
      "../../../packages/flutter/k_design_ui/shaders/orbit_center.frag",
      import.meta.url,
    ),
    "utf8",
  );
  const material = (source) =>
    source
      .match(
        /vec3 normal[\s\S]*?(?:gl_FragColor|fragColor) = vec4\(bronze \* alpha, alpha\);/,
      )?.[0]
      .replace("gl_FragColor", "fragColor")
      .replaceAll(/\s+/g, " ")
      .trim();
  assert.ok(material(web));
  assert.equal(material(web), material(flutter));
});

test("Orbit label placement follows shared priority and collision rules", () => {
  const nodes = [
    { id: "root", label: "Root" },
    { id: "z", label: "Selected", levelId: "level" },
    { id: "q", label: "Question", levelId: "level", status: "question" },
    { id: "a", label: "Active", levelId: "level", status: "active" },
    { id: "i", label: "Idle", levelId: "level" },
  ];
  const points = new Map(
    nodes.map((node) => [
      node.id,
      node.id === "root"
        ? { x: 100, y: 100, depth: 0 }
        : { x: 45, y: 45, depth: 0 },
    ]),
  );
  const placements = layoutKOrbitLabels({
    nodes,
    points,
    selectedId: "z",
    width: 200,
    height: 200,
    center: { x: 100, y: 100 },
    centerRadius: 25,
    nodeRadius: 12,
    labelOffset: 18,
    fontSize: 12,
    lineHeight: 16,
  });
  assert.deepEqual(
    [...placements].map(([id, placement]) => [id, placement.side]),
    [
      ["root", "center"],
      ["z", "right"],
      ["q", "below"],
      ["a", "above"],
      ["i", "hidden"],
    ],
  );
});

test("Orbit pointer resolution chooses the nearest circular hit or visible label", () => {
  const candidates = [
    { id: "atlas", x: 257, y: 143, radius: 22 },
    {
      id: "agent",
      x: 282,
      y: 124,
      radius: 22,
      label: { left: 300, top: 116, right: 350, bottom: 132 },
    },
  ];
  assert.equal(
    resolveKOrbitPointerNode({ x: 257, y: 143 }, candidates),
    "atlas",
  );
  assert.equal(
    resolveKOrbitPointerNode({ x: 325, y: 124 }, candidates),
    "agent",
  );
  assert.equal(
    resolveKOrbitPointerNode({ x: 20, y: 20 }, candidates),
    undefined,
  );
});

test("Orbit controller forwards transient signals without history", () => {
  const controller = new KOrbitController();
  const active = new Set();
  controller.bind({
    trigger(signal) {
      if (active.has(signal.id)) return "invalid";
      active.add(signal.id);
      return "accepted";
    },
    cancel(id) {
      return active.delete(id);
    },
    cancelAll() {
      active.clear();
    },
  });
  assert.equal(
    controller.triggerSignal({ id: "s1", connectionId: "c1" }),
    "accepted",
  );
  assert.equal(
    controller.triggerSignal({ id: "s1", connectionId: "c1" }),
    "invalid",
  );
  assert.equal(controller.cancelSignal("s1"), true);
  controller.dispose();
  assert.equal(
    controller.triggerSignal({ id: "s2", connectionId: "c1" }),
    "inactive",
  );
});

test("Presence grows with overshoot, shrinks in reverse and reverses without a jump", async () => {
  const { kOrbitPresenceScale } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-presence.js");
  const enter = { from: 0, to: 1, startedAt: 0, durationMs: 400 };
  assert.ok(Math.abs(kOrbitPresenceScale(enter, 0)) < 1e-12);
  assert.ok(kOrbitPresenceScale(enter, 250) > 1);
  assert.equal(kOrbitPresenceScale(enter, 400), 1);
  const exit = { from: 1, to: 0, startedAt: 0, durationMs: 400 };
  assert.equal(kOrbitPresenceScale(exit, 0), 1);
  assert.ok(kOrbitPresenceScale(exit, 100) > 1);
  assert.ok(kOrbitPresenceScale(exit, 350) < 0.6);
  assert.ok(kOrbitPresenceScale(exit, 400) < 1e-12);
  const interrupted = kOrbitPresenceScale(exit, 200);
  assert.ok(
    Math.abs(
      kOrbitPresenceScale(
        { ...enter, from: interrupted, startedAt: 200 },
        200,
      ) - interrupted,
    ) < 1e-12,
  );
  assert.equal(kOrbitPresenceScale({ ...enter, durationMs: 0 }, 0), 1);
});

test("Presence scales the actual painted planet and local signals draw without connections", () => {
  const nodes = [
    { id: "root", label: "Root", radius: 20, appearance: "sphere" },
  ];
  const scene = projectKOrbitScene([], nodes, kOrbitDefaultView, 0, 400, 400);
  const arcs = [];
  const context = new Proxy(
    {},
    {
      get: (_, key) =>
        key === "arc" ? (...args) => arcs.push(args) : () => {},
    },
  );
  const palette = new Proxy(
    {},
    { get: (_, key) => (key === "centerRadiusRatio" ? 0.296 : 1) },
  );
  let paintedRadius;
  drawKOrbit(
    context,
    { width: 400, height: 400 },
    [],
    nodes,
    [],
    [
      {
        nodeId: "root",
        progress: 0.5,
        style: "pings",
        sourcePing: false,
        arrivalPing: true,
      },
    ],
    kOrbitDefaultView,
    0,
    palette,
    false,
    true,
    undefined,
    undefined,
    (_, point, radius) => {
      paintedRadius = radius;
      return true;
    },
    new Map([["root", 0.5]]),
  );
  assert.equal(paintedRadius, scene.radii.get("root") * 0.5);
  assert.ok(
    arcs.some((arc) => arc[2] > paintedRadius + 3),
    "node-only signal creates its own ping outside the sphere",
  );
});

test("Flat nodes are the default: token surface, no shader, gradient or center glow", () => {
  const nodes = [{ id: "root", label: "Team", radius: 20, tone: "info" }];
  const fills = [];
  let shaderCalls = 0;
  const context = new Proxy(
    {},
    {
      get: (target, key) => {
        if (key === "createRadialGradient")
          throw new Error("Flat nodes must not use a material gradient");
        if (key === "fill") return () => fills.push(target.fillStyle);
        return () => {};
      },
    },
  );
  const palette = new Proxy(
    { nodeSurfaces: { info: "#172554" } },
    { get: (target, key) => (key in target ? target[key] : 1) },
  );
  drawKOrbit(
    context,
    { width: 400, height: 400 },
    [],
    nodes,
    [],
    [],
    kOrbitDefaultView,
    0,
    palette,
    true,
    true,
    undefined,
    undefined,
    () => {
      shaderCalls++;
      return true;
    },
  );
  assert.equal(shaderCalls, 0);
  assert.deepEqual(fills, ["#172554"]);
});

test("Each flat status has exactly one persistent contour", () => {
  const palette = {
    nodeSurfaces: { neutral: "surface" },
    nodeBorder: "border",
    primary: "primary",
    success: "success",
    warning: "warning",
    info: "info",
    error: "error",
    connectionWidth: 1,
    centerRadiusRatio: 0.296,
  };
  for (const [status, color] of [
    ["idle", "border"],
    ["active", "info"],
    ["question", "warning"],
    ["completed", "success"],
    ["error", "error"],
  ]) {
    const strokes = [];
    const context = new Proxy(
      {},
      {
        get: (target, key) =>
          key === "stroke" ? () => strokes.push(target.strokeStyle) : () => {},
      },
    );
    drawKOrbit(
      context,
      { width: 400, height: 400 },
      [],
      [{ id: "root", label: "Team", radius: 20, status }],
      [],
      [],
      kOrbitDefaultView,
      0,
      palette,
      true,
      true,
    );
    assert.deepEqual(strokes, [color], status);
  }
});

test("Motion caps effective speed per node and preserves phase across live changes", async () => {
  const { advanceKOrbitAngles } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-motion.js");
  const levels = [{ id: "a", label: "A", radius: 100, periodSeconds: 60 }];
  const nodes = [
    { id: "a", label: "A", levelId: "a" },
    { id: "b", label: "B", levelId: "a", periodSeconds: 1, direction: -1 },
  ];
  const angles = advanceKOrbitAngles(new Map(), levels, nodes, 1, 2, 10);
  assert.ok(Math.abs(angles.get("a") - Math.PI / 18) < 1e-12);
  assert.ok(Math.abs(angles.get("b") + Math.PI / 18) < 1e-12);
  advanceKOrbitAngles(angles, levels, nodes, 0, 100, 5);
  assert.ok(
    Math.abs(angles.get("a") - Math.PI / 18) < 1e-12,
    "Changing speed must not teleport",
  );
  advanceKOrbitAngles(angles, levels, nodes, 1, 0, 5);
  assert.ok(
    Math.abs(angles.get("a") - Math.PI / 18) < 1e-12,
    "Zero speed pauses",
  );
  advanceKOrbitAngles(angles, levels, [nodes[0]], 1, 1, 0);
  assert.equal(angles.has("b"), false);
  for (const invalid of [
    { periodSeconds: 0 },
    { pulseIntensity: 2 },
    { direction: 0 },
  ])
    assert.throws(() =>
      validateKOrbit(levels, [{ ...nodes[0], ...invalid }], []),
    );
});

test("Node colors and pulse intensity override semantic defaults", async () => {
  const { drawKOrbitFlatNode, drawKOrbitRim, drawKOrbitStatus } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-painter.js");
  const fills = [],
    strokes = [];
  const context = {
    beginPath() {},
    arc() {},
    fill() {
      fills.push(this.fillStyle);
    },
    stroke() {
      strokes.push([this.strokeStyle, this.globalAlpha]);
    },
  };
  const node = {
    id: "a",
    label: "A",
    status: "question",
    backgroundColor: "#123456",
    borderColor: "#abcdef",
    pulse: false,
  };
  const palette = { connectionWidth: 1, pulseDuration: 1000 };
  drawKOrbitFlatNode(context, { x: 0, y: 0 }, 10, node, palette);
  drawKOrbitRim(context, { x: 0, y: 0 }, 10, palette, node);
  drawKOrbitStatus(
    context,
    node,
    { x: 0, y: 0, depth: 1 },
    10,
    0,
    false,
    palette,
  );
  assert.deepEqual(fills, ["#123456"]);
  assert.equal(strokes.length, 1);
  assert.equal(strokes[0][0], "#abcdef");
  drawKOrbitStatus(
    context,
    { ...node, pulse: true, pulseIntensity: 0.25 },
    { x: 0, y: 0, depth: 1 },
    10,
    0,
    false,
    palette,
  );
  assert.deepEqual(strokes[1], ["#abcdef", 0.25]);
});

test("Primary drag pans without rotation; secondary drag rotates without translation", async () => {
  const { kOrbitDragView } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-gestures.js");
  const view = { yaw: 0.3, pitch: 0.2, zoom: 1.5, offset: { x: 10, y: 20 } };
  assert.deepEqual(kOrbitDragView(view, 30, -10, false), {
    ...view,
    offset: { x: 40, y: 10 },
  });
  const rotated = kOrbitDragView(view, 30, -10, true);
  assert.equal(rotated.yaw, 0.54);
  assert.ok(Math.abs(rotated.pitch - 0.12) < 1e-12);
  assert.deepEqual(rotated.offset, view.offset);
  assert.equal(rotated.zoom, view.zoom);
});

test("Orbit accepts consumer zoom limits and rejects invalid ranges", async () => {
  const { createElement } = await import("react");
  const { renderToStaticMarkup } = await import("react-dom/server");
  const { KOrbit } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit.js");
  const render = (zoomBounds) =>
    renderToStaticMarkup(
      createElement(KOrbit, { levels: [], nodes: [], zoomBounds }),
    );
  assert.match(render([0.05, 50]), /Interactive orbit/);
  for (const bounds of [
    [0, 2],
    [2, 1],
    [1, Infinity],
    [NaN, 2],
  ])
    assert.throws(() => render(bounds), /zoomBounds/);
});

test("Pinned nested node stays centered through motion, zoom and inclination, then resets smoothly", async () => {
  const { resolveKOrbitCamera } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-transitions.js");
  const state = { progress: new Map() };
  const levels = [
    { id: "a", label: "A", radius: 100, periodSeconds: 50 },
    { id: "b", label: "B", radius: 25, periodSeconds: 30 },
  ];
  const nodes = [
    { id: "root", label: "Root" },
    { id: "parent", label: "P", parentId: "root", levelId: "a" },
    { id: "child", label: "C", parentId: "parent", levelId: "b" },
  ];
  for (const [time, zoom, pitch] of [
    [0, 1, 0],
    [10, 4, 0.8],
    [30, 0.2, -0.6],
  ]) {
    const base = { ...kOrbitDefaultView, zoom, pitch };
    const project = (view) =>
      projectKOrbitScene(levels, nodes, view, time, 800, 600);
    const view = resolveKOrbitCamera(
      state,
      base,
      "child",
      (candidate) => {
        const point = project(candidate).points.get("child");
        return {
          x: candidate.offset.x + 400 - point.x,
          y: candidate.offset.y + 300 - point.y,
        };
      },
      time * 1000,
      200,
    );
    const point = project(view).points.get("child");
    assert.ok(Math.abs(point.x - 400) < 1e-9 && Math.abs(point.y - 300) < 1e-9);
  }
  const pinnedView = state.view;
  const first = resolveKOrbitCamera(
    state,
    kOrbitDefaultView,
    null,
    () => ({ x: 0, y: 0 }),
    31000,
    200,
  );
  assert.deepEqual(first, pinnedView);
  const last = resolveKOrbitCamera(
    state,
    kOrbitDefaultView,
    null,
    () => ({ x: 0, y: 0 }),
    31200,
    200,
  );
  assert.deepEqual(last, kOrbitDefaultView);
  state.pinnedId = "child";
  state.view = pinnedView;
  assert.deepEqual(
    resolveKOrbitCamera(
      state,
      kOrbitDefaultView,
      null,
      () => ({ x: 0, y: 0 }),
      32000,
      0,
    ),
    kOrbitDefaultView,
  );
});

test("Progress interpolates, reverses continuously, and respects reduced motion", async () => {
  const { animateKOrbitProgress } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-transitions.js");
  const state = new Map();
  const sample = (progress, now, duration = 200) =>
    animateKOrbitProgress(
      state,
      [{ id: "n", label: "N", progress }],
      now,
      duration,
    )[0].progress;
  assert.equal(sample(0, 0), 0);
  assert.equal(sample(100, 10), 0);
  assert.equal(sample(100, 110), 50);
  assert.equal(sample(0, 110), 50);
  assert.equal(sample(0, 210), 25);
  assert.equal(sample(80, 220, 0), 80);
  assert.equal(sample(80, 230), 80);
  animateKOrbitProgress(state, [], 300, 200);
  assert.equal(state.size, 0);
  assert.throws(
    () => validateKOrbit([], [{ id: "n", label: "N", progress: 101 }], []),
    /progress/,
  );
});

test("Progress paints a scaled arc on the node contour from 12 o'clock", async () => {
  const { drawKOrbitProgress } =
    await import("../../../packages/web/ui/dist/data-display/orbit/orbit-painter.js");
  const arcs = [],
    widths = [];
  const ctx = {
    beginPath() {},
    arc(...args) {
      arcs.push(args);
    },
    stroke() {
      widths.push(this.lineWidth);
    },
  };
  const palette = { nodeSize: 24, progressWidth: 2, primary: "blue" };
  const node = { id: "n", label: "N" },
    point = { x: 20, y: 30, depth: 0 };
  drawKOrbitProgress(ctx, { ...node, progress: 0 }, point, 12, palette);
  assert.equal(arcs.length, 0);
  drawKOrbitProgress(ctx, { ...node, progress: 50 }, point, 12, palette);
  drawKOrbitProgress(ctx, { ...node, progress: 100 }, point, 24, palette);
  assert.deepEqual(arcs[0], [20, 30, 12, -Math.PI / 2, Math.PI / 2]);
  assert.deepEqual(widths, [2, 4]);
});
