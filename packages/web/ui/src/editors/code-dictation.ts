import { StateEffect, StateField, Transaction } from "@codemirror/state";
import { Decoration, EditorView, WidgetType } from "@codemirror/view";
import { isolateHistory } from "@codemirror/commands";
import {
  createKDictationAnchor,
  KDictationState,
} from "../forms/dictation-action.js";

type Anchor = { id: symbol; from: number; to: number };
const setAnchor = StateEffect.define<Anchor | null>();

class AnchorWidget extends WidgetType {
  toDOM(view: EditorView) {
    return createKDictationAnchor(
      KDictationState.recording,
      view.dom.ownerDocument,
    );
  }
}

/** Kept outside the document, undo stack and collaboration updates. */
export const codeDictationField = StateField.define<Anchor | null>({
  create: () => null,
  update(anchor, transaction) {
    for (const effect of transaction.effects) {
      if (effect.is(setAnchor)) return effect.value;
    }
    if (!anchor || !transaction.docChanged) return anchor;
    let removed = false;
    transaction.changes.iterChangedRanges((from, to) => {
      if (from < anchor.to && to > anchor.from) removed = true;
      if (anchor.from === anchor.to && from < anchor.from && to > anchor.from)
        removed = true;
    });
    if (removed) return null;
    const from = transaction.changes.mapPos(anchor.from, 1);
    const to =
      anchor.from === anchor.to
        ? from
        : transaction.changes.mapPos(anchor.to, -1);
    return { ...anchor, from, to };
  },
  provide: (field) =>
    EditorView.decorations.from(field, (anchor) =>
      anchor
        ? Decoration.set([
            Decoration.widget({ widget: new AnchorWidget(), side: 1 }).range(
              anchor.from,
            ),
          ])
        : Decoration.none,
    ),
});

export function beginCodeDictation(view: EditorView, isCurrent: () => boolean) {
  const { from, to } = view.state.selection.main;
  const id = Symbol("dictation");
  view.dispatch({
    effects: setAnchor.of({ id, from, to }),
    annotations: Transaction.addToHistory.of(false),
  });
  const cancel = () => {
    if (isCurrent() && view.state.field(codeDictationField)?.id === id)
      view.dispatch({
        effects: setAnchor.of(null),
        annotations: Transaction.addToHistory.of(false),
      });
  };
  return {
    cancel,
    insert(text: string): boolean {
      if (!isCurrent()) return false;
      const anchor = view.state.field(codeDictationField);
      if (!anchor || anchor.id !== id || view.state.readOnly || !text.trim()) {
        cancel();
        return false;
      }
      // Leave the live selection alone; CodeMirror maps it through this insertion.
      view.dispatch({
        changes: { from: anchor.from, to: anchor.to, insert: text },
        effects: setAnchor.of(null),
        annotations: isolateHistory.of("full"),
      });
      return true;
    },
  };
}
