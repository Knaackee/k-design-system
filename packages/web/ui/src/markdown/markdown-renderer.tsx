import {
  Children,
  cloneElement,
  isValidElement,
  useMemo,
  type ComponentProps,
  type ReactNode,
} from "react";
import { Streamdown, defaultRehypePlugins } from "streamdown";
import { KAlert, type KStatusTone } from "../basic-components.js";
import { KCheckbox } from "../forms/checkbox.js";
import { KLink } from "../primitives/link.js";
import { KButton } from "../primitives/button.js";
import { KMarkdownCodeBlock } from "./markdown-code-block.js";
import { MarkdownImage } from "./markdown-image.js";
import { streamingSource } from "./streaming-source.js";

export type KMarkdownProfile = "document" | "chat";

export interface KMarkdownRendererProps {
  content: string;
  /** Context, not a replacement for the application's density or text scale. */
  profile?: KMarkdownProfile;
  streaming?: boolean;
  /** HTML element names. Disallowed wrappers are unwrapped, preserving text. */
  allowedElements?: readonly string[];
  onLinkActivate?: (url: string) => void;
  renderImage?: (image: {
    src: string;
    alt?: string;
    title?: string;
  }) => ReactNode;
  selectable?: boolean;
  copyLabel?: string;
  tableLabel?: string;
  completedTaskLabel?: string;
  incompleteTaskLabel?: string;
  alertLabels?: Partial<
    Record<"NOTE" | "TIP" | "IMPORTANT" | "WARNING" | "CAUTION", string>
  >;
  /** If supplied, exposes copy actions. The consumer owns clipboard/feedback. */
  onCopy?: (text: string) => void;
  ariaLabel?: string;
  className?: string;
}

type MarkdownNode = {
  type?: string;
  value?: string;
  tagName?: string;
  children?: MarkdownNode[];
  properties?: Record<string, unknown>;
};

function textOf(node?: MarkdownNode): string {
  return node?.value ?? node?.children?.map(textOf).join("") ?? "";
}

export function markdownTableText(node?: MarkdownNode): string {
  return (
    node?.children
      ?.flatMap((section) =>
        section.type === "element"
          ? (section.children?.filter((row) => row.type === "element") ?? [])
          : [],
      )
      .map(
        (row) =>
          row.children
            ?.filter((cell) => cell.type === "element")
            .map(textOf)
            .join("\t") ?? "",
      )
      .join("\n") ?? ""
  );
}

function safeUrl(url: string, image: boolean): string {
  const trimmed = url.trim();
  // Reject obfuscated protocols as well as executable and embedded documents.
  if (/[\u0000-\u0020\u007f]/.test(trimmed)) return "";
  const scheme = /^([a-z][a-z\d+.-]*):/i.exec(trimmed)?.[1]?.toLowerCase();
  return !scheme ||
    (image ? ["http", "https"] : ["http", "https", "mailto"]).includes(scheme)
    ? trimmed
    : "";
}

const alertTones: Record<string, KStatusTone> = {
  NOTE: "info",
  TIP: "success",
  IMPORTANT: "info",
  WARNING: "warning",
  CAUTION: "error",
};

function withoutAlertMarker(children: ReactNode): ReactNode {
  let removed = false;
  function visit(child: ReactNode): ReactNode {
    if (removed) return child;
    if (typeof child === "string") {
      const next = child.replace(
        /^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*/,
        "",
      );
      removed = next !== child;
      return next;
    }
    if (isValidElement<{ children?: ReactNode }>(child)) {
      return cloneElement(child, {}, Children.map(child.props.children, visit));
    }
    return child;
  }
  return Children.map(children, visit);
}

