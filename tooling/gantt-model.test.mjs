import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  addDays,
  applyGanttProposal,
  dateKey,
  isDateKey,
  localDate,
  moveGanttTask,
  summarizeTasks,
  validateGanttProposal,
} from "../packages/web/ui/src/data-display/gantt/gantt-model.ts";

const fixture = JSON.parse(
  readFileSync(
    new URL("../fixtures/gantt-reference.json", import.meta.url),
    "utf8",
  ),
);
const tasks = fixture.tasks;
const editable = tasks.find((task) => task.id === "research");

test("move previews shift both dates and preserve all task metadata", () => {
  const before = structuredClone(editable);
  assert.deepEqual(moveGanttTask(editable, 2, "move"), {
    ...editable,
    start: "2026-09-23",
    end: "2026-09-26",
  });
  assert.deepEqual(moveGanttTask(editable, -2, "move"), {
    ...editable,
    start: "2026-09-19",
    end: "2026-09-22",
  });
  assert.deepEqual(editable, before);
});

test("resize previews change only the selected boundary and clamp to one day", () => {
  assert.deepEqual(moveGanttTask(editable, -2, "start"), {
    ...editable,
    start: "2026-09-19",
  });
  assert.deepEqual(moveGanttTask(editable, 2, "end"), {
    ...editable,
    end: "2026-09-26",
  });
  assert.equal(moveGanttTask(editable, 30, "start").start, "2026-09-23");
  assert.equal(moveGanttTask(editable, -30, "end").end, "2026-09-22");
  assert.equal(moveGanttTask(editable, 3, "start").start, "2026-09-23");
  assert.equal(moveGanttTask(editable, -3, "end").end, "2026-09-22");
});

test("milestone movement preserves the absent end and local dates across DST", () => {
  const milestone = tasks.find((task) => task.type === "milestone");
  const moved = moveGanttTask(milestone, 1, "move");
  assert.equal(moved.start, "2026-10-17");
  assert.equal(Object.hasOwn(moved, "end"), false);
  const spring = { ...editable, start: "2026-03-28", end: "2026-03-30" };
  assert.deepEqual(moveGanttTask(spring, 1, "move"), {
    ...spring,
    start: "2026-03-29",
    end: "2026-03-31",
  });
  const fall = { ...editable, start: "2026-10-24", end: "2026-10-26" };
  assert.deepEqual(moveGanttTask(fall, 1, "move"), {
    ...fall,
    start: "2026-10-25",
    end: "2026-10-27",
  });
});

test("calendar arithmetic keeps local dates across DST, leap and month boundaries", () => {
  assert.equal(addDays("2026-03-29", 1), "2026-03-30");
  assert.equal(addDays("2024-03-01", -1), "2024-02-29");
  assert.equal(addDays("2026-09-30", 1), "2026-10-01");
  assert.equal(dateKey(localDate("0099-01-01")), "0099-01-01");
  for (const value of [
    "2026-02-29",
    "2026-13-01",
    "2026-00-12",
    "2026-2-01",
    "invalid",
  ])
    assert.equal(isDateKey(value), false);
});

test("accepted changes preserve consumer identity, content and references of other tasks", () => {
  const before = structuredClone(tasks);
  const proposed = {
    ...editable,
    start: "2026-09-22",
    end: "2026-09-26",
    progress: 42,
    text: "Injected",
    parent: "launch",
    type: "milestone",
    readOnly: true,
  };
  assert.equal(validateGanttProposal(tasks, proposed), true);
  const updated = applyGanttProposal(tasks, proposed);
  assert.notEqual(updated, tasks);
  const actual = updated.find((task) => task.id === editable.id);
  assert.deepEqual(actual, {
    ...editable,
    start: proposed.start,
    end: proposed.end,
    progress: 42,
  });
  assert.equal(updated[0], tasks[0]);
  assert.deepEqual(tasks, before);
  assert.equal(applyGanttProposal(tasks, proposed, false), tasks);
});

