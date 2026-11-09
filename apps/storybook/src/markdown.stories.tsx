import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import {
  KMarkdownRenderer,
  KMarkdownPreview,
  KChatConversation,
  KButton,
  KInline,
  KPage,
  KStack,
  KText,
  type KMarkdownRendererProps,
} from "@k-design-system/ui";
import { KMarkdownEditor } from "@k-design-system/ui/editors";
import basic from "../../../fixtures/markdown/basic.md?raw";
import tables from "../../../fixtures/markdown/tables.md?raw";
import code from "../../../fixtures/markdown/code.md?raw";
import alerts from "../../../fixtures/markdown/alerts.md?raw";
import images from "../../../fixtures/markdown/images.md?raw";
import longDocument from "../../../fixtures/markdown/long-document.md?raw";
import chat from "../../../fixtures/markdown/chat-reply.md?raw";
import edgeCases from "../../../fixtures/markdown/edge-cases.md?raw";
import streamingSequence from "../../../fixtures/markdown/streaming-sequence.json";

function MarkdownFixture({
  preview = false,
  integration,
  ...props
}: KMarkdownRendererProps & {
  preview?: boolean;
  integration?: "editor" | "chat";
}) {
  const [event, setEvent] = useState("");
  const [draft, setDraft] = useState(props.content);
  const [previewState, setPreviewState] = useState<
    "ready" | "loading" | "empty"
  >("ready");
  const shared: KMarkdownRendererProps = {
    ...props,
    copyLabel: "Kopieren",
    tableLabel: "Tabelle",
    completedTaskLabel: "Erledigt",
    incompleteTaskLabel: "Offen",
    alertLabels: {
      NOTE: "Hinweis",
      TIP: "Tipp",
      IMPORTANT: "Wichtig",
      WARNING: "Warnung",
      CAUTION: "Vorsicht",
    },
    onLinkActivate: (url) => setEvent(`Link ausgewählt: ${url}`),
    onCopy: async (text) => {
      try {
        await navigator.clipboard.writeText(text);
        setEvent("In die Zwischenablage kopiert.");
      } catch {
        setEvent("Die Zwischenablage ist hier nicht verfügbar.");
      }
    },
    renderImage: ({ src, alt, title }) =>
      src === "./project-preview.png" ? (
        <img src="/image-cropper/jordan.png" alt={alt ?? ""} title={title} />
      ) : (
        <KText variant="bodySmall">{alt}: Bild nicht verfügbar</KText>
      ),
  };
  const content =
    integration === "editor" ? (
      <KMarkdownEditor
        markdown={draft}
        onChange={setDraft}
        defaultMode="read"
        markdownOptions={shared}
        ariaLabel="Markdown bearbeiten"
        labels={{
          read: "Vorschau",
          source: "Markdown",
          link: "Link",
          search: "Suchen",
          searchFind: "Suchbegriff",
          searchReplace: "Ersetzen",
        }}
        linkLabels={{
          title: "Link einfügen",
          url: "Link-Adresse",
          cancel: "Abbrechen",
          submit: "Einfügen",
          invalidUrl: "Gib eine gültige Link-Adresse ein.",
          close: "Schließen",
        }}
      />
    ) : integration === "chat" ? (
      <KChatConversation
        metadataMode="hidden"
        labels={{ assistant: "Assistent", user: "Du" }}
        markdownOptions={shared}
        userMarkdownAllowedElements={["p"]}
        messages={[
          {
            id: "request",
            role: "user",
            timestamp: "09:41",
            parts: [
              {
                id: "request-text",
                type: "text",
                text: "# Bitte zeige mir den aktuellen Stand.\n\n**Danke!**",
              },
            ],
          },
          {
            id: "answer",
            role: "assistant",
            timestamp: "09:42",
            parts: [{ id: "answer-text", type: "text", text: props.content }],
          },
        ]}
      />
    ) : preview ? (
      <>
        <KInline gap="action" wrap>
          <KButton variant="secondary" onClick={() => setPreviewState("ready")}>
            Dokument
          </KButton>
          <KButton
            variant="secondary"
            onClick={() => setPreviewState("loading")}
          >
            Laden
          </KButton>
          <KButton variant="secondary" onClick={() => setPreviewState("empty")}>
            Leer
          </KButton>
        </KInline>
        <KMarkdownPreview
          {...shared}
          ariaLabel="Dokumentvorschau"
          content={previewState === "empty" ? "" : shared.content}
          contentMaxWidth="var(--k-layout-form-width)"
          loading={previewState === "loading"}
          loadingContent={<KText>Dokument wird geladen …</KText>}
          emptyContent={<KText>Dieses Dokument ist leer.</KText>}
        />
      </>
    ) : (
      <KMarkdownRenderer {...shared} />
    );
  const status = (
    <KText variant="caption" role="status">
      {event}
    </KText>
  );
  return integration ? (
    <div className="k-markdown-fixture k-markdown-integration-fixture">
      <div className="k-markdown-integration-fixture__surface">{content}</div>
      {status}
    </div>
  ) : (
    <KPage className="k-markdown-fixture">
      <KStack align="stretch" gap="section">
        {content}
        {status}
      </KStack>
    </KPage>
  );
}

