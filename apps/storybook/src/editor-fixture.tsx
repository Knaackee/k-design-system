import {
  KCodeEditor,
  KMarkdownEditor,
  createKEditorCollaborationDocument,
  createKEditorCollaborationTransport,
  type KCodeCompletion,
  type KEditorMode,
  type KEditorSelection,
} from "@k-design-system/ui/editors";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  KButton,
  KDictationState,
  KInline,
  KStack,
  KText,
} from "@k-design-system/ui";
import "./editor-fixture.css";

const initialMarkdown = `# Collaborative release notes

Select text to open the **contextual format bar**. Preview renders the same collaborative Markdown document.

- [x] Prepare the component contract
- [ ] Review keyboard and touch behavior
- [ ] Connect the consumer's CRDT transport

| Surface | State |
| --- | --- |
| Preview | **Read only** |
| Source | Editable |

![Preview image](/image-cropper/jordan.png)

> Persistence, rooms and permissions stay with the consuming application.

\`KMarkdownEditor\` emits controlled document and selection events.

~~~ts
const releaseState = "ready";
~~~`;

const initialCode = `type EditorParticipant = {
  id: string;
  name: string;
  color: string;
};

export function participantLabel(user: EditorParticipant) {
  return user.name.trim() || "Anonymous";
}`;

const codeCompletions: KCodeCompletion[] = [
  {
    label: "participantLabel",
    type: "function",
    detail: "Format a participant name",
  },
  {
    label: "EditorParticipant",
    type: "keyword",
    detail: "Participant contract",
  },
];

const alexSelection = [
  {
    anchor: 20,
    head: 34,
    participant: {
      id: "alex",
      name: "Alex",
      color: "#0d6b4e",
      foregroundColor: "#ffffff",
    },
  },
];

const dennisSelection = [
  {
    anchor: 48,
    head: 48,
    participant: {
      id: "dennis",
      name: "Dennis",
      color: "#4f46b7",
      foregroundColor: "#ffffff",
    },
  },
];

export function MarkdownEditorFixture() {
  return <MarkdownEditorDemo />;
}

/** Deterministic capture simulation; galleries never access a microphone. */
export function MarkdownEditorDictationFixture() {
  return <MarkdownEditorDemo dictation />;
}

export function MarkdownEditorFullscreenFixture() {
  return <MarkdownEditorDemo dictation expandable compact />;
}

export function MarkdownEditorFullscreenWithToolbarFixture() {
  return <MarkdownEditorDemo dictation expandable />;
}

function MarkdownEditorDemo({
  mobile = false,
  readOnly = false,
  dictation = false,
  expandable = false,
  compact = false,
}: {
  mobile?: boolean;
  readOnly?: boolean;
  dictation?: boolean;
  expandable?: boolean;
  compact?: boolean;
}) {
  const [markdown, setMarkdown] = useState(initialMarkdown);
  const [mode, setMode] = useState<KEditorMode>("source");
  const [state, setState] = useState(KDictationState.ready);
  const insertion = useRef<((text: string) => boolean) | null>(null);
  const cancel = useRef<(() => void) | null>(null);
  return (
    <div
      className={`editor-demo${mobile ? " editor-demo--mobile" : ""}${compact ? " editor-demo--compact-field" : ""}`}
    >
      {compact && (
        <KStack gap="control" align="stretch">
          <KText variant="label">Release-Notiz</KText>
          <KText variant="caption">
            Kleines bearbeitbares Markdown-Feld ohne Formatleiste. Die
            Vollansicht zeigt die Formatleiste mit simuliertem Diktat.
          </KText>
        </KStack>
      )}
      <div
        className={`editor-demo-shell${compact ? " editor-demo-compact-field" : ""}${!compact && state === KDictationState.recording ? " editor-demo-shell--with-actions" : ""}`}
      >
        {!compact && state === KDictationState.recording && (
          <KButton
            variant="secondary"
            onClick={() => {
              cancel.current?.();
              insertion.current = null;
              setState(KDictationState.ready);
            }}
          >
            Cancel dictation
          </KButton>
        )}
        <KMarkdownEditor
          showExpandButton={expandable}
          minHeight={compact ? 0 : undefined}
          showFixedToolbar={!compact}
          showFloatingToolbar={!compact}
          showModeSwitcher={!compact}
          showSearchButton={!compact}
          markdown={markdown}
          onChange={setMarkdown}
          mode={mode}
          onModeChange={setMode}
          readOnly={readOnly}
          ariaLabel={
            compact
              ? "Release-Notiz"
              : mobile
                ? "Mobile Markdown editor"
                : "Markdown editor"
          }
          placeholder="Write release notes…"
          labels={{ source: "Markdown", read: "Preview" }}
          dictation={
            dictation
              ? {
                  state,
                  label:
                    state === KDictationState.recording
                      ? "Finish dictation"
                      : "Start dictation",
                  onStart: (insert, stop) => {
                    insertion.current = insert;
                    cancel.current = stop;
                    setState(KDictationState.recording);
                  },
                  onStop: () => {
                    insertion.current?.("Dictated release update. ");
                    insertion.current = null;
                    setState(KDictationState.ready);
                  },
                }
              : undefined
          }
        />
      </div>
    </div>
  );
}

