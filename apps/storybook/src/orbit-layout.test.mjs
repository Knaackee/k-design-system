import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { layoutKOrbit } from "../../../packages/web/ui/dist/data-display/orbit/orbit-layout.js";
import {
  projectKOrbitScene,
  kOrbitDefaultView,
} from "../../../packages/web/ui/dist/data-display/orbit/orbit-model.js";
import { advanceKOrbitAngles } from "../../../packages/web/ui/dist/data-display/orbit/orbit-motion.js";
const fixture = JSON.parse(
  readFileSync(new URL("./orbit-layout.fixture.json", import.meta.url), "utf8"),
);
function assertClear(layout) {
  const byId = new Map(layout.nodes.map((node) => [node.id, node]));
  function projectOf(node) {
    if (node.id.startsWith("project-")) return node.id;
    return node.parentId ? projectOf(byId.get(node.parentId)) : null;
  }
  for (const elapsed of [0, 7, 61, 300]) {
    const scene = projectKOrbitScene(
      layout.levels,
      layout.nodes,
      kOrbitDefaultView,
      elapsed,
      1200,
      900,
    );
    for (const a of layout.nodes)
      for (const b of layout.nodes) {
        if (
          a.id >= b.id ||
          !projectOf(a) ||
          !projectOf(b) ||
          projectOf(a) === projectOf(b)
        )
          continue;
        const pa = scene.points.get(a.id),
          pb = scene.points.get(b.id);
        const distance = Math.hypot(pa.x - pb.x, pa.y - pb.y) / scene.scale;
        assert.ok(
          distance >= (a.radius ?? 12) + (b.radius ?? 12) + 12 - 1e-6,
          `${a.id}/${b.id} overlap at ${elapsed}`,
        );
      }
  }
}
test("subtree spacing keeps unequal projects separated throughout motion and after filtering", () => {
  const before = JSON.stringify(fixture);
  assertClear(layoutKOrbit(fixture.levels, fixture.nodes));
  const colored = layoutKOrbit(
    fixture.levels.map((level) => ({ ...level, color: "#6366f1" })),
    fixture.nodes,
  );
  assert.ok(colored.levels.every((level) => level.color === "#6366f1"));
  const filtered = fixture.nodes.filter(
    (node) => !/^(project|issue|agent)-1(?:-|$)/.test(node.id),
  );
  assertClear(layoutKOrbit(fixture.levels, filtered));
  assert.equal(JSON.stringify(fixture), before);
});
test("different periods receive separate annuli and shared rings synchronize accumulated angles", () => {
  const nodes = fixture.nodes.map((node) =>
    node.id === "project-1" ? { ...node, periodSeconds: 75 } : node,
  );
  const layout = layoutKOrbit(fixture.levels, nodes);
  assertClear(layout);
  const a = layout.nodes.find((node) => node.id === "project-0");
  const b = layout.nodes.find((node) => node.id === "project-2");
  const angles = advanceKOrbitAngles(
    new Map([
      [a.id, 1],
      [b.id, 2],
    ]),
    layout.levels,
    layout.nodes,
    1,
    1,
    12,
    true,
  );
  assert.equal(angles.get(a.id), angles.get(b.id));
  assert.throws(
    () => layoutKOrbit(fixture.levels, fixture.nodes, -1),
    /layoutGap/,
  );
  assert.throws(
    () => layoutKOrbit(fixture.levels, fixture.nodes, NaN),
    /layoutGap/,
  );
});
