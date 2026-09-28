import test from "node:test";
import assert from "node:assert/strict";
import { installGanttGestures } from "../packages/web/ui/src/data-display/gantt/gantt-gestures.ts";

function harness(t, compact = true) {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  const previousDocument = globalThis.document;
  const document = new EventTarget();
  globalThis.document = document;
  const captures = new Set();
  const tasks = [
    {
      id: "research",
      text: "Research",
      type: "task",
      start: "2026-09-21",
      end: "2026-09-24",
      progress: 0,
    },
    {
      id: "locked",
      text: "Locked",
      type: "task",
      start: "2026-09-21",
      end: "2026-09-24",
      progress: 0,
      readOnly: true,
    },
    {
      id: "group",
      text: "Group",
      type: "summary",
      start: "2026-09-21",
      end: "2026-09-24",
      progress: 0,
    },
  ];
  const calls = {
    opens: [],
    previews: [],
    commits: [],
    activations: [],
    pans: [],
    clears: 0,
  };
  const root = Object.assign(new EventTarget(), {
    contains: (target) => target?.inside === true,
    setPointerCapture: (id) => captures.add(id),
    hasPointerCapture: (id) => captures.has(id),
    releasePointerCapture: (id) => captures.delete(id),
  });
  const dispose = installGanttGestures(root, {
    compact: () => compact,
    task: (id) => tasks.find((task) => task.id === id),
    dayWidth: () => 40,
    preview: (...args) => calls.previews.push(args),
    commit: (...args) => calls.commits.push(args),
    clear: () => calls.clears++,
    open: (id) => calls.opens.push(id),
    activate: (id) => calls.activations.push(id),
    pan: (...args) => calls.pans.push(args),
  });
  function fire(
    type,
    {
      id = "research",
      edge,
      surface,
      x = 0,
      y = 0,
      pointerType = "mouse",
      pointerId = 1,
      ...properties
    } = {},
  ) {
    const bar = {
      inside: true,
      querySelector: () => ({ dataset: { ganttId: id } }),
    };
    const target = {
      inside: true,
      closest: (selector) =>
        selector === ".wx-bar[data-id]"
          ? surface
            ? null
            : bar
          : selector === ".wx-area, .wx-scale"
            ? surface === "plot" || surface === "scale"
              ? { inside: true }
              : null
            : edge
              ? { dataset: { ganttEdge: edge } }
              : null,
    };
    const event = new Event(type, { cancelable: true });
    Object.assign(event, {
      button: 0,
      isPrimary: true,
      pointerId,
      pointerType,
      clientX: x,
      clientY: y,
      ...properties,
    });
    Object.defineProperty(event, "target", { value: target });
    root.dispatchEvent(event);
    return event;
  }
  t.after(() => {
    dispose();
    globalThis.document = previousDocument;
  });
  return { calls, fire, document, tasks, root, captures };
}

for (const pointerType of ["mouse", "touch"]) {
  for (const surface of ["plot", "scale"]) {
    test(`${pointerType} drag on empty ${surface} pans without editing records`, (t) => {
      const h = harness(t);
      h.fire("pointerdown", { surface, pointerType, x: 200, y: 100 });
      t.mock.timers.tick(600);
      h.fire("pointermove", { surface, pointerType, x: 120, y: 70 });
      h.fire("pointerup", { surface, pointerType, x: 120, y: 70 });
      assert.deepEqual(h.calls.pans, [[80, 30]]);
      assert.deepEqual(h.calls.previews, []);
      assert.deepEqual(h.calls.commits, []);
      assert.deepEqual(h.calls.opens, []);
      assert.equal(h.captures.size, 0);
    });
  }
}

test("controls outside the plot keep their native pointer handling", (t) => {
  const h = harness(t);
  h.fire("pointerdown", { surface: "control" });
  assert.equal(h.captures.size, 0);
  h.fire("pointermove", { surface: "control", x: 80 });
  h.fire("pointerup", { surface: "control", x: 80 });
  assert.deepEqual(h.calls.pans, []);
});

test("compact short tap opens details without activating or editing", (t) => {
  const h = harness(t);
  h.fire("pointerdown");
  t.mock.timers.tick(100);
  h.fire("pointerup");
  t.mock.timers.tick(600);
  assert.deepEqual(h.calls.opens, ["research"]);
  assert.deepEqual(h.calls.commits, []);
  assert.ok(!h.calls.activations.includes("research"));
  assert.equal(h.captures.size, 0);
});

