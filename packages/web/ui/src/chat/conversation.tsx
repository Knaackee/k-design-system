import {
  useCallback,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { Streamdown } from "streamdown";
import { KAvatar } from "../basic-components.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import {
  KAgentActivity,
  KAgentApproval,
  KAgentAttachment,
  KAgentQuestion,
  KAgentReference,
  KAgentStatus,
  KAgentTaskGroup,
  KAgentToolCall,
  KAgentToolGroup,
  type KAgentPartActions,
  type KAgentToolRenderer,
} from "./agent-parts.js";
import {
  KAgentAttachmentRequest,
  KAgentExternalAction,
  KAgentForm,
} from "./ask-tools.js";
import type {
  KChatMessagePart,
  KChatMessageValue,
  KChatRunState,
} from "./types.js";

export interface KChatLabels {
  emptyTitle: string;
  emptyDescription: string;
  loadOlder: string;
  newContent: string;
  assistant: string;
  user: string;
  system: string;
  sending: string;
  sent: string;
  failed: string;
  approvalNote?: string;
}

const defaultLabels: KChatLabels = {
  emptyTitle: "Start a conversation",
  emptyDescription: "Send a message to begin.",
  loadOlder: "Load earlier messages",
  newContent: "Jump to newest message",
  assistant: "Assistant",
  user: "You",
  system: "System",
  sending: "Sending…",
  sent: "Sent",
  failed: "Not sent",
  approvalNote: "Add a note (optional)",
};

export type KChatMessageMetadataMode = "always" | "grouped" | "hidden";

export type KChatAvatarRenderer = (
  message: KChatMessageValue,
  author: string,
) => ReactNode;

export interface KChatConversationProps
  extends Omit<HTMLAttributes<HTMLDivElement>, "children">, KAgentPartActions {
  messages: readonly KChatMessageValue[];
  runState?: KChatRunState;
  hasOlder?: boolean;
  loadingOlder?: boolean;
  onLoadOlder?: () => void;
  labels?: Partial<KChatLabels>;
  emptyState?: ReactNode;
  renderPart?: (
    part: KChatMessagePart,
    message: KChatMessageValue,
  ) => ReactNode;
  renderMessageActions?: (message: KChatMessageValue) => ReactNode;
  toolRenderers?: Readonly<Record<string, KAgentToolRenderer>>;
  onLinkActivate?: (url: string) => void;
  metadataMode?: KChatMessageMetadataMode;
  metadataByRole?: Partial<
    Record<KChatMessageValue["role"], KChatMessageMetadataMode>
  >;
  showTimestamps?: boolean;
  renderAvatar?: KChatAvatarRenderer;
}

