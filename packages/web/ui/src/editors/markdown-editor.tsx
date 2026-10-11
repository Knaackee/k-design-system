import Link from "@tiptap/extension-link";
import TaskItem from "@tiptap/extension-task-item";
import TaskList from "@tiptap/extension-task-list";
import { Markdown } from "@tiptap/markdown";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import { useEffect, useMemo, useRef, useState } from "react";
import type { CSSProperties, ReactNode, Ref } from "react";
import type { Editor } from "@tiptap/react";
import {
  KDictationAction,
  KDictationAnchor,
  KDictationState,
} from "../forms/dictation-action.js";
import {
  beginKEditorDictation,
  cancelKEditorDictation,
  insertKEditorDictation,
} from "./dictation.js";
import { KIconButton } from "../actions/icon-button.js";
import type { KEditorCollaborationDocument } from "./collaboration.js";
import {
  KEditorFormatBar,
  kDefaultMarkdownFormatActions,
  type KMarkdownFormatAction,
} from "./format-bar.js";
import { KCodeEditor, type KCodeEditorHandle } from "./code-editor.js";
import {
  kDefaultEditorLabels,
  type KEditorLabels,
  type KEditorMode,
  type KEditorParticipant,
  type KEditorSelection,
  type KEditorTransaction,
  type KRemoteSelection,
} from "./types.js";

export interface KMarkdownEditorProps {
  markdown: string;
  onChange?: (markdown: string, transaction: KEditorTransaction) => void;
  mode?: KEditorMode;
  defaultMode?: KEditorMode;
  onModeChange?: (mode: KEditorMode) => void;
  onSelectionChange?: (selection: KEditorSelection) => void;
  readOnly?: boolean;
  placeholder?: string;
  labels?: Partial<KEditorLabels>;
  formatActions?: KMarkdownFormatAction[];
  showFixedToolbar?: boolean;
  showFloatingToolbar?: boolean;
  showModeSwitcher?: boolean;
  showSearchButton?: boolean;
  remoteSelections?: KRemoteSelection[];
  collaborationDocument?: KEditorCollaborationDocument;
  participants?: KEditorParticipant[];
  sourceEditorRef?: Ref<KCodeEditorHandle>;
  onFocus?: () => void;
  onBlur?: () => void;
  ariaLabel?: string;
  className?: string;
  /** Host-owned rich editor: preserves its CRDT document, history and presence. */
  richEditor?: Editor | null;
  richToolbar?: ReactNode | ((dictationAction: ReactNode) => ReactNode);
  richOverlay?: ReactNode;
  /** Optional capture UI; microphone and transcription remain with the host. */
  dictation?: {
    state: KDictationState;
    audioLevel?: number;
    label: string;
    onStart: (insert: (text: string) => boolean, cancel: () => void) => void;
    onStop: () => void;
  };
}

interface MarkdownChange {
  from: number;
  to: number;
  insert: string;
  selection: KEditorSelection;
}

const emptyRemoteSelections: KRemoteSelection[] = [];

function wrapSelection(
  markdown: string,
  selection: KEditorSelection,
  before: string,
  after = before,
): MarkdownChange {
  const from = Math.min(selection.anchor, selection.head);
  const to = Math.max(selection.anchor, selection.head);
  const selected = markdown.slice(from, to);
  const insert = `${before}${selected}${after}`;
  const anchor = from + before.length;
  return {
    from,
    to,
    insert,
    selection: { anchor, head: anchor + selected.length },
  };
}

function prefixLines(
  markdown: string,
  selection: KEditorSelection,
  prefix: string | ((index: number) => string),
): MarkdownChange {
  const from = Math.min(selection.anchor, selection.head);
  const to = Math.max(selection.anchor, selection.head);
  const lineStart = markdown.lastIndexOf("\n", Math.max(0, from - 1)) + 1;
  const nextBreak = markdown.indexOf("\n", to);
  const lineEnd = nextBreak < 0 ? markdown.length : nextBreak;
  const selected = markdown.slice(lineStart, lineEnd);
  const insert = selected
    .split("\n")
    .map(
      (line, index) =>
        `${typeof prefix === "function" ? prefix(index) : prefix}${line}`,
    )
    .join("\n");
  return {
    from: lineStart,
    to: lineEnd,
    insert,
    selection: { anchor: lineStart, head: lineStart + insert.length },
  };
}

