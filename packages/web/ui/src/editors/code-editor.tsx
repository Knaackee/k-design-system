import { autocompletion } from "@codemirror/autocomplete";
import type { CompletionContext } from "@codemirror/autocomplete";
import {
  defaultKeymap,
  history,
  historyKeymap,
  redo as redoCommand,
  undo as undoCommand,
} from "@codemirror/commands";
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
import {
  Annotation,
  Compartment,
  EditorSelection,
  EditorState,
  Extension,
  Transaction,
} from "@codemirror/state";
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
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  rawTextCollaboration,
  collaborativeUndo,
  collaborativeRedo,
  collaborativeHistoryKeymap,
} from "./code-collaboration.js";
import { renderedChange, renderedSource } from "./code-source-map.js";
import { KIconButton } from "../actions/icon-button.js";
import {
  createKDictationAnchor,
  KDictationState,
} from "../forms/dictation-action.js";
import {
  resolveKEditorCollaborationDocument,
  seedKEditorCollaborationText,
  type KEditorCollaborationDocument,
} from "./collaboration.js";
import { createKEditorSearchPanel } from "./editor-search-panel.js";
import {
  kDefaultEditorLabels,
  type KCodeCompletion,
  type KCodeDiagnostic,
  type KEditorLabels,
  type KEditorParticipant,
  type KEditorSelection,
  type KEditorTransaction,
  type KRemoteSelection,
} from "./types.js";

export type KCodeLanguage =
  "plain" | "javascript" | "typescript" | "json" | "markdown";

const emptyDiagnostics: KCodeDiagnostic[] = [];
const emptyCompletions: KCodeCompletion[] = [];
const emptyRemoteSelections: KRemoteSelection[] = [];
const controlledValue = Annotation.define<boolean>();

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

class DictationAnchorWidget extends WidgetType {
  constructor(private readonly state: KDictationState) {
    super();
  }

  eq(other: DictationAnchorWidget) {
    return other.state === this.state;
  }

  toDOM(view: EditorView) {
    return createKDictationAnchor(this.state, view.dom.ownerDocument);
  }
}

function dictationAnchorExtension(
  state: KDictationState | undefined,
  offset: number | undefined,
): Extension {
  if (
    offset === undefined ||
    (state !== KDictationState.recording &&
      state !== KDictationState.processing)
  )
    return [];
  return EditorView.decorations.compute(["doc"], (editorState) =>
    Decoration.set([
      Decoration.widget({
        widget: new DictationAnchorWidget(state),
        side: 1,
      }).range(Math.max(0, Math.min(editorState.doc.length, offset))),
    ]),
  );
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
  participants?: KEditorParticipant[];
  collaborationDocument?: KEditorCollaborationDocument;
  ariaLabel?: string;
  minHeight?: number;
  className?: string;
  onFocus?: () => void;
  onBlur?: () => void;
  /** Visual-only insertion anchor. The host maps this offset through its CRDT. */
  dictationState?: KDictationState;
  dictationOffset?: number;
}

