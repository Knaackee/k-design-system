import { KDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import type { KMapZoneCommitImpact } from "../maps/map-zone-boolean.js";

export function ZoneOverlapConfirmation({
  impacts,
  labels,
  onCancel,
  onConfirm,
}: {
  impacts: readonly KMapZoneCommitImpact[];
  labels: KMapZoneEditorLabels;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <KDialog
      open={impacts.length > 0}
      onOpenChange={(open) => !open && onCancel()}
      title={labels.overlapTitle}
      description={labels.overlapDescription}
      actions={
        <div className="k-map-zone-editor__confirmation-actions">
          <KButton variant="secondary" onClick={onCancel}>
            {labels.cancel}
          </KButton>
          <KButton onClick={onConfirm}>{labels.confirmOverlap}</KButton>
        </div>
      }
    >
      <ul className="k-map-zone-editor__impact-list">
        {impacts.map((impact) => (
          <li key={impact.zoneId}>
            <strong>{impact.zoneName}</strong>{" "}
            {impact.outcome === "removed"
              ? labels.overlapRemoved
              : labels.overlapReduced}
          </li>
        ))}
      </ul>
    </KDialog>
  );
}

export function ZoneDeleteConfirmation({
  zoneName,
  labels,
  onCancel,
  onDelete,
}: {
  zoneName: string | null;
  labels: KMapZoneEditorLabels;
  onCancel: () => void;
  onDelete: () => void;
}) {
  return (
    <KDialog
      open={!!zoneName}
      onOpenChange={(open) => !open && onCancel()}
      title={labels.deleteZoneTitle}
      description={labels.deleteZoneDescription.replace(
        "{name}",
        zoneName ?? "",
      )}
      actions={
        <div className="k-map-zone-editor__confirmation-actions">
          <KButton variant="secondary" onClick={onCancel}>
            {labels.cancel}
          </KButton>
          <KButton onClick={onDelete}>{labels.confirmDeleteZone}</KButton>
        </div>
      }
    >
      <span />
    </KDialog>
  );
}

export function ZoneEditorFeedback({
  labels,
  confirmOpen,
  canSave,
  saveDisabledReason,
  onSave,
  onDiscard,
  onContinue,
}: {
  labels: KMapZoneEditorLabels;
  confirmOpen: boolean;
  canSave: boolean;
  saveDisabledReason?: string;
  onSave: () => void;
  onDiscard: () => void;
  onContinue: () => void;
}) {
  return (
    <KDialog
      open={confirmOpen}
      onOpenChange={(open) => {
        if (!open) onContinue();
      }}
      title={labels.unsavedTitle}
      description={
        <>
          {labels.unsavedDescription}
          {!canSave && saveDisabledReason ? (
            <>
              <br />
              {saveDisabledReason}
            </>
          ) : null}
        </>
      }
      dismissible={false}
      className="k-map-zone-editor__confirmation"
      actions={
        <div className="k-map-zone-editor__confirmation-actions">
          <KButton variant="secondary" onClick={onContinue}>
            {labels.continueEditing}
          </KButton>
          <KButton variant="secondary" onClick={onDiscard}>
            {labels.discard}
          </KButton>
          <KButton disabled={!canSave} onClick={onSave}>
            {labels.save}
          </KButton>
        </div>
      }
    >
      <span />
    </KDialog>
  );
}
