import assert from "node:assert/strict";
import { test } from "node:test";
import { EditorState, Transaction } from "@codemirror/state";
import { history, undo } from "@codemirror/commands";
import { Doc, UndoManager } from "yjs";
import { ySyncFacet } from "y-codemirror.next";
import { RawTextSync } from "../dist/editors/code-collaboration.js";
import {
  beginCodeDictation,
  codeDictationField,
} from "../dist/editors/code-dictation.js";

function fixture(selection = { anchor: 6, head: 10 }) {
  let current = true;
  const view = {
    state: EditorState.create({
      doc: "Hallo Welt!",
      selection,
      extensions: [codeDictationField, history()],
    }),
    dispatch(spec) {
      view.state = view.state.update(spec).state;
    },
  };
  return {
    view,
    begin: () => beginCodeDictation(view, () => current),
    dispose: () => {
      current = false;
    },
  };
}

test("source dictation maps concurrent changes and preserves the live selection", () => {
  const { view, begin } = fixture();
  const capture = begin();
  assert.equal(view.state.doc.toString(), "Hallo Welt!");
  view.dispatch({
    changes: { from: 0, insert: "Neu " },
    annotations: Transaction.remote.of(true),
  });
  view.dispatch({ selection: { anchor: 0, head: 3 } });
  assert.equal(capture.insert("Fred"), true);
  assert.equal(view.state.doc.toString(), "Neu Hallo Fred!");
  assert.equal(view.state.selection.main.anchor, 0);
  assert.equal(view.state.selection.main.head, 3);
  assert.equal(view.state.field(codeDictationField), null);
  assert.equal(capture.insert("Duplicate"), false);
});

test("cursor insertion follows preceding edits; cancellation and deleted ranges never write", () => {
  const { view, begin } = fixture({ anchor: 6 });
  const capture = begin();
  view.dispatch({ changes: { from: 0, insert: "Neu " } });
  assert.equal(capture.insert("schöne "), true);
  assert.equal(view.state.doc.toString(), "Neu Hallo schöne Welt!");
  const canceled = begin();
  canceled.cancel();
  assert.equal(canceled.insert("lost"), false);
  const removed = begin();
  view.dispatch({ changes: { from: 0, to: view.state.doc.length } });
  assert.equal(removed.insert("lost"), false);
  assert.equal(view.state.doc.toString(), "");
});

test("anchor metadata adds no undo entry, insertion is one normal undoable edit", () => {
  const { view, begin, dispose } = fixture();
  const capture = begin();
  assert.equal(undo({ state: view.state, dispatch: view.dispatch }), false);
  capture.insert("Fred");
  assert.equal(undo({ state: view.state, dispatch: view.dispatch }), true);
  assert.equal(view.state.doc.toString(), "Hallo Welt!");
  const unmounted = begin();
  dispose();
  assert.equal(unmounted.insert("lost"), false);
});

test("dictation undo preserves recent surrounding typing", () => {
  const { view, begin } = fixture({ anchor: 6 });
  const capture = begin();
  view.dispatch({
    changes: { from: 0, insert: "Neu " },
    annotations: Transaction.userEvent.of("input.type"),
  });
  capture.insert("schöne ");
  assert.equal(undo({ state: view.state, dispatch: view.dispatch }), true);
  assert.equal(view.state.doc.toString(), "Neu Hallo Welt!");
});

test("CRDT dictation undo keeps concurrent and recent edits and journals only actual text", () => {
  const doc = new Doc();
  const text = doc.getText("content");
  text.insert(0, "Hallo Welt!");
  const config = { toYRange: () => null, fromYRange: () => ({ anchor: 0 }) };
  const manager = new UndoManager(text, { trackedOrigins: new Set([config]) });
  let sync;
  const view = {
    state: EditorState.create({
      doc: text.toString(),
      selection: { anchor: 6 },
      extensions: [codeDictationField, ySyncFacet.of(config)],
    }),
    dispatch(spec) {
      const tr = view.state.update(spec);
      view.state = tr.state;
      sync?.update({
        docChanged: tr.docChanged,
        changes: tr.changes,
        transactions: [tr],
        state: tr.state,
      });
    },
  };
  sync = new RawTextSync(view, text, manager);
  let updates = 0;
  doc.on("update", () => updates++);
  const capture = beginCodeDictation(view, () => true);
  assert.equal(updates, 0);
  view.dispatch({ changes: { from: 0, insert: "Neu " } });
  doc.transact(() => text.insert(text.length, " Remote"), "remote");
  assert.equal(capture.insert("schöne "), true);
  assert.equal(updates, 3);
  assert.equal(text.toString(), "Neu Hallo schöne Welt! Remote");
  manager.undo();
  assert.equal(text.toString(), "Neu Hallo Welt! Remote");
  assert.equal(view.state.doc.toString(), text.toString());
  sync.destroy();
  doc.destroy();
});