export function KChatConversation({
  messages,
  runState = "idle",
  hasOlder = false,
  loadingOlder = false,
  onLoadOlder,
  labels: labelsInput,
  emptyState,
  renderPart,
  renderMessageActions,
  toolRenderers,
  onLinkActivate,
  metadataMode = "always",
  metadataByRole,
  showTimestamps = true,
  renderAvatar,
  onApprovalResponse,
  onQuestionResponse,
  onFormResponse,
  onExternalAction,
  onAttachmentRequest,
  onAttachmentActivate,
  onSourceActivate,
  onArtifactActivate,
  className,
  ...props
}: KChatConversationProps) {
  const labels = { ...defaultLabels, ...labelsInput };
  const scrollRef = useRef<HTMLDivElement>(null);
  const previousHeight = useRef(0);
  const following = useRef(true);
  const [showNewest, setShowNewest] = useState(false);
  const lastMessage = messages.at(-1);
  const streamMarker = `${lastMessage?.id ?? ""}:${lastMessage?.parts
    .map((part) => (part.type === "text" ? part.text.length : part.id))
    .join(":")}`;

  useLayoutEffect(() => {
    const node = scrollRef.current;
    if (!node) return;
    if (following.current) node.scrollTop = node.scrollHeight;
    setShowNewest(!following.current);
    previousHeight.current = node.scrollHeight;
  }, [messages.length, streamMarker]);

  const onScroll = useCallback(() => {
    const node = scrollRef.current;
    if (!node) return;
    following.current =
      node.scrollHeight - node.scrollTop - node.clientHeight < 32;
    setShowNewest(!following.current);
  }, []);

  const jumpToNewest = () => {
    const node = scrollRef.current;
    if (!node) return;
    following.current = true;
    node.scrollTo({ top: node.scrollHeight, behavior: "smooth" });
    setShowNewest(false);
  };

  return (
    <section
      {...props}
      className={["k-chat-conversation", className].filter(Boolean).join(" ")}
      aria-busy={
        runState === "submitted" || runState === "streaming" || undefined
      }
    >
      <div
        ref={scrollRef}
        className="k-chat-conversation__scroll"
        onScroll={onScroll}
        role="log"
        aria-live="polite"
        aria-relevant="additions text"
      >
        {hasOlder ? (
          <div className="k-chat-conversation__older">
            <KButton
              variant="ghost"
              loading={loadingOlder}
              onClick={onLoadOlder}
            >
              {labels.loadOlder}
            </KButton>
          </div>
        ) : null}
        {messages.length === 0
          ? (emptyState ?? (
              <div className="k-chat-empty">
                <KIcon name="info" size={32} />
                <strong>{labels.emptyTitle}</strong>
                <p>{labels.emptyDescription}</p>
              </div>
            ))
          : messages.map((message, index) => {
              const mode = metadataByRole?.[message.role] ?? metadataMode;
              const previous = messages[index - 1];
              const author = message.authorLabel ?? labels[message.role];
              const previousAuthor = previous
                ? (previous.authorLabel ?? labels[previous.role])
                : undefined;
              const startsGroup =
                !previous ||
                previous.role !== message.role ||
                previousAuthor !== author;
              const showMetadata =
                mode === "always" || (mode === "grouped" && startsGroup);

              return (
                <KChatMessage
                  key={message.id}
                  message={message}
                  labels={labels}
                  showMetadata={showMetadata}
                  showTimestamp={showTimestamps}
                  renderAvatar={renderAvatar}
                  actions={renderMessageActions?.(message)}
                >
                  {message.parts.map((part, index) => {
                    // Only group the default renderer; custom parts keep their contract.
                    if (
                      !renderPart &&
                      part.type === "tool" &&
                      !toolRenderers?.[part.toolName]
                    ) {
                      const previous = message.parts[index - 1];
                      const canGroup = (candidate: KChatMessagePart) =>
                        candidate.type === "tool" &&
                        candidate.toolName === part.toolName &&
                        !candidate.error &&
                        candidate.state !== "failed" &&
                        candidate.state !== "approval-required";
                      if (canGroup(part)) {
                        if (previous && canGroup(previous)) return null;
                        const parts = [part];
                        for (
                          let next = index + 1;
                          next < message.parts.length;
                          next++
                        ) {
                          const candidate = message.parts[next];
                          if (candidate.type !== "tool" || !canGroup(candidate))
                            break;
                          parts.push(candidate);
                        }
                        if (parts.length > 1)
                          return (
                            <KAgentToolGroup key={part.id} parts={parts} />
                          );
                      }
                    }
                    return (
                      renderPart?.(part, message) ?? (
                        <KChatPart
                          key={part.id}
                          part={part}
                          toolRenderer={
                            part.type === "tool"
                              ? toolRenderers?.[part.toolName]
                              : undefined
                          }
                          onLinkActivate={onLinkActivate}
                          approvalNoteLabel={labels.approvalNote}
                          onApprovalResponse={onApprovalResponse}
                          onQuestionResponse={onQuestionResponse}
                          onFormResponse={onFormResponse}
                          onExternalAction={onExternalAction}
                          onAttachmentRequest={onAttachmentRequest}
                          onAttachmentActivate={onAttachmentActivate}
                          onSourceActivate={onSourceActivate}
                          onArtifactActivate={onArtifactActivate}
                        />
                      )
                    );
                  })}
                </KChatMessage>
              );
            })}
      </div>
      {showNewest ? (
        <button
          className="k-chat-conversation__newest"
          type="button"
          onClick={jumpToNewest}
        >
          <KIcon name="arrow-down" />
          {labels.newContent}
        </button>
      ) : null}
    </section>
  );
}

