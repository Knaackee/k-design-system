import type { KMarkdownFormatAction } from "./format-bar.js";
import type { KEditorSelection } from "./types.js";

export interface MarkdownChange {
  from: number;
  to: number;
  insert: string;
  selection: KEditorSelection;
}

function wrapSelection(
  markdown: string,
  selection: KEditorSelection,
  before: string,
  after = before,
): MarkdownChange {
  const from = Math.min(selection.anchor, selection.head);
  const to = Math.max(selection.anchor, selection.head);
  const selected = markdown.slice(from, to);
  const insert = `${before}${selected}${after}`;
  const anchor = from + before.length;
  const head = anchor + selected.length;
  return {
    from,
    to,
    insert,
    selection:
      selection.anchor <= selection.head
        ? { anchor, head }
        : { anchor: head, head: anchor },
  };
}

function prefixLines(
  markdown: string,
  selection: KEditorSelection,
  prefix: string | ((index: number) => string),
): MarkdownChange {
  const from = Math.min(selection.anchor, selection.head);
  const to = Math.max(selection.anchor, selection.head);
  const lineStart = from === 0 ? 0 : markdown.lastIndexOf("\n", from - 1) + 1;
  const endOffset = to > from && markdown[to - 1] === "\n" ? to - 1 : to;
  const nextBreak = markdown.indexOf("\n", endOffset);
  const lineEnd = nextBreak < 0 ? markdown.length : nextBreak;
  const selected = markdown.slice(lineStart, lineEnd);
  const insert = selected
    .split("\n")
    .map(
      (line, index) =>
        `${typeof prefix === "function" ? prefix(index) : prefix}${line}`,
    )
    .join("\n");
  return {
    from: lineStart,
    to: lineEnd,
    insert,
    selection: { anchor: lineStart, head: lineStart + insert.length },
  };
}

export function markdownChange(
  markdown: string,
  selection: KEditorSelection,
  action: KMarkdownFormatAction,
  href?: string,
): MarkdownChange {
  if (action === "bold") return wrapSelection(markdown, selection, "**");
  if (action === "italic") return wrapSelection(markdown, selection, "_");
  if (action === "strike") return wrapSelection(markdown, selection, "~~");
  if (action === "code") return wrapSelection(markdown, selection, "`");
  if (action === "link") {
    const from = Math.min(selection.anchor, selection.head);
    const to = Math.max(selection.anchor, selection.head);
    const selected = (markdown.slice(from, to) || href || "").replace(
      /[\\[\]]/g,
      "\\$&",
    );
    const destination = href?.replace(/[()]/g, "\\$&");
    const anchor = from + 1;
    const head = anchor + selected.length;
    return {
      from,
      to,
      insert: `[${selected}](${destination})`,
      selection:
        selection.anchor <= selection.head
          ? { anchor, head }
          : { anchor: head, head: anchor },
    };
  }
  if (action === "bulletList") return prefixLines(markdown, selection, "- ");
  if (action === "orderedList")
    return prefixLines(markdown, selection, (index) => `${index + 1}. `);
  if (action === "taskList") return prefixLines(markdown, selection, "- [ ] ");
  if (action === "quote") return prefixLines(markdown, selection, "> ");
  return wrapSelection(markdown, selection, "```\n", "\n```");
}
