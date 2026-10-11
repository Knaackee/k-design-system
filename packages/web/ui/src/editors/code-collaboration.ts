import {
  EditorState,
  Prec,
  Transaction,
  type Extension,
} from "@codemirror/state";
import { ViewPlugin, EditorView, type ViewUpdate } from "@codemirror/view";
import {
  yCollab,
  ySync,
  ySyncFacet,
  ySyncAnnotation,
  yUndoManagerKeymap,
  type YRange,
} from "y-codemirror.next";
import * as Y from "yjs";
import {
  renderedSource,
  renderedToRaw,
  rawToRendered,
  sourceEdit,
  renderedChange,
} from "./code-source-map.js";

/** CodeMirror uses LF positions; the shared Y.Text retains original separators. */
export class RawTextSync {
  private config;
  private range: YRange;
  constructor(
    private view: EditorView,
    private text: Y.Text,
  ) {
    this.config = view.state.facet(ySyncFacet);
    this.config.toYPos = (pos, assoc = 0) =>
      Y.createRelativePositionFromTypeIndex(
        this.text,
        renderedToRaw(this.text.toString(), pos),
        assoc,
      );
    this.config.fromYPos = (position) => {
      const result = Y.createAbsolutePositionFromRelativePosition(
        position,
        this.text.doc!,
      );
      if (!result || result.type !== this.text)
        throw Error("Selection belongs to a different document");
      return {
        pos: rawToRendered(this.text.toString(), result.index),
        assoc: result.assoc,
      };
    };
    this.range = this.config.toYRange(view.state.selection.main);
    this.text.observe(this.changed);
  }
  private changed = (_event: Y.YTextEvent, transaction: Y.Transaction) => {
    if (transaction.origin === this.config) return;
    const next = renderedSource(this.text.toString()),
      before = this.view.state.doc.toString();
    if (next === before) return;
    this.view.dispatch({
      changes: renderedChange(before, next),
      selection: this.config.fromYRange(this.range),
      annotations: [
        ySyncAnnotation.of(this.config),
        Transaction.remote.of(true),
        Transaction.addToHistory.of(false),
      ],
    });
  };
  update(update: ViewUpdate) {
    if (
      update.docChanged &&
      !update.transactions.some(
        (transaction) =>
          transaction.annotation(ySyncAnnotation) === this.config,
      )
    ) {
      const source = this.text.toString();
      let adjustment = 0;
      this.text.doc!.transact(() => {
        update.changes.iterChanges((from, to, _fromB, _toB, insert) => {
          const change = sourceEdit(source, from, to, insert.toString());
          if (change.to > change.from)
            this.text.delete(change.from + adjustment, change.to - change.from);
          if (change.insert)
            this.text.insert(change.from + adjustment, change.insert);
          adjustment += change.insert.length - (change.to - change.from);
        });
      }, this.config);
    }
    this.range = this.config.toYRange(update.state.selection.main);
  }
  destroy() {
    this.text.unobserve(this.changed);
  }
}
export function collaborativeUndo(view: EditorView) {
  return view.state.facet(EditorState.readOnly)
    ? false
    : yUndoManagerKeymap[0]!.run!(view);
}
export function collaborativeRedo(view: EditorView) {
  return view.state.facet(EditorState.readOnly)
    ? false
    : yUndoManagerKeymap[1]!.run!(view);
}
export const collaborativeHistoryKeymap = [
  { key: "Mod-z", run: collaborativeUndo },
  { key: "Mod-y", mac: "Mod-Shift-z", run: collaborativeRedo },
  { key: "Mod-Shift-z", run: collaborativeRedo },
];
export function rawTextCollaboration(
  text: Y.Text,
  undoManager = new Y.UndoManager(text),
): Extension {
  const sync = ViewPlugin.define((view) => new RawTextSync(view, text));
  return [
    Prec.highest(
      EditorView.domEventHandlers({
        beforeinput(event, view) {
          return (
            view.state.facet(EditorState.readOnly) &&
            (event.inputType === "historyUndo" ||
              event.inputType === "historyRedo")
          );
        },
      }),
    ),
    ...(yCollab(text, null, { undoManager }) as Extension[]).map((extension) =>
      extension === ySync ? sync : extension,
    ),
  ];
}
