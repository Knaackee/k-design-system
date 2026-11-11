import { EditorContent } from "@tiptap/react";
import { KMarkdownPreview } from "./markdown-preview.js";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { CSSProperties, ReactNode } from "react";
import {
  KDictationAction,
  KDictationState,
} from "../forms/dictation-action.js";
import {
  beginKEditorDictation,
  cancelKEditorDictation,
  insertKEditorDictation,
} from "./dictation.js";
import { KIconButton } from "../actions/icon-button.js";
import {
  resolveKEditorCollaborationDocument,
  seedKEditorCollaborationText,
} from "./collaboration.js";
import {
  KEditorFormatBar,
  kDefaultMarkdownFormatActions,
  type KMarkdownFormatAction,
} from "./format-bar.js";
import { KCodeEditor, type KCodeEditorHandle } from "./code-editor.js";
import { renderedSource } from "./code-source-map.js";
import {
  MarkdownLinkDialog,
  defaultMarkdownLinkLabels,
  markdownLinkUrl,
} from "./markdown-link-dialog.js";
import {
  kDefaultEditorLabels,
  type KEditorMode,
  type KEditorSelection,
  type KEditorTransaction,
  type KRemoteSelection,
} from "./types.js";

import type { KMarkdownEditorProps } from "./markdown-editor-types.js";
import { markdownChange, type MarkdownChange } from "./markdown-formatting.js";
import { MarkdownEditorFullscreen } from "./markdown-editor-fullscreen.js";

export type { KMarkdownEditorProps } from "./markdown-editor-types.js";

interface LinkRequest {
  value: string;
  selection: KEditorSelection;
  editor: KCodeEditorHandle;
}

const emptyRemoteSelections: KRemoteSelection[] = [];

