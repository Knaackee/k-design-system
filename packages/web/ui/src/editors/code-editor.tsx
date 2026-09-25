import { autocompletion } from "@codemirror/autocomplete";
import type { CompletionContext } from "@codemirror/autocomplete";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { javascript } from "@codemirror/lang-javascript";
import { json } from "@codemirror/lang-json";
import { markdown } from "@codemirror/lang-markdown";
import {
  defaultHighlightStyle,
  HighlightStyle,
  syntaxTree,
  syntaxHighlighting,
} from "@codemirror/language";
import { classHighlighter, tags } from "@lezer/highlight";
import { Diagnostic, lintGutter, setDiagnostics } from "@codemirror/lint";
import {
  closeSearchPanel,
  openSearchPanel,
  search,
  searchKeymap,
} from "@codemirror/search";
import { EditorSelection, EditorState, Extension } from "@codemirror/state";
import {
  Decoration,
  DecorationSet,
  EditorView,
  keymap,
  ViewPlugin,
  ViewUpdate,
  WidgetType,
  lineNumbers,
  placeholder as codeMirrorPlaceholder,
} from "@codemirror/view";
import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from "react";
import { yCollab } from "y-codemirror.next";
import * as Y from "yjs";
import { KIconButton } from "../actions/icon-button.js";
import {
  resolveKEditorCollaborationDocument,
  type KEditorCollaborationDocument,
} from "./collaboration.js";
import { createKEditorSearchPanel } from "./editor-search-panel.js";
import {
  kDefaultEditorLabels,
  type KCodeCompletion,
  type KCodeDiagnostic,
  type KEditorLabels,
  type KEditorSelection,
  type KEditorTransaction,
  type KRemoteSelection,
} from "./types.js";

export type KCodeLanguage =
  "plain" | "javascript" | "typescript" | "json" | "markdown";

const emptyDiagnostics: KCodeDiagnostic[] = [];
const emptyCompletions: KCodeCompletion[] = [];
const emptyRemoteSelections: KRemoteSelection[] = [];

const kEditorHighlightStyle = HighlightStyle.define([
  { tag: tags.heading1, class: "k-syntax-heading k-syntax-heading-1" },
  { tag: tags.heading2, class: "k-syntax-heading k-syntax-heading-2" },
  {
    tag: [tags.heading3, tags.heading4, tags.heading5, tags.heading6],
    class: "k-syntax-heading",
  },
]);

function languageExtension(language: KCodeLanguage): Extension {
  if (language === "javascript") return javascript();
  if (language === "typescript") return javascript({ typescript: true });
  if (language === "json") return json();
  if (language === "markdown") return markdown();
  return [];
}

function markdownLineDecorations(): Extension {
  return ViewPlugin.fromClass(
    class {
      decorations: DecorationSet;

      constructor(view: EditorView) {
        this.decorations = this.build(view);
      }

      update(update: ViewUpdate) {
        if (update.docChanged) this.decorations = this.build(update.view);
      }

      build(view: EditorView) {
        const lineClasses = new Map<number, Set<string>>();
        syntaxTree(view.state).iterate({
          enter(node) {
            const className =
              node.name === "Blockquote"
                ? "k-markdown-line--quote"
                : node.name === "FencedCode"
                  ? "k-markdown-line--code"
                  : null;
            if (!className) return;
            const firstLine = view.state.doc.lineAt(node.from).number;
            const lastLine = view.state.doc.lineAt(node.to).number;
            for (let number = firstLine; number <= lastLine; number += 1) {
              const line = view.state.doc.line(number);
              const classes = lineClasses.get(line.from) ?? new Set<string>();
              classes.add(className);
              lineClasses.set(line.from, classes);
            }
          },
        });
        return Decoration.set(
          [...lineClasses.entries()]
            .sort(([left], [right]) => left - right)
            .map(([from, classes]) =>
              Decoration.line({
                attributes: { class: [...classes].join(" ") },
              }).range(from),
            ),
        );
      }
    },
    { decorations: (plugin) => plugin.decorations },
  );
}

class RemoteCaretWidget extends WidgetType {
  constructor(private readonly selection: KRemoteSelection) {
    super();
  }
  toDOM() {
    const caret = document.createElement("span");
    caret.className = "k-code-editor-remote-caret";
    caret.style.setProperty(
      "--k-editor-participant-color",
      this.selection.participant.color,
    );
    caret.style.setProperty(
      "--k-editor-participant-foreground",
      this.selection.participant.foregroundColor ?? "#ffffff",
    );
    const label = document.createElement("span");
    label.textContent = this.selection.participant.name;
    caret.append(label);
    return caret;
  }
}

