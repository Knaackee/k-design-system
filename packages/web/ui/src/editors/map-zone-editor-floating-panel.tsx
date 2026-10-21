import type { KMapPostalArea, KMapZone } from "../maps/map-zone-geometry.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import {
  DraftPanel,
  HomePanel,
  PostalPanel,
} from "./map-zone-editor-panels.js";
import { ZoneEditorPropertiesFields } from "./map-zone-editor-properties.js";
import type { ZoneEditorPropertyController } from "./map-zone-editor-properties-state.js";
import type {
  KMapZoneEditorStage,
  KMapZonePropertyOptions,
} from "./map-zone-editor-types.js";

export function ZoneEditorFloatingPanel({
  labels,
  zones,
  selectedZoneId,
  showZoneList,
  createMode,
  editingZoneId,
  stage,
  draft,
  draftError,
  postalAreas,
  postalQuery,
  postalSelection,
  disabled,
  properties,
  propertyOptions,
  onSelect,
  onEdit,
  onDelete,
  onShowAll,
  onStartRadius,
  onStartPostal,
  onStartPolygon,
  onLeaveDraft,
  onPostalQuery,
  onTogglePostal,
  onApplyPostal,
  onUpdateDraft,
}: {
  labels: KMapZoneEditorLabels;
  zones: readonly KMapZone[];
  selectedZoneId: string | null;
  showZoneList: boolean;
  createMode: boolean;
  editingZoneId: string | null;
  stage: KMapZoneEditorStage;
  draft: KMapZone | null;
  draftError: string | null;
  postalAreas: readonly KMapPostalArea[];
  postalQuery: string;
  postalSelection: readonly string[];
  disabled: boolean;
  properties: ZoneEditorPropertyController;
  propertyOptions?: KMapZonePropertyOptions;
  onSelect: (zone: KMapZone) => void;
  onEdit: (zone: KMapZone) => void;
  onDelete: (zone: KMapZone) => void;
  onShowAll: () => void;
  onStartRadius: () => void;
  onStartPostal: () => void;
  onStartPolygon: () => void;
  onLeaveDraft: () => void;
  onPostalQuery: (query: string) => void;
  onTogglePostal: (id: string) => void;
  onApplyPostal: () => void;
  onUpdateDraft: (zone: KMapZone) => void;
}) {
  return (
    <>
      <div
        className="k-map-zone-editor__floating-dialog-view"
        hidden={properties.open}
      >
        <div className="k-map-zone-editor__panel">
          {showZoneList || stage === "home" ? (
            <HomePanel
              labels={labels}
              zones={zones}
              selectedZoneId={selectedZoneId}
              createMode={createMode && !showZoneList}
              editingZoneId={editingZoneId}
              disabled={disabled}
              onSelect={onSelect}
              onEdit={onEdit}
              onDelete={onDelete}
              onShowAll={onShowAll}
              onStartRadius={onStartRadius}
              onStartPostal={onStartPostal}
              onStartPolygon={onStartPolygon}
            />
          ) : stage === "postal" ? (
            <PostalPanel
              labels={labels}
              areas={postalAreas}
              query={postalQuery}
              selection={postalSelection}
              disabled={disabled}
              onBack={onLeaveDraft}
              onQuery={onPostalQuery}
              onToggle={onTogglePostal}
              onApply={onApplyPostal}
            />
          ) : draft ? (
            <DraftPanel
              labels={labels}
              draft={draft}
              stage={stage}
              error={draftError}
              disabled={disabled}
              onBack={onLeaveDraft}
              onUpdate={onUpdateDraft}
              onGeometryUpdate={onUpdateDraft}
            />
          ) : null}
        </div>
      </div>
      {properties.zone ? (
        <div
          className="k-map-zone-editor__floating-dialog-view"
          hidden={!properties.open}
        >
          <ZoneEditorPropertiesFields
            controller={properties}
            labels={labels}
            propertyOptions={propertyOptions}
          />
        </div>
      ) : null}
    </>
  );
}
