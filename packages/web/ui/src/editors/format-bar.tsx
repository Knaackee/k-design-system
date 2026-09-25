import { KButton } from "../primitives/button.js";
import type { KEditorLabels } from "./types.js";

export type KMarkdownFormatAction =
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
}

export function KEditorFormatBar({
  labels,
  actions = kDefaultMarkdownFormatActions,
  activeActions = [],
  onAction,
  floating = false,
}: KEditorFormatBarProps) {
  return (
    <div
      className={`k-editor-format-bar k-scrollbar${floating ? " k-editor-format-bar--floating" : ""}`}
      role="toolbar"
      aria-label="Text formatting"
    >
      {actions.map((action) => (
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
      ))}
    </div>
  );
}
