import test from "node:test";
import assert from "node:assert/strict";
import { createTimelinePreview } from "../packages/web/ui/src/data-display/timeline/timeline-preview.ts";

test("proposal painting preserves canonical item geometry and cleans up", () => {
  const previous = globalThis.document;
  const rect = { left: 100, top: 80, width: 80, height: 38 };
  const clone = { style: {}, querySelectorAll: () => [] };
  const source = {
    style: { visibility: "" },
    getBoundingClientRect: () => rect,
    cloneNode: () => clone,
  };
  let removed = false;
  const overlay = {
    style: {},
    setAttribute() {},
    appendChild() {},
    remove() {
      removed = true;
    },
  };
  const plot = {
    getBoundingClientRect: () => ({ left: 100, top: 64, width: 700 }),
  };
  const content = { dataset: { timelineId: "a" }, closest: () => source };
  const group = {
    dataset: { timelineGroup: "other" },
    closest: () => ({ getBoundingClientRect: () => ({ top: 180 }) }),
  };
  const root = {
    getBoundingClientRect: () => ({ left: 0, top: 0 }),
    querySelector: () => plot,
    querySelectorAll: (selector) =>
      selector.includes("group") ? [group] : [content],
    appendChild() {},
  };
  globalThis.document = { createElement: () => overlay };
  try {
    const preview = createTimelinePreview(root, {
      getWindow: () => ({
        start: new Date(2026, 8, 21),
        end: new Date(2026, 8, 28),
      }),
    });
    const original = {
      id: "a",
      group: "first",
      start: "2026-09-21",
      end: "2026-09-23",
    };
    preview.show(
      { ...original, start: "2026-09-23", end: "2026-09-26" },
      original,
    );
    assert.equal(clone.style.left, "300px");
    assert.equal(clone.style.width, "300px");
    assert.equal(clone.style.top, "80px");
    assert.equal(source.style.visibility, "hidden");
    assert.deepEqual(rect, { left: 100, top: 80, width: 80, height: 38 });
    preview.show({ ...original, group: "other" }, original);
    assert.equal(clone.style.top, "185px");
    preview.clear();
    assert.equal(source.style.visibility, "");
    assert.equal(removed, true);
    preview.clear();
  } finally {
    globalThis.document = previous;
  }
});
