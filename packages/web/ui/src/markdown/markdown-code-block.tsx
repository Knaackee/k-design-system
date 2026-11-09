import { useMemo, type ReactNode } from "react";
import { javascript } from "@codemirror/lang-javascript";
import { json } from "@codemirror/lang-json";
import { classHighlighter, highlightTree } from "@lezer/highlight";
import { KButton } from "../primitives/button.js";

function highlight(text: string, language: string): ReactNode {
  const parser = /^(js|javascript|jsx|ts|typescript|tsx)$/.test(language)
    ? javascript({
        typescript: /^(ts|typescript|tsx)$/.test(language),
        jsx: /x$/.test(language),
      }).language.parser
    : language === "json"
      ? json().language.parser
      : null;
  if (!parser) return text;
  const parts: ReactNode[] = [];
  let position = 0;
  highlightTree(parser.parse(text), classHighlighter, (from, to, classes) => {
    if (from > position) parts.push(text.slice(position, from));
    parts.push(
      <span key={from} className={classes}>
        {text.slice(from, to)}
      </span>,
    );
    position = to;
  });
  if (position < text.length) parts.push(text.slice(position));
  return parts;
}

export function KMarkdownCodeBlock({
  text,
  language,
  copyLabel,
  onCopy,
}: {
  text: string;
  language: string;
  copyLabel: string;
  onCopy?: (text: string) => void;
}) {
  const content = useMemo(
    () => highlight(text, language.toLowerCase()),
    [text, language],
  );
  return (
    <div className="k-markdown__code-block">
      {language || onCopy ? (
        <div className="k-markdown__code-header">
          <span>{language}</span>
          {onCopy ? (
            <KButton variant="ghost" onClick={() => onCopy(text)}>
              {copyLabel}
            </KButton>
          ) : null}
        </div>
      ) : null}
      <pre tabIndex={0}>
        <code>{content}</code>
      </pre>
    </div>
  );
}