function remoteSelectionPlugin(selections: KRemoteSelection[]): Extension {
  return ViewPlugin.fromClass(
    class {
      decorations: DecorationSet;
      constructor(view: EditorView) {
        this.decorations = this.build(view);
      }
      update(update: ViewUpdate) {
        if (update.docChanged || update.viewportChanged)
          this.decorations = this.build(update.view);
      }
      build(view: EditorView) {
        const max = view.state.doc.length;
        const ranges = selections.flatMap((selection) => {
          const anchor = Math.max(0, Math.min(max, selection.anchor));
          const head = Math.max(0, Math.min(max, selection.head));
          const from = Math.min(anchor, head);
          const to = Math.max(anchor, head);
          const result = [
            Decoration.widget({
              widget: new RemoteCaretWidget(selection),
              side: 1,
            }).range(head),
          ];
          if (to > from) {
            result.push(
              Decoration.mark({
                class: "k-code-editor-remote-selection",
                attributes: {
                  style: `--k-editor-participant-color:${selection.participant.color}`,
                },
              }).range(from, to),
            );
          }
          return result;
        });
        return Decoration.set(ranges, true);
      }
    },
    { decorations: (plugin) => plugin.decorations },
  );
}

function diagnostics(value: KCodeDiagnostic[]): Diagnostic[] {
  return value.map((diagnostic) => ({
    from: diagnostic.from,
    to: diagnostic.to,
    severity: diagnostic.severity,
    message: diagnostic.message,
  }));
}

export interface KCodeEditorProps {
  value: string;
  onChange?: (value: string, transaction: KEditorTransaction) => void;
  onSelectionChange?: (selection: KEditorSelection) => void;
  language?: KCodeLanguage;
  readOnly?: boolean;
  placeholder?: string;
  lineNumbers?: boolean;
  showDiagnosticGutter?: boolean;
  lineWrapping?: boolean;
  showToolbar?: boolean;
  showSearchButton?: boolean;
  labels?: Partial<KEditorLabels>;
  diagnostics?: KCodeDiagnostic[];
  completions?: KCodeCompletion[];
  remoteSelections?: KRemoteSelection[];
  collaborationDocument?: KEditorCollaborationDocument;
  ariaLabel?: string;
  minHeight?: number;
  className?: string;
  onFocus?: () => void;
  onBlur?: () => void;
}

export interface KCodeEditorHandle {
  focus: () => void;
  replaceRange: (
    from: number,
    to: number,
    insert: string,
    selection?: KEditorSelection,
  ) => void;
  getSelectionRect: () => {
    top: number;
    right: number;
    bottom: number;
    left: number;
  } | null;
}

