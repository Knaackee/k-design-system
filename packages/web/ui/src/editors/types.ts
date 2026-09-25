export type KEditorMode = "source" | "read";

export interface KEditorSelection {
  anchor: number;
  head: number;
}

export interface KEditorParticipant {
  id: string;
  name: string;
  color: string;
  foregroundColor?: string;
}

export interface KRemoteSelection extends KEditorSelection {
  participant: KEditorParticipant;
}

export interface KCodeDiagnostic {
  from: number;
  to: number;
  severity: "info" | "warning" | "error";
  message: string;
}

export interface KCodeCompletion {
  label: string;
  detail?: string;
  apply?: string;
  type?: "keyword" | "function" | "variable" | "property" | "text";
}

export interface KEditorLabels {
  source: string;
  read: string;
  bold: string;
  italic: string;
  strike: string;
  code: string;
  link: string;
  bulletList: string;
  orderedList: string;
  taskList: string;
  quote: string;
  codeBlock: string;
  undo: string;
  redo: string;
  search: string;
  searchFind: string;
  searchReplace: string;
  searchReplaceAll: string;
  searchNext: string;
  searchPrevious: string;
  searchAll: string;
  searchClose: string;
  searchOptions: string;
  searchShowReplace: string;
  searchMatchCase: string;
  searchRegexp: string;
  searchWholeWord: string;
  wrap: string;
  lineNumbers: string;
}

export const kDefaultEditorLabels: KEditorLabels = {
  source: "Markdown",
  read: "Preview",
  bold: "Bold",
  italic: "Italic",
  strike: "Strikethrough",
  code: "Inline code",
  link: "Link",
  bulletList: "Bullet list",
  orderedList: "Numbered list",
  taskList: "Task list",
  quote: "Quote",
  codeBlock: "Code block",
  undo: "Undo",
  redo: "Redo",
  search: "Search",
  searchFind: "Find",
  searchReplace: "Replace",
  searchReplaceAll: "Replace all",
  searchNext: "Next result",
  searchPrevious: "Previous result",
  searchAll: "Select all",
  searchClose: "Close search",
  searchOptions: "Search options",
  searchShowReplace: "Show replace",
  searchMatchCase: "Match case",
  searchRegexp: "Regular expression",
  searchWholeWord: "Whole word",
  wrap: "Wrap long lines",
  lineNumbers: "Line numbers",
};

export interface KEditorTransaction {
  value: string;
  selection: KEditorSelection;
  origin: "local" | "remote";
}
