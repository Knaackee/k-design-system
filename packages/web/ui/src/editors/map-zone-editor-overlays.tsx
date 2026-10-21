import type { KMapZone } from "../maps/map-zone-geometry.js";
import {
  ZoneDeleteConfirmation,
  ZoneEditorFeedback,
  ZoneOverlapConfirmation,
} from "./map-zone-editor-feedback.js";
import type { KMapZoneCommitImpact } from "../maps/map-zone-boolean.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";

export function ZoneEditorOverlays({
  labels,
  confirmOpen,
  canSave,
  saveDisabledReason,
  deleteTarget,
  onContinue,
  onDiscard,
  onSave,
  onCancelDelete,
  onConfirmDelete,
  overlapImpacts,
  onCancelOverlap,
  onConfirmOverlap,
}: {
  labels: KMapZoneEditorLabels;
  confirmOpen: boolean;
  canSave: boolean;
  saveDisabledReason: string;
  deleteTarget: KMapZone | null;
  onContinue: () => void;
  onDiscard: () => void;
  onSave: () => void;
  onCancelDelete: () => void;
  onConfirmDelete: () => void;
  overlapImpacts: readonly KMapZoneCommitImpact[];
  onCancelOverlap: () => void;
  onConfirmOverlap: () => void;
}) {
  return (
    <>
      <ZoneEditorFeedback
        labels={labels}
        confirmOpen={confirmOpen}
        canSave={canSave}
        saveDisabledReason={saveDisabledReason}
        onContinue={onContinue}
        onDiscard={onDiscard}
        onSave={onSave}
      />
      <ZoneOverlapConfirmation
        impacts={overlapImpacts}
        labels={labels}
        onCancel={onCancelOverlap}
        onConfirm={onConfirmOverlap}
      />
      <ZoneDeleteConfirmation
        zoneName={deleteTarget?.name ?? null}
        labels={labels}
        onCancel={onCancelDelete}
        onDelete={onConfirmDelete}
      />
    </>
  );
}
