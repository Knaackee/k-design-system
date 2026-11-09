export { KMarkdownEditor } from "./markdown-editor.js";

export type { KMarkdownEditorProps } from "./markdown-editor.js";
export type { KMarkdownLinkLabels } from "./markdown-link-dialog.js";

export {
  KEditorDictationExtension,
  beginKEditorDictation,
  cancelKEditorDictation,
  insertKEditorDictation,
} from "./dictation.js";

export { KCodeEditor } from "./code-editor.js";

export type {
  KCodeEditorProps,
  KCodeEditorHandle,
  KCodeLanguage,
} from "./code-editor.js";

export { KEditorSearchPanel } from "./editor-search-panel.js";

export type { KEditorSearchPanelProps } from "./editor-search-panel.js";

export {
  KEditorFormatBar,
  kDefaultMarkdownFormatActions,
} from "./format-bar.js";

export type {
  KEditorFormatBarProps,
  KMarkdownFormatAction,
} from "./format-bar.js";

export {
  createKEditorCollaborationDocument,
  createKEditorCollaborationTransport,
} from "./collaboration.js";

export type {
  KEditorCollaborationDocument,
  KEditorDocumentKind,
  KEditorCollaborationTransport,
} from "./collaboration.js";

export { kDefaultEditorLabels } from "./types.js";

export type {
  KEditorMode,
  KEditorSelection,
  KEditorParticipant,
  KRemoteSelection,
  KCodeDiagnostic,
  KCodeCompletion,
  KEditorLabels,
  KEditorTransaction,
} from "./types.js";

export { KMapZoneEditor } from "./map-zone-editor.js";

export { kDefaultMapZoneEditorLabels } from "./map-zone-editor-labels.js";

export type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";

export type {
  KMapZoneEditorProps,
  KMapZoneUndoAction,
  KMapZonePropertyOption,
  KMapZonePropertyOptions,
  KMapZoneTravelCostSource,
} from "./map-zone-editor-types.js";

export type {
  KMapZone,
  KMapPolygon,
  KMapZoneAvailability,
  KMapZoneSettings,
  KMapZoneWorkingDay,
  KMapZoneTravelCost,
  KMapPostalArea,
  KMapZoneValidationCode,
  KMapZoneValidationError,
  KMapPosition,
} from "../maps/map-zone-geometry.js";
