import assert from "node:assert/strict";
import { test } from "node:test";
import {
  moveMarkdownEditorMount,
  wrapMarkdownEditorTab,
} from "../dist/editors/markdown-editor-mount.js";

class ElementFixture {
  children = [];
  parentElement = null;
  isConnected = true;
  scrollTop = 0;
  scrollLeft = 0;
  focusCount = 0;
  contains(node) {
    return node === this || this.children.some((child) => child.contains(node));
  }
  querySelectorAll() {
    return this.children.flatMap((child) => [
      child,
      ...child.querySelectorAll(),
    ]);
  }
  focus() {
    this.focusCount += 1;
    this.ownerDocument.activeElement = this;
  }
  append(node) {
    node.parentElement = this;
    this.children.push(node);
    // Model browser fallback: detach loses focus, DOM selection and scroll.
    this.ownerDocument.activeElement = null;
    this.ownerDocument.selection.anchorNode = null;
    for (const child of node.querySelectorAll())
      child.scrollTop = child.scrollLeft = 0;
  }
}

function fixture() {
  const document = {
    selection: {
      anchorOffset: 2,
      focusOffset: 5,
      setBaseAndExtent(anchorNode, anchorOffset, focusNode, focusOffset) {
        Object.assign(this, {
          anchorNode,
          anchorOffset,
          focusNode,
          focusOffset,
        });
      },
    },
    getSelection() {
      return this.selection;
    },
  };
  const mount = new ElementFixture();
  const editor = new ElementFixture();
  const target = new ElementFixture();
  for (const element of [mount, editor, target])
    element.ownerDocument = document;
  mount.children = [editor];
  document.activeElement = editor;
  document.selection.anchorNode = editor;
  document.selection.focusNode = editor;
  editor.scrollTop = 120;
  editor.scrollLeft = 24;
  return { mount, editor, target, document };
}

test("fallback relocation retains the same editor node, focus, selection and scroll", () => {
  const previous = globalThis.HTMLElement;
  globalThis.HTMLElement = ElementFixture;
  try {
    const { mount, editor, target, document } = fixture();
    moveMarkdownEditorMount(mount, target);
    assert.equal(target.children[0], mount);
    assert.equal(mount.children[0], editor);
    assert.equal(document.activeElement, editor);
    assert.equal(document.selection.anchorNode, editor);
    assert.equal(document.selection.focusNode, editor);
    assert.equal(document.selection.anchorOffset, 2);
    assert.equal(document.selection.focusOffset, 5);
    assert.equal(editor.scrollTop, 120);
    assert.equal(editor.scrollLeft, 24);
    const focusCount = editor.focusCount;
    moveMarkdownEditorMount(mount, target);
    assert.equal(editor.focusCount, focusCount, "same-host moves are a no-op");
  } finally {
    globalThis.HTMLElement = previous;
  }
});

test("connected browsers with moveBefore use the state-preserving DOM move", () => {
  const { mount, editor, target, document } = fixture();
  let moves = 0;
  target.moveBefore = (node, before) => {
    assert.equal(node, mount);
    assert.equal(before, null);
    moves += 1;
  };
  moveMarkdownEditorMount(mount, target);
  assert.equal(moves, 1);
  assert.equal(document.activeElement, editor);
  assert.equal(editor.focusCount, 0);
  assert.equal(editor.scrollTop, 120);
});

test("the portal completes only the dialog's missing forward Tab boundary", () => {
  const document = {};
  const control = (name, visible = true) => ({
    name,
    tabIndex: 0,
    matches: () => false,
    closest: () => null,
    getClientRects: () => (visible ? [{}] : []),
    focus() {
      document.activeElement = this;
    },
  });
  const first = control("Back");
  const last = control("Collapse");
  const hidden = control("Hidden", false);
  const dialog = { querySelectorAll: () => [first, last, hidden] };
  const mount = { ownerDocument: document, closest: () => dialog };
  const event = {
    key: "Tab",
    currentTarget: mount,
    prevented: false,
    preventDefault() {
      this.prevented = true;
    },
  };
  document.activeElement = last;
  wrapMarkdownEditorTab(event);
  assert.equal(event.prevented, true);
  assert.equal(document.activeElement, first);
  for (const change of [
    { shiftKey: true },
    { defaultPrevented: true },
    { key: "Escape" },
  ]) {
    document.activeElement = last;
    const ignored = { ...event, prevented: false, ...change };
    wrapMarkdownEditorTab(ignored);
    assert.equal(ignored.prevented, false);
    assert.equal(document.activeElement, last);
  }
  document.activeElement = first;
  const middle = { ...event, prevented: false };
  wrapMarkdownEditorTab(middle);
  assert.equal(middle.prevented, false, "normal tab order stays native");
});
