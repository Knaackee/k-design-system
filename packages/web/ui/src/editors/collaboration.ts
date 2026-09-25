import * as Y from "yjs";

export type KEditorDocumentKind = "rich" | "text";

export interface KEditorCollaborationDocument {
  readonly kind: KEditorDocumentKind;
  readonly id: string;
}

const documents = new WeakMap<KEditorCollaborationDocument, Y.Doc>();

export function createKEditorCollaborationDocument(options: {
  id: string;
  kind: KEditorDocumentKind;
  initialText?: string;
}): KEditorCollaborationDocument {
  const handle = Object.freeze({ kind: options.kind, id: options.id });
  const document = new Y.Doc();
  if (options.kind === "text" && options.initialText) {
    document.getText("content").insert(0, options.initialText);
  }
  documents.set(handle, document);
  return handle;
}

export function resolveKEditorCollaborationDocument(
  handle: KEditorCollaborationDocument,
  expectedKind: KEditorDocumentKind,
): Y.Doc {
  if (handle.kind !== expectedKind) {
    throw new TypeError(
      `Expected a ${expectedKind} collaboration document, received ${handle.kind}`,
    );
  }
  const document = documents.get(handle);
  if (!document) {
    throw new TypeError("Unknown collaboration document handle");
  }
  return document;
}