test("movement before hold pans and permanently cancels activation for that gesture", (t) => {
  const h = harness(t);
  h.fire("pointerdown");
  assert.equal(h.fire("pointermove", { x: 10, y: 20 }).defaultPrevented, true);
  t.mock.timers.tick(600);
  h.fire("pointermove", { x: 40, y: 30 });
  h.fire("pointerup", { x: 40, y: 30 });
  assert.deepEqual(h.calls.pans, [
    [-10, -20],
    [-30, -10],
  ]);
  assert.deepEqual(h.calls.commits, []);
  assert.deepEqual(h.calls.previews, []);
  assert.deepEqual(h.calls.opens, []);
  assert.ok(!h.calls.activations.includes("research"));
});

for (const pointerType of ["mouse", "touch"]) {
  test(`500ms ${pointerType} hold activates, then release leaves resize mode without opening details`, (t) => {
    const h = harness(t);
    h.fire("pointerdown", { pointerType });
    t.mock.timers.tick(499);
    assert.deepEqual(h.calls.activations, []);
    t.mock.timers.tick(1);
    assert.deepEqual(h.calls.activations, ["research"]);
    h.fire("pointerup", { pointerType });
    assert.deepEqual(h.calls.opens, []);
    assert.deepEqual(h.calls.commits, []);
    assert.equal(h.calls.activations.at(-1), "research");
  });
}

test("same held gesture previews snapped dates and commits once on release", (t) => {
  const h = harness(t);
  const before = structuredClone(h.tasks);
  h.fire("pointerdown", { pointerType: "touch" });
  t.mock.timers.tick(500);
  h.fire("pointermove", { pointerType: "touch", x: 65 });
  assert.deepEqual(h.calls.previews, [[h.tasks[0], 2, "move"]]);
  assert.deepEqual(h.calls.commits, []);
  h.fire("pointerup", { pointerType: "touch", x: 65 });
  h.fire("pointerup", { pointerType: "touch", x: 65 });
  assert.deepEqual(h.calls.commits, [[h.tasks[0], 2, "move"]]);
  assert.equal(h.calls.activations.at(-1), null);
  assert.deepEqual(h.tasks, before);
});

test("activated resize handles report their edge and signed day delta", (t) => {
  const h = harness(t);
  for (const [edge, x, days] of [
    ["start", -40, -1],
    ["end", 80, 2],
  ]) {
    h.fire("pointerdown");
    t.mock.timers.tick(500);
    h.fire("pointerup");
    h.fire("pointerdown", { edge });
    h.fire("pointermove", { edge, x });
    h.fire("pointerup", { edge, x });
    assert.deepEqual(h.calls.commits.at(-1), [h.tasks[0], days, edge]);
  }
  assert.equal(h.calls.commits.length, 2);
});

test("Escape and pointer cancellation discard previews without committing", (t) => {
  const h = harness(t);
  for (const cancellation of ["escape", "pointercancel"]) {
    h.fire("pointerdown");
    t.mock.timers.tick(500);
    h.fire("pointermove", { x: 80 });
    if (cancellation === "escape") {
      const event = new Event("keydown");
      Object.assign(event, { key: "Escape" });
      h.document.dispatchEvent(event);
    } else h.fire("pointercancel");
    assert.equal(
      h.captures.size,
      0,
      "cancellation releases capture before pointer-up",
    );
    h.fire("pointerup", { x: 80 });
    assert.equal(h.calls.activations.at(-1), null);
  }
  assert.deepEqual(h.calls.commits, []);
  assert.ok(h.calls.clears >= 2);
});

test("readonly tasks and summary rows never enter editing mode", (t) => {
  const h = harness(t);
  for (const id of ["locked", "group"]) {
    h.fire("pointerdown", { id });
    t.mock.timers.tick(500);
    h.fire("pointermove", { id, x: 80 });
    h.fire("pointerup", { id, x: 80 });
  }
  assert.deepEqual(h.calls.previews, []);
  assert.deepEqual(h.calls.commits, []);
  assert.equal(h.calls.pans.length, 2);
});

test("consumer rejection cannot leak a previous delta into a subsequent drag", (t) => {
  const h = harness(t, false);
  for (const x of [120, -40, 10]) {
    h.fire("pointerdown");
    h.fire("pointermove", { x });
    h.fire("pointerup", { x });
  }
  assert.deepEqual(
    h.calls.commits.map(([, days]) => days),
    [3, -1],
  );
  assert.equal(h.tasks[0].start, "2026-09-21");
  assert.ok(h.calls.commits.every(([task]) => task === h.tasks[0]));
});

test("nonprimary pointers are ignored and outside interaction dismisses activation", (t) => {
  const h = harness(t);
  h.fire("pointerdown", { isPrimary: false });
  t.mock.timers.tick(500);
  assert.deepEqual(h.calls.activations, []);
  h.fire("pointerdown");
  t.mock.timers.tick(500);
  h.fire("pointerup");
  h.document.dispatchEvent(new Event("pointerdown"));
  assert.equal(h.calls.activations.at(-1), null);
  assert.deepEqual(h.calls.commits, []);
});