export function MarkdownEditorMobileFixture() {
  return <MarkdownEditorDemo mobile />;
}

export function MarkdownEditorReadOnlyFixture() {
  return <MarkdownEditorDemo readOnly />;
}

export function CodeEditorFixture() {
  const [code, setCode] = useState(initialCode);
  const diagnostics = useMemo(
    () => [
      {
        from: code.indexOf("Anonymous"),
        to: code.indexOf("Anonymous") + "Anonymous".length,
        severity: "info" as const,
        message: "This fallback label can be configured by the consumer.",
      },
    ],
    [code],
  );
  return (
    <div className="editor-demo">
      <div className="editor-demo-shell">
        <KCodeEditor
          value={code}
          onChange={setCode}
          language="typescript"
          diagnostics={diagnostics}
          completions={codeCompletions}
          lineWrapping
          minHeight={0}
        />
      </div>
    </div>
  );
}

export function CodeEditorMobileFixture() {
  const [code, setCode] = useState(initialCode);
  return (
    <div className="editor-demo editor-demo--mobile">
      <div className="editor-demo-shell">
        <KCodeEditor
          value={code}
          onChange={setCode}
          language="typescript"
          completions={codeCompletions}
          lineWrapping
          minHeight={0}
        />
      </div>
    </div>
  );
}

export function EditorCollaborationFixture() {
  const [{ first, second, firstTransport, secondTransport }] = useState(() => {
    const first = createKEditorCollaborationDocument({
      id: "editor-demo-markdown",
      kind: "text",
      initialText: initialMarkdown,
    });
    const second = createKEditorCollaborationDocument({
      id: first.id,
      kind: "text",
    });
    const firstTransport = createKEditorCollaborationTransport(first);
    const secondTransport = createKEditorCollaborationTransport(second);
    secondTransport.applyUpdate(firstTransport.encodeUpdate());
    return { first, second, firstTransport, secondTransport };
  });
  const [connected, setConnected] = useState(true);
  const online = useRef(true);
  const [alex, setAlex] = useState(alexSelection);
  const [dennis, setDennis] = useState(dennisSelection);
  useEffect(() => {
    const stopFirst = firstTransport.subscribe((update) => {
      if (online.current) secondTransport.applyUpdate(update);
    });
    const stopSecond = secondTransport.subscribe((update) => {
      if (online.current) firstTransport.applyUpdate(update);
    });
    return () => {
      stopFirst();
      stopSecond();
    };
  }, [firstTransport, secondTransport]);

  function toggleConnection() {
    online.current = !online.current;
    setConnected(online.current);
    if (online.current) {
      const fromDennis = firstTransport.encodeUpdate(
        secondTransport.encodeStateVector(),
      );
      const fromAlex = secondTransport.encodeUpdate(
        firstTransport.encodeStateVector(),
      );
      secondTransport.applyUpdate(fromDennis);
      firstTransport.applyUpdate(fromAlex);
    }
  }

  return (
    <div className="editor-demo">
      <div className="editor-demo-shell editor-demo-shell--with-actions">
        <KInline
          gap="action"
          wrap
          className="editor-demo-collaboration-actions"
        >
          <KButton variant="secondary" onClick={toggleConnection}>
            {connected ? "Disconnect Alex" : "Reconnect Alex"}
          </KButton>
          <KText variant="caption">
            Yjs demo. Each editor keeps its own replica. Reconnect merges
            offline edits.
          </KText>
        </KInline>
        <div className="editor-demo-grid">
          <div className="editor-demo-pane">
            <header>
              <span>Dennis</span>
              <span>Desktop</span>
            </header>
            <KMarkdownEditor
              markdown=""
              collaborationDocument={first}
              showFixedToolbar={false}
              remoteSelections={connected ? alex : undefined}
              onSelectionChange={(selection: KEditorSelection) =>
                setDennis([
                  {
                    ...selection,
                    participant: dennisSelection[0]!.participant,
                  },
                ])
              }
              ariaLabel="Dennis Markdown editor"
            />
          </div>
          <div className="editor-demo-pane">
            <header>
              <span>Alex</span>
              <span>Second client</span>
            </header>
            <KMarkdownEditor
              markdown=""
              collaborationDocument={second}
              showFixedToolbar={false}
              remoteSelections={connected ? dennis : undefined}
              onSelectionChange={(selection: KEditorSelection) =>
                setAlex([
                  { ...selection, participant: alexSelection[0]!.participant },
                ])
              }
              ariaLabel="Alex Markdown editor"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
