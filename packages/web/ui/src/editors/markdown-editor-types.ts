import type { Editor } from "@tiptap/react";
import type { CSSProperties, ReactNode, Ref } from "react";
import type { KDictationState } from "../forms/dictation-action.js";
import type { KMarkdownRendererProps } from "../markdown/markdown-renderer.js";
import type { KCodeEditorHandle } from "./code-editor.js";
import type { KEditorCollaborationDocument } from "./collaboration.js";
import type { KMarkdownFormatAction } from "./format-bar.js";
import type { KMarkdownLinkLabels } from "./markdown-link-dialog.js";
import type {
  KEditorLabels,
  KEditorMode,
  KEditorParticipant,
  KEditorSelection,
  KEditorTransaction,
  KRemoteSelection,
} from "./types.js";

export interface KMarkdownEditorProps {
  markdown: string;
  /** Shared preview behavior; editing and document state remain owned by this editor. */
  markdownOptions?: Omit<
    KMarkdownRendererProps,
    "content" | "profile" | "streaming" | "className" | "ariaLabel"
  >;
  onLinkActivate?: (url: string) => void;
  /** Supply a URL or cancel with null/undefined. Overrides the built-in link dialog. */
  onLinkRequested?: (
    selection: KEditorSelection,
  ) => string | null | undefined | Promise<string | null | undefined>;
  linkLabels?: Partial<KMarkdownLinkLabels>;
  /** Resolve private or relative image sources in the host, without rewriting the document. */
  renderImage?: (image: {
    src: string;
    alt?: string;
    title?: string;
  }) => ReactNode;
  onChange?: (markdown: string, transaction: KEditorTransaction) => void;
  mode?: KEditorMode;
  defaultMode?: KEditorMode;
  onModeChange?: (mode: KEditorMode) => void;
  onSelectionChange?: (selection: KEditorSelection) => void;
  readOnly?: boolean;
  placeholder?: string;
  contentMaxWidth?: CSSProperties["maxWidth"];
  minHeight?: number;
  labels?: Partial<KEditorLabels>;
  formatActions?: KMarkdownFormatAction[];
  showFixedToolbar?: boolean;
  showFloatingToolbar?: boolean;
  showModeSwitcher?: boolean;
  showSearchButton?: boolean;
  remoteSelections?: KRemoteSelection[];
  collaborationDocument?: KEditorCollaborationDocument;
  participants?: KEditorParticipant[];
  sourceEditorRef?: Ref<KCodeEditorHandle>;
  onFocus?: () => void;
  onBlur?: () => void;
  ariaLabel?: string;
  className?: string;
  /** Host-owned rich editor: preserves its CRDT document, history and presence. */
  richEditor?: Editor | null;
  richToolbar?: ReactNode | ((dictationAction: ReactNode) => ReactNode);
  richOverlay?: ReactNode;
  /** Optional capture UI; microphone and transcription remain with the host. */
  dictation?: {
    state: KDictationState;
    audioLevel?: number;
    label: string;
    onStart: (insert: (text: string) => boolean, cancel: () => void) => void;
    onStop: () => void;
  };
}
