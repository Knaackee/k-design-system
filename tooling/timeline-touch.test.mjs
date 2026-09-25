import test from "node:test";
import assert from "node:assert/strict";
import { installTimelineTouch } from "../apps/storybook/src/timeline/timeline-touch.ts";

test("mobile timeline separates taps, holds, panning and edit dismissal", (t) => {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  const oldWindow = globalThis.window;
  const oldDocument = globalThis.document;
  const document = new EventTarget();
  const window = Object.assign(new EventTarget(), {
    innerWidth: 375,
    innerHeight: 812,
  });
  globalThis.document = document;
  globalThis.window = window;
  const element = Object.assign(new EventTarget(), {
    contains: () => true,
    classList: { toggle() {}, remove() {} },
  });
  let selection = [];
  let selectable = true;
  let opens = 0;
  const timeline = {
    getEventProperties: (event) => ({ item: event.item }),
    setSelection: (ids) => {
      selection = ids;
    },
    setOptions: (options) => {
      selectable = options.selectable;
    },
  };
  const control = installTimelineTouch(element, timeline, {
    selected: () => "research",
    editable: (id) => id !== "locked",
    select() {},
    open() {
      opens++;
    },
  });
  const fire = (target, type, item = "research", x = 0) => {
    const event = new Event(type, { cancelable: true });
    Object.assign(event, {
      item,
      button: 0,
      isPrimary: true,
      pointerId: 1,
      clientX: x,
      clientY: 0,
    });
    target.dispatchEvent(event);
  };
  try {
    assert.equal(selectable, false);
    assert.deepEqual(selection, []);
    fire(document, "pointerdown");
    t.mock.timers.tick(100);
    fire(document, "pointerup");
    fire(element, "click");
    assert.equal(opens, 1);
    assert.deepEqual(selection, []);
    fire(document, "pointerdown");
    t.mock.timers.tick(500);
    assert.deepEqual(selection, ["research"]);
    fire(document, "pointerup");
    fire(element, "click");
    assert.equal(opens, 1, "hold release must not open details");
    control.finish();
    control.syncSelection();
    assert.deepEqual(
      selection,
      [],
      "drop must not reactivate controlled selection",
    );
    fire(document, "pointerdown");
    fire(document, "pointermove", "research", 20);
    t.mock.timers.tick(500);
    assert.deepEqual(selection, [], "scroll movement cancels activation");
    fire(document, "pointerup");
    fire(element, "click");
    assert.equal(opens, 1);
    fire(document, "pointerdown", "locked");
    t.mock.timers.tick(500);
    assert.deepEqual(selection, []);
    fire(document, "pointerdown");
    t.mock.timers.tick(500);
    fire(document, "pointercancel");
    assert.deepEqual(selection, []);
    window.innerWidth = 1000;
    window.dispatchEvent(new Event("resize"));
    assert.equal(selectable, true);
    assert.deepEqual(selection, ["research"]);
  } finally {
    control.dispose();
    globalThis.window = oldWindow;
    globalThis.document = oldDocument;
  }
});
