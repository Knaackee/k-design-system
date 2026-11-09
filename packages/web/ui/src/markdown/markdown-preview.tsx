import type { CSSProperties, ReactNode } from "react";
import {
  KMarkdownRenderer,
  type KMarkdownRendererProps,
} from "./markdown-renderer.js";

export interface KMarkdownPreviewProps extends KMarkdownRendererProps {
  /** Consumer layout constraint; typography and spacing remain token-driven. */
  contentMaxWidth?: CSSProperties["maxWidth"];
  loading?: boolean;
  loadingContent?: ReactNode;
  emptyContent?: ReactNode;
}

export function KMarkdownPreview({
  contentMaxWidth,
  loading = false,
  loadingContent,
  emptyContent,
  ...props
}: KMarkdownPreviewProps) {
  return (
    <section
      className="k-markdown-preview"
      aria-label={props.ariaLabel}
      aria-busy={loading || undefined}
      style={{ maxWidth: contentMaxWidth }}
    >
      {loading ? (
        loadingContent
      ) : props.content.trim() ? (
        <KMarkdownRenderer {...props} />
      ) : (
        emptyContent
      )}
    </section>
  );
}
