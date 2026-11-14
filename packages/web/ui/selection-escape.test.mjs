import assert from "node:assert/strict";
import test from "node:test";
import { Window } from "happy-dom";

// Install the DOM before importing Radix/React DOM, which detect it at import time.
const window = new Window({ url: "https://k.test" });
for (const name of [
  "document",
  "navigator",
  "Node",
  "Element",
  "HTMLElement",
  "HTMLInputElement",
  "HTMLSelectElement",
  "Event",
  "MouseEvent",
  "KeyboardEvent",
  "CustomEvent",
  "MutationObserver",
  "ResizeObserver",
  "NodeFilter",
]) {
  Object.defineProperty(globalThis, name, {
    configurable: true,
    value: window[name],
  });
}
globalThis.window = window;
globalThis.getComputedStyle = window.getComputedStyle.bind(window);
globalThis.requestAnimationFrame = window.requestAnimationFrame.bind(window);
globalThis.cancelAnimationFrame = window.cancelAnimationFrame.bind(window);
globalThis.innerWidth = 1280;
globalThis.innerHeight = 800;
globalThis.IS_REACT_ACT_ENVIRONMENT = true;
HTMLElement.prototype.showPopover = function () {};
HTMLElement.prototype.hidePopover = function () {};
HTMLElement.prototype.scrollIntoView = function () {};

const { createElement: h, useState, act } = await import("react");
const { createRoot } = await import("react-dom/client");
const { KSelect, KCombobox } = await import("./dist/forms/selection.js");
const { KAdaptiveDialog } = await import("./dist/overlays/overlay.js");

for (const [name, Picker] of [
  ["select", KSelect],
  ["combobox", KCombobox],
]) {
  test(`${name}: Escape closes its menu before the parent adaptive dialog`, async () => {
    const container = document.createElement("div");
    document.body.append(container);
    const root = createRoot(container);
    let closed = 0;
    function Fixture() {
      const [open, setOpen] = useState(true);
      return h(
        KAdaptiveDialog,
        {
          open,
          title: "Edit draft",
          description: "Unsaved form",
          onOpenChange: (value) => {
            closed++;
            setOpen(value);
          },
        },
        h(Picker, {
          label: "Status",
          value: "draft",
          onValueChange() {},
          options: [
            { value: "draft", label: "Draft" },
            { value: "active", label: "Active" },
          ],
        }),
      );
    }
    try {
      await act(async () => root.render(h(Fixture)));
      const input = document.querySelector('[role="combobox"]');
      assert.ok(input);
      assert.equal(input.closest("[data-k-escape-boundary]"), null);
      await act(async () => {
        input.focus();
        input.click();
      });
      assert.ok(document.querySelector('[role="listbox"]'));
      await act(async () =>
        input.dispatchEvent(
          new KeyboardEvent("keydown", {
            key: "Escape",
            bubbles: true,
            cancelable: true,
          }),
        ),
      );
      assert.equal(document.querySelector('[role="listbox"]'), null);
      assert.ok(document.querySelector('[role="dialog"]'));
      assert.equal(closed, 0, "first Escape must not discard the parent draft");
      assert.equal(document.activeElement, input);
      assert.equal(
        input.closest("[data-k-escape-boundary]"),
        null,
        "closed picker must release the parent's Escape handling",
      );
      await act(async () =>
        input.dispatchEvent(
          new KeyboardEvent("keydown", {
            key: "Escape",
            bubbles: true,
            cancelable: true,
          }),
        ),
      );
      assert.equal(closed, 1, "second Escape dismisses the parent");
      assert.equal(document.querySelector('[role="dialog"]'), null);
    } finally {
      await act(async () => root.unmount());
      container.remove();
    }
  });
}

test.after(() => window.happyDOM.close());
