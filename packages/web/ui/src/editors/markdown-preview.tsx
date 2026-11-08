import { Streamdown, defaultRehypePlugins } from "streamdown";
import type { ReactNode } from "react";

/** Read the Markdown source without turning the rendered result back into edits. */
export function KMarkdownPreview({
  markdown,
  ariaLabel,
  renderImage,
}: {
  markdown: string;
  ariaLabel: string;
  renderImage?: (image: {
    src: string;
    alt?: string;
    title?: string;
  }) => ReactNode;
}) {
  return (
    <div className="k-markdown-editor-content" aria-label={ariaLabel}>
      <Streamdown
        mode="static"
        skipHtml
        controls={false}
        // The default hardener resolves relative paths against the web origin.
        // Files hosts must resolve them against the document's own folder instead.
        rehypePlugins={[defaultRehypePlugins.sanitize]}
        urlTransform={(url) =>
          /^(?:https?:|mailto:)/i.test(url) || !/^[a-z][a-z\d+.-]*:/i.test(url)
            ? url
            : ""
        }
        components={{
          strong: ({ children }) => <strong>{children}</strong>,
          table: ({ children }) => <table>{children}</table>,
          thead: ({ children }) => <thead>{children}</thead>,
          tbody: ({ children }) => <tbody>{children}</tbody>,
          tr: ({ children }) => <tr>{children}</tr>,
          th: ({ children }) => <th>{children}</th>,
          td: ({ children }) => <td>{children}</td>,
          a: ({ href, children }) => (
            <a href={href} rel="noopener noreferrer">
              {children}
            </a>
          ),
          img: ({ src, alt, title }) => {
            if (typeof src !== "string") return null;
            return renderImage ? (
              renderImage({ src, alt, title })
            ) : (
              <img
                src={src}
                alt={alt ?? ""}
                title={title}
                loading="lazy"
                referrerPolicy="no-referrer"
              />
            );
          },
        }}
      >
        {markdown}
      </Streamdown>
    </div>
  );
}
