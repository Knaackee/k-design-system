import { KButton } from "../primitives/button.js";
import type { ReactNode } from "react";
import { useHorizontalDragScroll } from "../util/use-horizontal-drag-scroll.js";
import type { KEditorLabels } from "./types.js";

export type KMarkdownFormatAction =
  | "undo"
  | "redo"
  | "bold"
  | "italic"
  | "strike"
  | "code"
  | "link"
  | "bulletList"
  | "orderedList"
  | "taskList"
  | "quote"
  | "codeBlock";

export const kDefaultMarkdownFormatActions: KMarkdownFormatAction[] = [
  "undo",
  "redo",
  "bold",
  "italic",
  "strike",
  "code",
  "link",
  "bulletList",
  "orderedList",
  "taskList",
  "quote",
  "codeBlock",
];

const actionGlyph: Record<KMarkdownFormatAction, string> = {
  undo: "↶",
  redo: "↷",
  bold: "B",
  italic: "I",
  strike: "S",
  code: "</>",
  link: "↗",
  bulletList: "•≡",
  orderedList: "1≡",
  taskList: "☑",
  quote: "❞",
  codeBlock: "{ }",
};

export interface KEditorFormatBarProps {
  labels: KEditorLabels;
  actions?: KMarkdownFormatAction[];
  activeActions?: KMarkdownFormatAction[];
  onAction: (action: KMarkdownFormatAction) => void;
  floating?: boolean;
  trailingAction?: ReactNode;
}

export function KEditorFormatBar({
  labels,
  actions = kDefaultMarkdownFormatActions,
  activeActions = [],
  onAction,
  floating = false,
  trailingAction,
}: KEditorFormatBarProps) {
  const dragScroll = useHorizontalDragScroll<HTMLDivElement>();
  const formatButtons = actions.map((action) => (
    <KButton
      key={action}
      variant="ghost"
      className="k-editor-format-action"
      aria-label={labels[action]}
      title={labels[action]}
      aria-pressed={activeActions.includes(action)}
      onMouseDown={(event) => event.preventDefault()}
      onClick={() => onAction(action)}
    >
      <span aria-hidden="true" data-action={action}>
        {actionGlyph[action]}
      </span>
    </KButton>
  ));
  return (
    <div
      {...(trailingAction ? {} : dragScroll)}
      data-has-trailing-action={Boolean(trailingAction)}
      className={`k-editor-format-bar k-scrollbar${floating ? " k-editor-format-bar--floating" : ""}`}
      role="toolbar"
      aria-label="Text formatting"
    >
      {trailingAction ? (
        <div {...dragScroll} className="k-editor-format-actions">
          {formatButtons}
        </div>
      ) : (
        formatButtons
      )}
      {trailingAction}
    </div>
  );
}