function markdownChange(
  markdown: string,
  selection: KEditorSelection,
  action: KMarkdownFormatAction,
  href?: string,
): MarkdownChange {
  if (action === "bold") return wrapSelection(markdown, selection, "**");
  if (action === "italic") return wrapSelection(markdown, selection, "_");
  if (action === "strike") return wrapSelection(markdown, selection, "~~");
  if (action === "code") return wrapSelection(markdown, selection, "`");
  if (action === "link") {
    const from = Math.min(selection.anchor, selection.head);
    const to = Math.max(selection.anchor, selection.head);
    const selected = markdown.slice(from, to);
    const destination = href?.trim() || "https://";
    return {
      from,
      to,
      insert: `[${selected}](${destination})`,
      selection: { anchor: from + 1, head: from + 1 + selected.length },
    };
  }
  if (action === "bulletList") return prefixLines(markdown, selection, "- ");
  if (action === "orderedList")
    return prefixLines(markdown, selection, (index) => `${index + 1}. `);
  if (action === "taskList") return prefixLines(markdown, selection, "- [ ] ");
  if (action === "quote") return prefixLines(markdown, selection, "> ");
  return wrapSelection(markdown, selection, "```\n", "\n```");
}

export function KMarkdownEditor({
  markdown,
  onChange,
  mode: controlledMode,
  defaultMode = "source",
  onModeChange,
  onSelectionChange,
  readOnly = false,
  placeholder = "Write something…",
  labels: labelOverrides,
  formatActions = kDefaultMarkdownFormatActions,
  showFixedToolbar = true,
  showFloatingToolbar = true,
  showModeSwitcher = true,
  remoteSelections = emptyRemoteSelections,
  collaborationDocument,
  participants = [],
  sourceEditorRef,
  showSearchButton = true,
  onFocus,
  onBlur,
  ariaLabel = "Markdown editor",
  className = "",
  richEditor,
  richToolbar,
  richOverlay,
  dictation,
}: KMarkdownEditorProps) {
  const [internalMode, setInternalMode] = useState(defaultMode);
  const mode = controlledMode ?? internalMode;
  const [sourceDraft, setSourceDraft] = useState(markdown);
  const [selection, setSelection] = useState<KEditorSelection>({
    anchor: 0,
    head: 0,
  });
  const [floatingPosition, setFloatingPosition] = useState<CSSProperties>();
  const sourceRef = useRef<KCodeEditorHandle>(null);
  const dictationWritable = useRef(false);
  dictationWritable.current = !readOnly && mode === "source";
  useEffect(
    () => () => {
      dictationWritable.current = false;
    },
    [],
  );
  const sourceShellRef = useRef<HTMLDivElement>(null);
  const lastEmitted = useRef(markdown);
  const [dictationRect, setDictationRect] = useState<CSSProperties>();
  const labelKey = JSON.stringify(
    Object.entries(labelOverrides ?? {}).sort(([left], [right]) =>
      left.localeCompare(right),
    ),
  );
  const labels = useMemo(
    () => ({ ...kDefaultEditorLabels, ...labelOverrides }),
    // The public labels object may be recreated by controlled consumers.
    // Reconfigure the editor only when a label value actually changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [labelKey],
  );

  const preview = useEditor({
    extensions: [
      StarterKit.configure({ link: false }),
      Link.configure({ openOnClick: true, autolink: true }),
      TaskList,
      TaskItem.configure({ nested: true }),
      Markdown.configure({ markedOptions: { gfm: true } }),
    ],
    content: markdown,
    contentType: "markdown",
    editable: false,
    editorProps: {
      attributes: {
        class: "k-markdown-editor-content",
        "aria-label": `${ariaLabel} preview`,
      },
    },
  });

  useEffect(() => {
    if (markdown === lastEmitted.current) return;
    setSourceDraft(markdown);
  }, [markdown]);

  useEffect(() => {
    if (!preview) return;
    preview.commands.setContent(sourceDraft, {
      contentType: "markdown",
      emitUpdate: false,
    });
  }, [preview, sourceDraft]);

  function changeMode(next: KEditorMode) {
    if (controlledMode === undefined) setInternalMode(next);
    onModeChange?.(next);
  }

  function changeSource(next: string, transaction: KEditorTransaction) {
    setSourceDraft(next);
    lastEmitted.current = next;
    onChange?.(next, transaction);
  }

  function updateSelection(next: KEditorSelection) {
    setSelection(next);
    onSelectionChange?.(next);
    if (next.anchor === next.head || !sourceShellRef.current) {
      setFloatingPosition(undefined);
      return;
    }
    requestAnimationFrame(() => {
      const selectionRect = sourceRef.current?.getSelectionRect();
      const shellRect = sourceShellRef.current?.getBoundingClientRect();
      if (!selectionRect || !shellRect) return;
      setFloatingPosition({
        left: Math.max(8, selectionRect.left - shellRect.left),
        top: Math.max(8, selectionRect.top - shellRect.top - 52),
      });
    });
  }

  function applyFormat(action: KMarkdownFormatAction) {
    if (action === "undo") {
      sourceRef.current?.undo();
      return;
    }
    if (action === "redo") {
      sourceRef.current?.redo();
      return;
    }
    let href: string | undefined;
    if (action === "link") {
      const answer = window.prompt("Link URL", "https://");
      if (answer === null) return;
      href = answer;
    }
    const change = markdownChange(sourceDraft, selection, action, href);
    sourceRef.current?.replaceRange(
      change.from,
      change.to,
      change.insert,
      change.selection,
    );
  }

  return (
    <section
      className={`k-markdown-editor ${className}`}
      data-mode={mode}
      data-has-mode-switcher={showModeSwitcher || undefined}
    >
      {richEditor !== undefined ? (
        <>
          <div className="k-markdown-editor-rich">
            <EditorContent editor={richEditor} />
            {richOverlay}
          </div>
          {typeof richToolbar === "function"
            ? richToolbar(
                dictation && !readOnly ? (
                  <KDictationAction
                    state={dictation.state}
                    audioLevel={dictation.audioLevel}
                    label={dictation.label}
                    onPressed={() => {
                      if (dictation.state === KDictationState.recording)
                        dictation.onStop();
                      else if (richEditor && beginKEditorDictation(richEditor))
                        dictation.onStart(
                          (text) => insertKEditorDictation(richEditor, text),
                          () => cancelKEditorDictation(richEditor),
                        );
                    }}
                  />
                ) : null,
              )
            : richToolbar}
        </>
      ) : (
        <>
          {showModeSwitcher && (
            <div className="k-editor-mode-switcher">
              <KIconButton
                icon={mode === "source" ? "eye" : "pen"}
                label={mode === "source" ? labels.read : labels.source}
                variant={mode === "read" ? "primary" : "ghost"}
                aria-pressed={mode === "read"}
                onClick={() =>
                  changeMode(mode === "source" ? "read" : "source")
                }
              />
            </div>
          )}

          {mode === "source" ? (
            <div ref={sourceShellRef} className="k-markdown-editor-source">
              {showFloatingToolbar &&
                !readOnly &&
                selection.anchor !== selection.head &&
                floatingPosition && (
                  <div
                    className="k-markdown-editor-context-toolbar"
                    style={floatingPosition}
                  >
                    <KEditorFormatBar
                      labels={labels}
                      actions={formatActions}
                      onAction={applyFormat}
                      floating
                    />
                  </div>
                )}
              <KCodeEditor
                ref={(editor) => {
                  sourceRef.current = editor;
                  if (typeof sourceEditorRef === "function")
                    sourceEditorRef(editor);
                  else if (sourceEditorRef) sourceEditorRef.current = editor;
                }}
                value={sourceDraft}
                onChange={changeSource}
                onSelectionChange={updateSelection}
                language="markdown"
                readOnly={readOnly}
                placeholder={placeholder}
                showToolbar={false}
                showSearchButton={showSearchButton}
                lineNumbers={false}
                showDiagnosticGutter={false}
                lineWrapping
                remoteSelections={remoteSelections}
                participants={participants}
                collaborationDocument={collaborationDocument}
                ariaLabel={ariaLabel}
                onFocus={onFocus}
                onBlur={onBlur}
              />
              {dictationRect &&
                (dictation?.state === KDictationState.recording ||
                  dictation?.state === KDictationState.processing) && (
                  <span style={dictationRect}>
                    <KDictationAnchor state={dictation.state} />
                  </span>
                )}
            </div>
          ) : (
            <div className="k-markdown-editor-surface" data-readonly="true">
              <EditorContent editor={preview} />
            </div>
          )}
          {(showFixedToolbar || dictation) &&
            mode === "source" &&
            !readOnly && (
              <div className="k-markdown-editor-dictation">
                <KEditorFormatBar
                  labels={labels}
                  actions={formatActions}
                  onAction={applyFormat}
                  floating
                  leadingAction={
                    dictation ? (
                      <KDictationAction
                        state={dictation.state}
                        audioLevel={dictation.audioLevel}
                        label={dictation.label}
                        onPressed={() => {
                          if (dictation.state === KDictationState.recording) {
                            dictation.onStop();
                            return;
                          }
                          const rect = sourceRef.current?.getSelectionRect();
                          const shell =
                            sourceShellRef.current?.getBoundingClientRect();
                          if (rect && shell)
                            setDictationRect({
                              position: "absolute",
                              top: rect.top - shell.top,
                              left: rect.left - shell.left,
                            });
                          const snapshot = sourceDraft;
                          const target = { ...selection };
                          dictation.onStart(
                            (text) => {
                              setDictationRect(undefined);
                              if (
                                !dictationWritable.current ||
                                !sourceRef.current ||
                                lastEmitted.current !== snapshot ||
                                !text.trim()
                              )
                                return false;
                              const from = Math.min(target.anchor, target.head),
                                to = Math.max(target.anchor, target.head);
                              sourceRef.current.replaceRange(from, to, text, {
                                anchor: from + text.length,
                                head: from + text.length,
                              });
                              return true;
                            },
                            () => setDictationRect(undefined),
                          );
                        }}
                      />
                    ) : undefined
                  }
                />
              </div>
            )}
        </>
      )}
    </section>
  );
}