const meta = {
  title: "Data Display/Markdown",
  parameters: { layout: "fullscreen" },
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;

export const RendererDocument: Story = {
  name: "renderer-document",
  parameters: { fixtureId: "markdown-renderer-document" },
  render: () => <MarkdownFixture content={basic} />,
};
export const RendererChat: Story = {
  name: "renderer-chat",
  parameters: { fixtureId: "markdown-renderer-chat" },
  render: () => <MarkdownFixture content={chat} profile="chat" />,
};
export const Preview: Story = {
  name: "preview",
  parameters: { fixtureId: "markdown-preview" },
  render: () => <MarkdownFixture content={longDocument} preview />,
};
export const Tables: Story = {
  name: "tables",
  parameters: { fixtureId: "markdown-tables" },
  render: () => <MarkdownFixture content={tables} />,
};
export const Code: Story = {
  name: "code",
  parameters: { fixtureId: "markdown-code" },
  render: () => <MarkdownFixture content={code} />,
};
export const Alerts: Story = {
  name: "alerts",
  parameters: { fixtureId: "markdown-alerts" },
  render: () => <MarkdownFixture content={alerts} />,
};
export const Images: Story = {
  name: "images",
  parameters: { fixtureId: "markdown-images" },
  render: () => <MarkdownFixture content={images} />,
};
export const EdgeCases: Story = {
  name: "edge-cases",
  parameters: { fixtureId: "markdown-edge-cases" },
  render: () => <MarkdownFixture content={edgeCases} />,
};
export const EditorIntegration: Story = {
  name: "editor-integration",
  parameters: { fixtureId: "markdown-editor-integration" },
  render: () => <MarkdownFixture content={basic} integration="editor" />,
};
export const ChatIntegration: Story = {
  name: "chat-integration",
  parameters: { fixtureId: "markdown-chat-integration" },
  render: () => <MarkdownFixture content={basic} integration="chat" />,
};

function StreamingFixture() {
  const [index, setIndex] = useState(0);
  const { content, streaming } = streamingSequence[index]!;
  return (
    <div className="k-markdown-fixture k-markdown-integration-fixture">
      <KInline
        gap="action"
        align="center"
        wrap
        className="k-markdown-fixture__actions"
      >
        <KButton
          variant="secondary"
          disabled={index === 0}
          onClick={() => setIndex(0)}
        >
          Zurücksetzen
        </KButton>
        <KButton
          disabled={index === streamingSequence.length - 1}
          onClick={() => setIndex(index + 1)}
        >
          Nächster Schritt
        </KButton>
        <KText variant="caption">
          {index + 1} / {streamingSequence.length}
        </KText>
      </KInline>
      <div className="k-markdown-integration-fixture__surface">
        <KChatConversation
          metadataMode="hidden"
          labels={{
            assistant: "Assistent",
            newContent: "Zu neuesten Nachrichten",
          }}
          messages={[
            {
              id: "streaming-answer",
              role: "assistant",
              parts: [
                { id: "answer-text", type: "text", text: content, streaming },
              ],
            },
          ]}
        />
      </div>
    </div>
  );
}

export const Streaming: Story = {
  name: "streaming",
  parameters: { fixtureId: "markdown-streaming" },
  render: () => <StreamingFixture />,
};
