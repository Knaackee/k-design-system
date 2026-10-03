import { Extension, type MappablePosition } from "@tiptap/core";
import type { Editor } from "@tiptap/react";
import { Plugin, PluginKey } from "@tiptap/pm/state";
import { Decoration, DecorationSet } from "@tiptap/pm/view";
import {
  createKDictationAnchor,
  KDictationState,
} from "../forms/dictation-action.js";

type Anchor = { from: MappablePosition; to: MappablePosition } | null;
const key = new PluginKey<Anchor>("kDictationAnchor");

/** Presentation-only insertion anchor. Transactions map it through concurrent edits. */
export const KEditorDictationExtension = Extension.create({
  name: "kDictationAnchor",
  addProseMirrorPlugins() {
    const editor = this.editor;
    return [
      new Plugin<Anchor>({
        key,
        state: {
          init: () => null,
          apply(tr, anchor) {
            const change = tr.getMeta(key) as Anchor | undefined;
            if (change !== undefined) return change;
            if (!anchor) return null;
            const from = editor.utils.getUpdatedPosition(anchor.from, tr);
            const to = editor.utils.getUpdatedPosition(anchor.to, tr);
            // Never insert into a range removed by another edit.
            return from.mapResult?.deletedAcross || to.mapResult?.deletedAcross
              ? null
              : { from: from.position, to: to.position };
          },
        },
        props: {
          decorations(state) {
            const anchor = key.getState(state);
            if (!anchor) return DecorationSet.empty;
            if (
              anchor.from.position < 1 ||
              anchor.from.position > state.doc.content.size
            )
              return DecorationSet.empty;
            return DecorationSet.create(state.doc, [
              Decoration.widget(
                anchor.from.position,
                () => {
                  return createKDictationAnchor(KDictationState.recording);
                },
                { side: 1 },
              ),
            ]);
          },
        },
      }),
    ];
  },
});

export function beginKEditorDictation(editor: Editor): boolean {
  if (
    !editor.isEditable ||
    editor.isDestroyed ||
    !editor.state.plugins.some((plugin) => plugin.spec.key === key)
  )
    return false;
  const { from, to } = editor.state.selection;
  editor.view.dispatch(
    editor.state.tr
      .setMeta(key, {
        from: editor.utils.createMappablePosition(from),
        to: editor.utils.createMappablePosition(to),
      })
      .setMeta("addToHistory", false),
  );
  return true;
}

export function cancelKEditorDictation(editor: Editor): void {
  if (!editor.isDestroyed)
    editor.view.dispatch(
      editor.state.tr.setMeta(key, null).setMeta("addToHistory", false),
    );
}

export function insertKEditorDictation(editor: Editor, text: string): boolean {
  const anchor = key.getState(editor.state);
  if (
    !anchor ||
    editor.isDestroyed ||
    !editor.isEditable ||
    !text.trim() ||
    anchor.from.position < 1
  ) {
    cancelKEditorDictation(editor);
    return false;
  }
  // One normal editor transaction: collaboration and undo see actual text only.
  const tr = editor.state.tr
    .insertText(
      text,
      anchor.from.position,
      Math.max(anchor.from.position, anchor.to.position),
    )
    .setMeta(key, null);
  editor.view.dispatch(tr.scrollIntoView());
  return true;
}