function KChatMessage({
  message,
  labels,
  actions,
  showMetadata,
  showTimestamp,
  renderAvatar,
  children,
}: {
  message: KChatMessageValue;
  labels: KChatLabels;
  actions?: ReactNode;
  showMetadata: boolean;
  showTimestamp: boolean;
  renderAvatar?: KChatAvatarRenderer;
  children: ReactNode;
}) {
  const author = message.authorLabel ?? labels[message.role];
  const avatar = showMetadata ? (
    renderAvatar ? (
      renderAvatar(message, author)
    ) : (
      <KAvatar alt={author} size="small" />
    )
  ) : null;
  const status = message.status ? labels[message.status] : null;
  const textOnly = message.parts.every((part) => part.type === "text");
  return (
    <article
      className="k-chat-message"
      data-role={message.role}
      data-status={message.status}
      data-metadata-visible={showMetadata}
      data-avatar-visible={Boolean(avatar)}
      data-text-only={textOnly}
    >
      {avatar}
      <div className="k-chat-message__body">
        {showMetadata || (showTimestamp && message.timestamp) ? (
          <header>
            {showMetadata ? <strong>{author}</strong> : null}
            {showTimestamp && message.timestamp ? (
              <time>{message.timestamp}</time>
            ) : null}
          </header>
        ) : (
          <span className="k-visually-hidden">{author}</span>
        )}
        <div className="k-chat-message__parts">{children}</div>
        {status ? (
          <small className="k-chat-message__status">{status}</small>
        ) : null}
        {actions ? (
          <div className="k-chat-message__actions">{actions}</div>
        ) : null}
      </div>
    </article>
  );
}

function KChatPart({
  part,
  toolRenderer,
  onLinkActivate,
  approvalNoteLabel,
  ...actions
}: {
  part: KChatMessagePart;
  toolRenderer?: KAgentToolRenderer;
  onLinkActivate?: (url: string) => void;
  approvalNoteLabel?: string;
} & KAgentPartActions) {
  if (part.type === "text") {
    return (
      <Streamdown
        className="k-chat-markdown"
        mode={part.streaming ? "streaming" : "static"}
        skipHtml
        controls={{ code: { copy: true }, table: { copy: true } }}
        components={{
          a: ({ href, children, ...props }) => (
            <a
              {...props}
              href={href}
              onClick={(event) => {
                if (!href || !onLinkActivate) return;
                event.preventDefault();
                onLinkActivate(href);
              }}
            >
              {children}
            </a>
          ),
        }}
      >
        {part.text}
      </Streamdown>
    );
  }
  if (part.type === "attachment")
    return (
      <KAgentAttachment
        part={part}
        onActivate={() => actions.onAttachmentActivate?.(part)}
      />
    );
  if (part.type === "tool")
    return <KAgentToolCall part={part} renderer={toolRenderer} />;
  if (part.type === "approval")
    return (
      <KAgentApproval
        part={part}
        reasonLabel={approvalNoteLabel}
        onResponse={actions.onApprovalResponse}
      />
    );
  if (part.type === "question")
    return (
      <KAgentQuestion part={part} onResponse={actions.onQuestionResponse} />
    );
  if (part.type === "form")
    return <KAgentForm part={part} onResponse={actions.onFormResponse} />;
  if (part.type === "external-action")
    return (
      <KAgentExternalAction part={part} onResponse={actions.onExternalAction} />
    );
  if (part.type === "attachment-request")
    return (
      <KAgentAttachmentRequest
        part={part}
        onResponse={actions.onAttachmentRequest}
      />
    );
  if (part.type === "tasks") return <KAgentTaskGroup part={part} />;
  if (part.type === "activity") return <KAgentActivity part={part} />;
  if (part.type === "status") return <KAgentStatus part={part} />;
  if (part.type === "source")
    return (
      <KAgentReference
        part={part}
        onActivate={() => actions.onSourceActivate?.(part)}
      />
    );
  return (
    <KAgentReference
      part={part}
      onActivate={() => actions.onArtifactActivate?.(part)}
    />
  );
}
