import assert from "node:assert/strict";
import { test } from "node:test";
import { handleOverlayPointerOutside } from "../dist/overlays/overlay-pointer.js";

test("dialog outside dismissal respects DOM-contained editor portals and dismissible", () => {
  const previous = globalThis.Node;
  globalThis.Node = class NodeFixture {};
  try {
    const inside = new Node();
    const outside = new Node();
    const content = { contains: (node) => node === inside };
    for (const [target, dismissible, expected] of [
      [inside, true, true],
      [outside, true, false],
      [outside, false, true],
      [null, true, false],
      [{}, true, false],
    ]) {
      let prevented = false;
      handleOverlayPointerOutside(
        {
          detail: { originalEvent: { target } },
          preventDefault: () => {
            prevented = true;
          },
        },
        content,
        dismissible,
      );
      assert.equal(prevented, expected);
    }
  } finally {
    globalThis.Node = previous;
  }
});
