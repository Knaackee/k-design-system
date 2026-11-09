import * as Y from "yjs";

export type KEditorDocumentKind = "rich" | "text";

export interface KEditorCollaborationDocument {
  readonly kind: KEditorDocumentKind;
  readonly id: string;
}

/** Public binary boundary; transports never need the underlying Yjs object. */
export interface KEditorCollaborationTransport {
  applyUpdate(update: Uint8Array): void;
  encodeStateVector(): Uint8Array;
  encodeUpdate(stateVector?: Uint8Array): Uint8Array;
  subscribe(listener: (update: Uint8Array) => void): () => void;
  destroy(): void;
}

const remoteOrigin = Symbol.for("k-design-system.editor.transport-remote");

export function createKEditorCollaborationTransport(
  handle: KEditorCollaborationDocument,
): KEditorCollaborationTransport {
  const document = resolveKEditorCollaborationDocument(handle, handle.kind);
  return {
    applyUpdate: (update) => Y.applyUpdate(document, update, remoteOrigin),
    encodeStateVector: () => Y.encodeStateVector(document),
    encodeUpdate: (vector) => Y.encodeStateAsUpdate(document, vector),
    subscribe(listener) {
      const callback = (update: Uint8Array, origin: unknown) => {
        if (origin !== remoteOrigin) listener(update);
      };
      document.on("update", callback);
      return () => document.off("update", callback);
    },
    destroy() {
      document.destroy();
      documents.delete(handle);
    },
  };
}

/** Legacy editor seeding applies only to a document with no prior edits. */
export function seedKEditorCollaborationText(document: Y.Doc, value: string) {
  if (value && Y.decodeStateVector(Y.encodeStateVector(document)).size === 0)
    document.getText("content").insert(0, value);
}

const documents = new WeakMap<KEditorCollaborationDocument, Y.Doc>();
// Keep the opaque handle usable across module refreshes and entry-point copies.
const documentKey = Symbol.for("k-design-system.editor.document");

export function createKEditorCollaborationDocument(options: {
  id: string;
  kind: KEditorDocumentKind;
  initialText?: string;
}): KEditorCollaborationDocument {
  const document = new Y.Doc();
  const handle = Object.freeze(
    Object.defineProperty({ kind: options.kind, id: options.id }, documentKey, {
      value: document,
    }),
  );
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
  const document =
    documents.get(handle) ??
    (handle as KEditorCollaborationDocument & { [documentKey]?: Y.Doc })[
      documentKey
    ];
  if (!document) {
    throw new TypeError("Unknown collaboration document handle");
  }
  return document;
}