export const KCodeEditor = forwardRef<KCodeEditorHandle, KCodeEditorProps>(
  function KCodeEditor(
    {
      value,
      onChange,
      onSelectionChange,
      language = "plain",
      readOnly = false,
      placeholder,
      lineNumbers: showLineNumbers = false,
      showDiagnosticGutter = false,
      lineWrapping = false,
      showToolbar = false,
      showSearchButton = true,
      labels: labelOverrides,
      diagnostics: diagnosticItems = emptyDiagnostics,
      completions = emptyCompletions,
      remoteSelections = emptyRemoteSelections,
      collaborationDocument,
      ariaLabel = "Code editor",
      minHeight = 280,
      className = "",
      onFocus,
      onBlur,
    }: KCodeEditorProps,
    forwardedRef,
  ) {
    const host = useRef<HTMLDivElement>(null);
    const viewRef = useRef<EditorView | null>(null);
    const [searchOpen, setSearchOpen] = useState(false);
    const valueRef = useRef(value);
    const changeRef = useRef(onChange);
    const selectionRef = useRef(onSelectionChange);
    const labels = useMemo(
      () => ({ ...kDefaultEditorLabels, ...labelOverrides }),
      [labelOverrides],
    );

    changeRef.current = onChange;
    selectionRef.current = onSelectionChange;

    useImperativeHandle(
      forwardedRef,
      () => ({
        focus() {
          viewRef.current?.focus();
        },
        replaceRange(from, to, insert, selection) {
          const view = viewRef.current;
          if (!view) return;
          view.dispatch({
            changes: { from, to, insert },
            selection: selection
              ? EditorSelection.range(selection.anchor, selection.head)
              : undefined,
          });
          view.focus();
        },
        getSelectionRect() {
          const view = viewRef.current;
          if (!view) return null;
          const selection = view.state.selection.main;
          const anchor = view.coordsAtPos(selection.anchor);
          const head = view.coordsAtPos(selection.head);
          if (!anchor || !head) return null;
          return {
            top: Math.min(anchor.top, head.top),
            right: Math.max(anchor.right, head.right),
            bottom: Math.max(anchor.bottom, head.bottom),
            left: Math.min(anchor.left, head.left),
          };
        },
      }),
      [],
    );

    const configuration = useMemo(() => {
      const extensions: Extension[] = [
        history(),
        keymap.of([...defaultKeymap, ...historyKeymap, ...searchKeymap]),
        search({
          createPanel: createKEditorSearchPanel(labels, setSearchOpen),
        }),
        languageExtension(language),
        syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
        syntaxHighlighting(classHighlighter),
        syntaxHighlighting(kEditorHighlightStyle),
        EditorState.readOnly.of(readOnly),
        EditorView.editable.of(!readOnly),
        EditorView.contentAttributes.of({
          "aria-label": ariaLabel,
          spellcheck: "false",
        }),
        EditorView.theme({
          ".cm-content, .cm-gutter": { minHeight: `${minHeight}px` },
        }),
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            const next = update.state.doc.toString();
            valueRef.current = next;
            const selection = {
              anchor: update.state.selection.main.anchor,
              head: update.state.selection.main.head,
            };
            changeRef.current?.(next, {
              value: next,
              selection,
              origin: "local",
            });
          }
          if (update.selectionSet) {
            selectionRef.current?.({
              anchor: update.state.selection.main.anchor,
              head: update.state.selection.main.head,
            });
          }
        }),
        remoteSelectionPlugin(remoteSelections),
      ];
      if (showDiagnosticGutter) extensions.push(lintGutter());
      if (showLineNumbers) extensions.push(lineNumbers());
      if (placeholder) extensions.push(codeMirrorPlaceholder(placeholder));
      if (lineWrapping) extensions.push(EditorView.lineWrapping);
      if (language === "markdown") extensions.push(markdownLineDecorations());
      if (completions.length) {
        extensions.push(
          autocompletion({
            override: [
              (_context: CompletionContext) => ({
                from: _context.pos,
                options: completions.map((item) => ({
                  ...item,
                  apply: item.apply ?? item.label,
                })),
              }),
            ],
          }),
        );
      }
      if (collaborationDocument) {
        const doc = resolveKEditorCollaborationDocument(
          collaborationDocument,
          "text",
        );
        extensions.push(
          yCollab(doc.getText("content"), null, {
            undoManager: new Y.UndoManager(doc.getText("content")),
          }),
        );
      }
      return extensions;
    }, [
      ariaLabel,
      collaborationDocument,
      completions,
      language,
      lineWrapping,
      labels,
      minHeight,
      placeholder,
      readOnly,
      remoteSelections,
      showDiagnosticGutter,
      showLineNumbers,
    ]);

    useEffect(() => {
      if (!host.current) return;
      if (collaborationDocument) {
        const document = resolveKEditorCollaborationDocument(
          collaborationDocument,
          "text",
        );
        const text = document.getText("content");
        if (text.length === 0 && value) text.insert(0, value);
      }
      const view = new EditorView({
        state: EditorState.create({
          doc: collaborationDocument ? undefined : value,
          extensions: configuration,
        }),
        parent: host.current,
      });
      viewRef.current = view;
      view.dispatch(setDiagnostics(view.state, diagnostics(diagnosticItems)));
      return () => {
        view.destroy();
        viewRef.current = null;
      };
    }, [configuration, collaborationDocument]);

    useEffect(() => {
      const view = viewRef.current;
      if (!view || collaborationDocument || value === view.state.doc.toString())
        return;
      view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: value },
      });
    }, [collaborationDocument, value]);

    useEffect(() => {
      if (viewRef.current) {
        viewRef.current.dispatch(
          setDiagnostics(viewRef.current.state, diagnostics(diagnosticItems)),
        );
      }
    }, [diagnosticItems]);

    return (
      <section
        className={`k-code-editor ${className}`}
        data-language={language}
        data-has-search-button={showSearchButton || undefined}
      >
        {showToolbar && (
          <div
            className="k-code-editor-toolbar"
            role="toolbar"
            aria-label="Code editor tools"
          >
            <span className="k-code-editor-language">{language}</span>
          </div>
        )}
        {showSearchButton && (
          <div className="k-code-editor-search">
            <KIconButton
              icon="search"
              label={labels.search}
              variant={searchOpen ? "primary" : "ghost"}
              aria-pressed={searchOpen}
              onClick={() => {
                const view = viewRef.current;
                if (!view) return;
                if (searchOpen) {
                  closeSearchPanel(view);
                  view.focus();
                  return;
                }
                openSearchPanel(view);
              }}
            />
          </div>
        )}
        <div
          ref={host}
          className="k-code-editor-host"
          onFocus={onFocus}
          onBlur={onBlur}
        />
      </section>
    );
  },
);