export function KMarkdownEditor({
  markdown,
  markdownOptions,
  onLinkActivate,
  onLinkRequested,
  linkLabels,
  renderImage,
  onChange,
  mode: controlledMode,
  defaultMode = "source",
  onModeChange,
  onSelectionChange,
  readOnly = false,
  placeholder = "Write something…",
  contentMaxWidth,
  minHeight,
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
  showExpandButton = false,
  expandLabel = "Expand editor",
  collapseLabel = "Return to editor",
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
  const sourceVisited = useRef(mode === "source");
  if (mode === "source") sourceVisited.current = true;
  const [draft, setDraft] = useState({
    markdown,
    collaborationDocument,
    value: markdown,
  });
  if (
    draft.collaborationDocument !== collaborationDocument ||
    (!collaborationDocument && draft.markdown !== markdown)
  ) {
    setDraft({ markdown, collaborationDocument, value: markdown });
  }
  const sourceDraft = draft.value;
  const sourceValue = useRef(sourceDraft);
  sourceValue.current = sourceDraft;
  const [selection, setSelection] = useState<KEditorSelection>({
    anchor: 0,
    head: 0,
  });
  const [floatingPosition, setFloatingPosition] = useState<CSSProperties>();
  useEffect(() => {
    setSelection({ anchor: 0, head: 0 });
    setFloatingPosition(undefined);
  }, [collaborationDocument]);
  const sourceRef = useRef<KCodeEditorHandle>(null);
  const sourceWritable = useRef(false);
  sourceWritable.current =
    !readOnly && mode === "source" && richEditor === undefined;
  const setSourceRef = useCallback(
    (editor: KCodeEditorHandle | null) => {
      sourceRef.current = editor;
      if (typeof sourceEditorRef === "function") {
        const cleanup = sourceEditorRef(editor);
        if (cleanup)
          return () => {
            sourceRef.current = null;
            cleanup();
          };
      } else if (sourceEditorRef) sourceEditorRef.current = editor;
    },
    [sourceEditorRef],
  );
  const sourceShellRef = useRef<HTMLDivElement>(null);
  const [linkRequest, setLinkRequest] = useState<LinkRequest>();
  const requestInProgress = useRef(false);

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

  useEffect(() => {
    if (!collaborationDocument || richEditor !== undefined) return;
    const document = resolveKEditorCollaborationDocument(
      collaborationDocument,
      "text",
    );
    seedKEditorCollaborationText(document, markdown);
    const text = document.getText("content");
    const update = () => {
      const value = text.toString();
      sourceValue.current = value;
      setDraft({ markdown, collaborationDocument, value });
    };
    text.observe(update);
    update();
    return () => text.unobserve(update);
  }, [collaborationDocument, markdown, richEditor]);

  const linkIsCurrent = Boolean(
    linkRequest &&
    sourceWritable.current &&
    linkRequest.value === sourceDraft &&
    linkRequest.editor === sourceRef.current,
  );
  useEffect(() => {
    if (linkRequest && !linkIsCurrent) setLinkRequest(undefined);
  }, [linkRequest, linkIsCurrent]);

  function changeMode(next: KEditorMode) {
    if (controlledMode === undefined) setInternalMode(next);
    onModeChange?.(next);
  }

  function changeSource(next: string, transaction: KEditorTransaction) {
    sourceValue.current = next;
    setDraft({ markdown, collaborationDocument, value: next });
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

  function applyChange(change: MarkdownChange, editor = sourceRef.current) {
    editor?.replaceRange(
      change.from,
      change.to,
      change.insert,
      change.selection,
    );
  }

  function applyLink(request: LinkRequest, result: string | null | undefined) {
    const href = result && markdownLinkUrl(result);
    if (
      !href ||
      !sourceWritable.current ||
      request.value !== sourceValue.current ||
      request.editor !== sourceRef.current
    )
      return;
    applyChange(
      markdownChange(
        renderedSource(request.value),
        request.selection,
        "link",
        href,
      ),
      request.editor,
    );
  }

  function closeLink(request: LinkRequest, result?: string) {
    setLinkRequest(undefined);
    applyLink(request, result);
    requestAnimationFrame(() => {
      if (sourceWritable.current && request.editor === sourceRef.current)
        request.editor.focus();
    });
  }

  async function requestLink() {
    if (requestInProgress.current || linkRequest || !sourceRef.current) return;
    const request = {
      value: sourceValue.current,
      selection,
      editor: sourceRef.current,
    };
    if (!onLinkRequested) {
      setLinkRequest(request);
      return;
    }
    requestInProgress.current = true;
    try {
      applyLink(request, await onLinkRequested(request.selection));
    } catch {
      // A failed consumer request leaves the source unchanged.
    } finally {
      requestInProgress.current = false;
    }
  }

  function applyFormat(action: KMarkdownFormatAction) {
    if (!sourceWritable.current) return;
    if (action === "undo") {
      sourceRef.current?.undo();
      return;
    }
    if (action === "redo") {
      sourceRef.current?.redo();
      return;
    }
    if (action === "link") {
      void requestLink();
      return;
    }
    applyChange(
      markdownChange(renderedSource(sourceValue.current), selection, action),
    );
  }

  const richDictationAction =
    dictation && !readOnly ? (
      <KDictationAction
        state={dictation.state}
        audioLevel={dictation.audioLevel}
        label={dictation.label}
        onPressed={() => {
          if (dictation.state === KDictationState.recording) dictation.onStop();
          else if (richEditor && beginKEditorDictation(richEditor))
            dictation.onStart(
              (text) => insertKEditorDictation(richEditor, text),
              () => cancelKEditorDictation(richEditor),
            );
        }}
      />
    ) : null;
  const toolbar =
    richEditor !== undefined
      ? typeof richToolbar === "function"
        ? richToolbar(richDictationAction)
        : richToolbar
      : null;

  const renderEditor = (expandAction: ReactNode, expanded: boolean) => (
    <section
      className={`k-markdown-editor ${className}`}
      data-mode={mode}
      data-has-mode-switcher={showModeSwitcher || undefined}
      data-has-expand-action={Boolean(expandAction) || undefined}
      data-has-content-width={contentMaxWidth !== undefined || undefined}
      style={
        {
          "--k-editor-content-max-width":
            typeof contentMaxWidth === "number"
              ? `${contentMaxWidth}px`
              : contentMaxWidth,
        } as CSSProperties
      }
    >
      {richEditor !== undefined ? (
        <>
          <div className="k-markdown-editor-rich">
            <EditorContent editor={richEditor} />
            {richOverlay}
          </div>
          {expandAction && toolbar ? (
            <div className="k-markdown-editor-rich-toolbar">{toolbar}</div>
          ) : (
            toolbar
          )}
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

          {(sourceVisited.current || collaborationDocument) && (
            <div
              ref={sourceShellRef}
              className="k-markdown-editor-source"
              style={mode === "source" ? undefined : { display: "none" }}
              inert={mode !== "source"}
            >
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
                ref={setSourceRef}
                value={sourceDraft}
                onChange={changeSource}
                onSelectionChange={updateSelection}
                language="markdown"
                readOnly={readOnly}
                placeholder={placeholder}
                minHeight={minHeight}
                labels={labelOverrides}
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
            </div>
          )}
          <div
            className="k-markdown-editor-surface"
            data-readonly="true"
            style={mode === "read" ? { minHeight } : { display: "none" }}
            inert={mode !== "read"}
          >
            {mode === "read" && (
              <KMarkdownPreview
                {...markdownOptions}
                markdown={sourceDraft}
                ariaLabel={`${ariaLabel} preview`}
                renderImage={renderImage ?? markdownOptions?.renderImage}
                onLinkActivate={
                  onLinkActivate ?? markdownOptions?.onLinkActivate
                }
              />
            )}
          </div>
          {(showFixedToolbar || expanded || (dictation && !showExpandButton)) &&
            mode === "source" &&
            !readOnly && (
              <div className="k-markdown-editor-dictation">
                <KEditorFormatBar
                  labels={labels}
                  actions={showFixedToolbar || expanded ? formatActions : []}
                  onAction={applyFormat}
                  floating
                  leadingAction={
                    dictation ? (
                      <span onPointerDown={(event) => event.preventDefault()}>
                        <KDictationAction
                          state={dictation.state}
                          audioLevel={dictation.audioLevel}
                          label={dictation.label}
                          onPressed={() => {
                            if (dictation.state === KDictationState.recording) {
                              dictation.onStop();
                              return;
                            }
                            const editor = sourceRef.current;
                            const anchor = editor?.beginDictation();
                            if (!anchor) return;
                            dictation.onStart((text) => {
                              if (
                                !sourceWritable.current ||
                                sourceRef.current !== editor
                              ) {
                                anchor.cancel();
                                return false;
                              }
                              return anchor.insert(text);
                            }, anchor.cancel);
                          }}
                        />
                      </span>
                    ) : undefined
                  }
                />
              </div>
            )}
        </>
      )}
      {expandAction && (
        <div className="k-markdown-editor-expand-action">{expandAction}</div>
      )}
      {linkRequest && linkIsCurrent && (
        <MarkdownLinkDialog
          labels={{ ...defaultMarkdownLinkLabels, ...linkLabels }}
          onCancel={() => closeLink(linkRequest)}
          onInsert={(url) => closeLink(linkRequest, url)}
        />
      )}
    </section>
  );

  return (
    <MarkdownEditorFullscreen
      enabled={showExpandButton}
      title={ariaLabel}
      expandLabel={expandLabel}
      collapseLabel={collapseLabel}
    >
      {renderEditor}
    </MarkdownEditorFullscreen>
  );
}
