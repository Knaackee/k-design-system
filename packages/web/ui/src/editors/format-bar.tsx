import { KIcon, type KIconName } from "../primitives/icon.js";
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

const actionIcon: Record<KMarkdownFormatAction, KIconName> = {
  undo: "undo-2",
  redo: "redo-2",
  bold: "bold",
  italic: "italic",
  strike: "strikethrough",
  code: "code",
  link: "link",
  bulletList: "list",
  orderedList: "list-ordered",
  taskList: "list-checks",
  quote: "quote",
  codeBlock: "square-code",
};

export interface KEditorFormatBarProps {
  labels: KEditorLabels;
  actions?: KMarkdownFormatAction[];
  activeActions?: KMarkdownFormatAction[];
  onAction: (action: KMarkdownFormatAction) => void;
  floating?: boolean;
  leadingAction?: ReactNode;
  trailingAction?: ReactNode;
}

export function KEditorFormatBar({
  labels,
  actions = kDefaultMarkdownFormatActions,
  activeActions = [],
  onAction,
  floating = false,
  leadingAction,
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
      <KIcon name={actionIcon[action]} />
    </KButton>
  ));
  return (
    <div
      {...(leadingAction || trailingAction ? {} : dragScroll)}
      data-has-trailing-action={Boolean(leadingAction || trailingAction)}
      className={`k-editor-format-bar k-scrollbar${floating ? " k-editor-format-bar--floating" : ""}`}
      role="toolbar"
      aria-label="Text formatting"
    >
      {leadingAction}
      {leadingAction || trailingAction ? (
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
