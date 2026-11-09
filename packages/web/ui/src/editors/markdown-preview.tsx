import {
  KMarkdownPreview as MarkdownPreview,
  type KMarkdownPreviewProps,
} from "../markdown/markdown-preview.js";

/** Compatibility adapter: the editor owns source; the shared renderer owns display. */
export function KMarkdownPreview({
  markdown,
  ...props
}: Omit<KMarkdownPreviewProps, "content"> & { markdown: string }) {
  return (
    <div className="k-markdown-editor-preview">
      <MarkdownPreview {...props} content={markdown} />
    </div>
  );
}
