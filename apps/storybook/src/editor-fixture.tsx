import {
  KCodeEditor,
  KMarkdownEditor,
  createKEditorCollaborationDocument,
  type KCodeCompletion,
  type KEditorMode,
} from "@k-design-system/ui/editors";
import { useMemo, useState } from "react";
import "./editor-fixture.css";

const initialMarkdown = `# Collaborative release notes

Select text to open the **contextual format bar**. Preview renders the same collaborative Markdown document.

- [x] Prepare the component contract
- [ ] Review keyboard and touch behavior
- [ ] Connect the consumer's CRDT transport

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

const sharedMarkdown = createKEditorCollaborationDocument({
  id: "editor-demo-markdown",
  kind: "text",
});

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
  const [markdown, setMarkdown] = useState(initialMarkdown);
  const [mode, setMode] = useState<KEditorMode>("source");
  return (
    <div className="editor-demo">
      <div className="editor-demo-shell">
        <KMarkdownEditor
          markdown={markdown}
          mode={mode}
          onModeChange={setMode}
          onChange={setMarkdown}
          placeholder="Write release notes…"
          labels={{ source: "Markdown", read: "Preview" }}
        />
      </div>
    </div>
  );
}

export function MarkdownEditorMobileFixture() {
  const [markdown, setMarkdown] = useState(initialMarkdown);
  const [mode, setMode] = useState<KEditorMode>("source");
  return (
    <div className="editor-demo editor-demo--mobile">
      <div className="editor-demo-shell">
        <KMarkdownEditor
          markdown={markdown}
          mode={mode}
          onModeChange={setMode}
          onChange={setMarkdown}
          placeholder="Write release notes…"
          labels={{ source: "Markdown", read: "Preview" }}
        />
      </div>
    </div>
  );
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
  return (
    <div className="editor-demo">
      <div className="editor-demo-shell">
        <div className="editor-demo-grid">
          <div className="editor-demo-pane">
            <header>
              <span>Dennis</span>
              <span>Desktop</span>
            </header>
            <KMarkdownEditor
              markdown={initialMarkdown}
              collaborationDocument={sharedMarkdown}
              showFixedToolbar={false}
              remoteSelections={alexSelection}
            />
          </div>
          <div className="editor-demo-pane">
            <header>
              <span>Alex</span>
              <span>Second client</span>
            </header>
            <KMarkdownEditor
              markdown={initialMarkdown}
              collaborationDocument={sharedMarkdown}
              showFixedToolbar={false}
              remoteSelections={dennisSelection}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