/** Token-driven Markdown display shared by documents and chat surfaces. */
export function KMarkdownRenderer({
  content,
  profile = "document",
  streaming = false,
  allowedElements,
  onLinkActivate,
  renderImage,
  selectable = true,
  copyLabel = "Copy",
  onCopy,
  ariaLabel,
  className,
  tableLabel = "Table",
  completedTaskLabel = "Completed",
  incompleteTaskLabel = "Not completed",
  alertLabels,
}: KMarkdownRendererProps) {
  const { markdown, tail } = streaming
    ? streamingSource(content)
    : { markdown: content, tail: "" };
  const components = useMemo<
    NonNullable<ComponentProps<typeof Streamdown>["components"]>
  >(
    () => ({
      strong: ({ children }) => <strong>{children}</strong>,
      em: ({ children }) => <em>{children}</em>,
      del: ({ children }) => <del>{children}</del>,
      a: ({ href, children }) =>
        href ? (
          <KLink
            href={href}
            onClick={(event) => {
              event.preventDefault();
              onLinkActivate?.(href);
            }}
          >
            {children}
          </KLink>
        ) : (
          <span>{children}</span>
        ),
      img: ({ src, alt, title }) =>
        typeof src !== "string" || !src ? null : renderImage ? (
          renderImage({ src, alt, title })
        ) : (
          <MarkdownImage key={src} src={src} alt={alt} title={title} />
        ),
      pre: ({ node }) => {
        const code = node?.children?.find(
          (child) => child.type === "element" && child.tagName === "code",
        );
        const classes =
          code && "properties" in code ? code.properties.className : [];
        const language = Array.isArray(classes)
          ? String(
              classes.find((value) => String(value).startsWith("language-")) ??
                "",
            ).replace(/^language-/, "")
          : "";
        return (
          <KMarkdownCodeBlock
            text={textOf(node)}
            language={language}
            copyLabel={copyLabel}
            onCopy={onCopy}
          />
        );
      },
      code: ({ children }) => <code>{children}</code>,
      inlineCode: ({ children }) => <code>{children}</code>,
      table: ({ children, node }) => {
        return (
          <div className="k-markdown__table">
            {onCopy ? (
              <div className="k-markdown__actions">
                <KButton
                  variant="ghost"
                  onClick={() => onCopy(markdownTableText(node))}
                >
                  {copyLabel}
                </KButton>
              </div>
            ) : null}
            <div
              className="k-markdown__table-scroll"
              tabIndex={0}
              role="region"
              aria-label={tableLabel}
            >
              <table>{children}</table>
            </div>
          </div>
        );
      },
      thead: ({ children }) => <thead>{children}</thead>,
      tbody: ({ children }) => <tbody>{children}</tbody>,
      tr: ({ children }) => <tr>{children}</tr>,
      th: ({ children, style }) => (
        <th scope="col" style={style}>
          {children}
        </th>
      ),
      td: ({ children, style }) => <td style={style}>{children}</td>,
      input: ({ checked }) => (
        <KCheckbox
          className="k-markdown__task"
          label=""
          aria-label={checked ? completedTaskLabel : incompleteTaskLabel}
          value={Boolean(checked)}
          disabled
        />
      ),
      blockquote: ({ children, node }) => {
        const kind = /^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]/.exec(
          textOf(node).trimStart(),
        )?.[1];
        return kind ? (
          <KAlert
            title={
              alertLabels?.[
                kind as keyof NonNullable<KMarkdownRendererProps["alertLabels"]>
              ] ?? kind
            }
            tone={alertTones[kind]}
            role="note"
            description={withoutAlertMarker(children)}
          />
        ) : (
          <blockquote>{children}</blockquote>
        );
      },
    }),
    [
      alertLabels,
      completedTaskLabel,
      copyLabel,
      incompleteTaskLabel,
      onCopy,
      onLinkActivate,
      renderImage,
      tableLabel,
    ],
  );
  const body = useMemo(
    () => (
      <Streamdown
        mode="static"
        skipHtml
        controls={false}
        allowedElements={allowedElements}
        unwrapDisallowed
        rehypePlugins={[defaultRehypePlugins.sanitize]}
        urlTransform={(url, key) => safeUrl(url, key === "src")}
        components={components}
      >
        {markdown}
      </Streamdown>
    ),
    [allowedElements, components, markdown],
  );

  return (
    <div
      className={["k-markdown", className].filter(Boolean).join(" ")}
      data-profile={profile}
      data-selectable={selectable}
      data-streaming={streaming}
      aria-label={ariaLabel}
      aria-busy={streaming || undefined}
    >
      {body}
      {tail && <p className="k-markdown__streaming-tail">{tail}</p>}
    </div>
  );
}