export interface KCodeEditorHandle {
  focus: () => void;
  openSearch: () => void;
  undo: () => boolean;
  redo: () => boolean;
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
      participants = [],
      collaborationDocument,
      ariaLabel = "Code editor",
      minHeight = 280,
      className = "",
      onFocus,
      onBlur,
      dictationState,
      dictationOffset,
    }: KCodeEditorProps,
    forwardedRef,
  ) {
    const host = useRef<HTMLDivElement>(null);
    const viewRef = useRef<EditorView | null>(null);
    const [searchOpen, setSearchOpen] = useState(false);
    const changeRef = useRef(onChange);
    const selectionRef = useRef(onSelectionChange);
    const reportedSelection = useRef<KEditorSelection>(undefined);
    const configurationCompartment = useRef(new Compartment());
    const presenceCompartment = useRef(new Compartment());
    const dictationCompartment = useRef(new Compartment());
    const labelKey = JSON.stringify(
      Object.entries(labelOverrides ?? {}).sort(([left], [right]) =>
        left.localeCompare(right),
      ),
    );
    const labels = useMemo(
      () => ({ ...kDefaultEditorLabels, ...labelOverrides }),
      // Controlled consumers commonly recreate partial label objects.
      // Keep CodeMirror history intact while their values stay unchanged.
      // eslint-disable-next-line react-hooks/exhaustive-deps
      [labelKey],
    );

    changeRef.current = onChange;
    selectionRef.current = onSelectionChange;
    const reportSelection = useCallback((anchor: number, head: number) => {
      const previous = reportedSelection.current;
      if (anchor === previous?.anchor && head === previous?.head) return;
      const selection = { anchor, head };
      reportedSelection.current = selection;
      selectionRef.current?.(selection);
    }, []);

    useImperativeHandle(
      forwardedRef,
      () => ({
        openSearch() {
          const view = viewRef.current;
          if (view) openSearchPanel(view);
        },
        focus() {
          viewRef.current?.focus();
        },
        undo() {
          const view = viewRef.current;
          if (!view || view.state.readOnly) return false;
          view.focus();
          return collaborationDocument
            ? collaborativeUndo(view)
            : undoCommand(view);
        },
        redo() {
          const view = viewRef.current;
          if (!view || view.state.readOnly) return false;
          view.focus();
          return collaborationDocument
            ? collaborativeRedo(view)
            : redoCommand(view);
        },
        replaceRange(from, to, insert, selection) {
          const view = viewRef.current;
          if (!view || view.state.readOnly) return;
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
      [collaborationDocument],
    );

    const configuration = useMemo(() => {
      const extensions: Extension[] = [
        search({
          top: true,
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
          const selection = update.state.selection.main;
          const previous = update.startState.selection.main;
          const { anchor, head } = selection;
          if (
            update.docChanged &&
            !update.transactions.some((tr) => tr.annotation(controlledValue))
          ) {
            const next = collaborationDocument
              ? resolveKEditorCollaborationDocument(
                  collaborationDocument,
                  "text",
                )
                  .getText("content")
                  .toString()
              : update.state.doc.toString();
            changeRef.current?.(next, {
              value: next,
              selection: { anchor, head },
              origin: update.transactions.some((tr) =>
                tr.annotation(Transaction.remote),
              )
                ? "remote"
                : "local",
            });
          }
          if (anchor !== previous.anchor || head !== previous.head)
            reportSelection(anchor, head);
        }),
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
      reportSelection,
      showDiagnosticGutter,
      showLineNumbers,
    ]);
    const initial = useRef({ configuration, value, diagnosticItems });
    initial.current = { configuration, value, diagnosticItems };

    useEffect(() => {
      if (!host.current) return;
      reportedSelection.current = undefined;
      const document = collaborationDocument
        ? resolveKEditorCollaborationDocument(collaborationDocument, "text")
        : undefined;
      if (document)
        seedKEditorCollaborationText(document, initial.current.value);
      const text = document?.getText("content");
      const view = new EditorView({
        state: EditorState.create({
          doc: renderedSource(text?.toString() ?? initial.current.value),
          extensions: [
            text ? rawTextCollaboration(text) : history(),
            keymap.of([
              ...(text ? collaborativeHistoryKeymap : historyKeymap),
              ...defaultKeymap,
              ...searchKeymap,
            ]),
            configurationCompartment.current.of(initial.current.configuration),
            presenceCompartment.current.of(
              remoteSelectionPlugin(emptyRemoteSelections),
            ),
            dictationCompartment.current.of(
              dictationAnchorExtension(undefined, undefined),
            ),
          ],
        }),
        parent: host.current,
      });
      viewRef.current = view;
      view.dispatch(
        setDiagnostics(
          view.state,
          diagnostics(initial.current.diagnosticItems),
        ),
      );
      return () => {
        view.destroy();
        viewRef.current = null;
      };
    }, [collaborationDocument]);

    useEffect(() => {
      const view = viewRef.current;
      if (
        !view ||
        configurationCompartment.current.get(view.state) === configuration
      )
        return;
      view.dispatch({
        effects: configurationCompartment.current.reconfigure(configuration),
      });
    }, [configuration]);

    useEffect(() => {
      viewRef.current?.dispatch({
        effects: presenceCompartment.current.reconfigure(
          remoteSelectionPlugin(remoteSelections),
        ),
      });
    }, [collaborationDocument, remoteSelections]);

    useEffect(() => {
      viewRef.current?.dispatch({
        effects: dictationCompartment.current.reconfigure(
          dictationAnchorExtension(dictationState, dictationOffset),
        ),
      });
    }, [collaborationDocument, dictationOffset, dictationState]);

    useEffect(() => {
      const view = viewRef.current;
      if (!view || collaborationDocument) return;
      const before = view.state.doc.toString();
      const next = renderedSource(value);
      if (before === next) return;
      view.dispatch({
        changes: renderedChange(before, next),
        annotations: [
          controlledValue.of(true),
          Transaction.addToHistory.of(false),
        ],
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
        className={`k-code-editor ${language === "markdown" ? "k-markdown-editor-source" : ""} ${className}`}
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
          onFocus={(event) => {
            if (event.currentTarget.contains(event.relatedTarget)) return;
            onFocus?.();
            const selection = viewRef.current?.state.selection.main;
            if (selection) reportSelection(selection.anchor, selection.head);
          }}
          onBlur={(event) => {
            if (!event.currentTarget.contains(event.relatedTarget)) onBlur?.();
          }}
        />
        {(participants.length > 0 || remoteSelections.length > 0) && (
          <div className="k-code-editor-presence" aria-label="Aktive Personen">
            {(participants.length
              ? participants
              : remoteSelections.map((selection) => selection.participant)
            ).map((participant) => (
              <span
                key={participant.id}
                title={participant.name}
                aria-label={participant.name}
                style={{ backgroundColor: participant.color }}
              />
            ))}
          </div>
        )}
      </section>
    );
  },
);
