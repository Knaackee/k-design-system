import assert from "node:assert/strict";
import test from "node:test";
import { UndoManager } from "yjs";
import {
  createKEditorCollaborationDocument,
  createKEditorCollaborationTransport,
  resolveKEditorCollaborationDocument,
  seedKEditorCollaborationText,
} from "./dist/editors/collaboration.js";

function replica(t, initialText) {
  const handle = createKEditorCollaborationDocument({
    id: "markdown-transport",
    kind: "text",
    initialText,
  });
  const document = resolveKEditorCollaborationDocument(handle, "text");
  const transport = createKEditorCollaborationTransport(handle);
  t.after(() => transport.destroy());
  return { document, text: document.getText("content"), transport };
}

test("independent Web replicas reconnect without echo and undo only their local edit", (t) => {
  const initialText = "# Alpha\r\nBeta 🧪";
  const left = replica(t, initialText);
  // Seed once: independent insertions of the same initial text merge as edits.
  const right = replica(t);
  const leftUpdates = [];
  const rightUpdates = [];
  left.transport.subscribe((update) => leftUpdates.push(update));
  right.transport.subscribe((update) => rightUpdates.push(update));
  const seed = left.transport.encodeUpdate();
  right.transport.applyUpdate(seed);
  assert.equal(right.text.toString(), initialText);

  const localOrigin = Symbol("left-editor");
  const undo = new UndoManager(left.text, {
    trackedOrigins: new Set([localOrigin]),
  });
  t.after(() => undo.destroy());
  left.document.transact(() => left.text.insert(0, "Local\r\n"), localOrigin);
  right.text.insert(right.text.length, " Remote");

  const missedByRight = left.transport.encodeUpdate(
    right.transport.encodeStateVector(),
  );
  const missedByLeft = right.transport.encodeUpdate(
    left.transport.encodeStateVector(),
  );
  left.transport.applyUpdate(missedByLeft);
  right.transport.applyUpdate(missedByRight);
  left.transport.applyUpdate(missedByLeft);
  right.transport.applyUpdate(seed);
  const merged = `Local\r\n${initialText} Remote`;
  assert.equal(left.text.toString(), merged);
  assert.equal(right.text.toString(), merged);
  assert.equal(leftUpdates.length, 1);
  assert.equal(rightUpdates.length, 1);

  undo.undo();
  assert.equal(leftUpdates.length, 2);
  right.transport.applyUpdate(leftUpdates[1]);
  assert.equal(left.text.toString(), `${initialText} Remote`);
  assert.equal(right.text.toString(), left.text.toString());
  assert.equal(rightUpdates.length, 1);
});

test("legacy editor seeding does not restore a document a peer emptied", (t) => {
  const left = replica(t, "Original");
  const right = replica(t);
  left.text.delete(0, left.text.length);
  right.transport.applyUpdate(left.transport.encodeUpdate());

  seedKEditorCollaborationText(right.document, "Original");
  assert.equal(right.text.toString(), "");
});