test("invalid, readonly and summary changes reject without mutation", () => {
  for (const patch of [
    { id: "unknown" },
    { start: "2026-02-30" },
    { end: undefined },
    { end: editable.start },
    { end: "2026-09-20" },
    { progress: NaN },
    { progress: Infinity },
    { progress: -1 },
    { progress: 101 },
  ])
    assert.equal(applyGanttProposal(tasks, { ...editable, ...patch }), tasks);
  for (const task of tasks.filter(
    (item) => item.readOnly || item.type === "summary",
  ))
    assert.equal(
      applyGanttProposal(tasks, { ...task, start: "2026-09-01" }),
      tasks,
    );
  const milestone = tasks.find((task) => task.type === "milestone");
  assert.equal(
    applyGanttProposal(tasks, { ...milestone, end: "2026-10-17" }),
    tasks,
  );
  const updated = applyGanttProposal(tasks, {
    ...milestone,
    start: "2026-10-15",
  });
  assert.equal(
    updated.find((task) => task.id === milestone.id).start,
    "2026-10-15",
  );
});

test("rejected edit cannot leak into the next accepted proposal", () => {
  applyGanttProposal(
    tasks,
    { ...editable, start: "2026-09-29", end: "2026-10-02" },
    false,
  );
  const updated = applyGanttProposal(tasks, {
    ...editable,
    start: "2026-09-22",
    end: "2026-09-25",
  });
  assert.equal(
    updated.find((task) => task.id === editable.id).end,
    "2026-09-25",
  );
  assert.equal(editable.start, "2026-09-21");
});

test("summaries derive bounds and duration-weighted progress without scheduling children", () => {
  const before = structuredClone(tasks);
  const result = summarizeTasks(tasks);
  const design = result.find((task) => task.id === "design");
  assert.equal(design.start, "2026-09-21");
  assert.equal(design.end, "2026-09-30");
  assert.equal(design.progress, 60);
  assert.equal(result.find((task) => task.id === "launch").end, "2026-10-17");
  assert.equal(
    result.find((task) => task.id === editable.id),
    editable,
  );
  assert.deepEqual(tasks, before);
});

test("nested summaries aggregate leaves and tolerate cyclic or empty groups", () => {
  const nested = [
    {
      id: "outer",
      text: "Outer",
      type: "summary",
      start: "2026-01-01",
      progress: 0,
    },
    {
      id: "inner",
      parent: "outer",
      text: "Inner",
      type: "summary",
      start: "2026-01-01",
      progress: 0,
    },
    { ...editable, parent: "inner" },
  ];
  const result = summarizeTasks(nested);
  assert.equal(result[0].end, editable.end);
  assert.equal(result[0].progress, editable.progress);
  const cycle = [{ ...nested[0], parent: "inner" }, nested[1]];
  assert.deepEqual(summarizeTasks(cycle), cycle);
});

test("fixture supplies complete stable hierarchy and valid dependency endpoints", () => {
  assert.equal(tasks.filter((task) => task.type === "summary").length, 3);
  assert.equal(tasks.filter((task) => task.type === "task").length, 9);
  assert.equal(tasks.filter((task) => task.type === "milestone").length, 1);
  const ids = new Set(tasks.map((task) => task.id));
  assert.equal(ids.size, tasks.length);
  for (const task of tasks) {
    assert.ok(isDateKey(task.start));
    if (task.parent)
      assert.equal(
        tasks.find((item) => item.id === task.parent)?.type,
        "summary",
      );
    if (task.end) assert.ok(isDateKey(task.end) && task.end > task.start);
  }
  assert.equal(
    new Set(fixture.links.map((link) => link.id)).size,
    fixture.links.length,
  );
  for (const link of fixture.links) {
    assert.ok(ids.has(link.source) && ids.has(link.target));
    assert.notEqual(link.source, link.target);
    assert.ok(["e2s", "s2s", "e2e", "s2e"].includes(link.type));
  }
});
