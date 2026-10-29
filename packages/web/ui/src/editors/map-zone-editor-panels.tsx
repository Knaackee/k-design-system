import { KSlider } from "../extended-components.js";
import { KIconButton } from "../actions/icon-button.js";
import { KInput } from "../forms/input.js";
import { KCheckbox } from "../forms/checkbox.js";
import {
  createCircleCoordinates,
  type KMapPostalArea,
  type KMapZone,
} from "../maps/map-zone-geometry.js";
import { mapZoneCssColor } from "../maps/map-zone-colors.js";
import { KButton } from "../primitives/button.js";
import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import type { KMapZoneEditorStage } from "./map-zone-editor-types.js";

function PanelHeader({
  labels,
  stage,
  onBack,
}: {
  labels: KMapZoneEditorLabels;
  stage: Exclude<KMapZoneEditorStage, "home">;
  onBack: () => void;
}) {
  return (
    <header className="k-map-zone-editor__header">
      <KButton variant="ghost" onClick={onBack}>
        {labels.back}
      </KButton>
      <p>{labels[`${stage}Description`]}</p>
    </header>
  );
}

export function HomePanel({
  labels,
  zones,
  selectedZoneId,
  createMode,
  editingZoneId,
  disabled,
  onSelect,
  onEdit,
  onDelete,
  onShowAll,
  onStartRadius,
  onStartPostal,
  onStartPolygon,
}: {
  labels: KMapZoneEditorLabels;
  zones: readonly KMapZone[];
  selectedZoneId: string | null;
  createMode: boolean;
  editingZoneId: string | null;
  disabled: boolean;
  onSelect: (zone: KMapZone) => void;
  onEdit: (zone: KMapZone) => void;
  onDelete: (zone: KMapZone) => void;
  onShowAll: () => void;
  onStartRadius: () => void;
  onStartPostal: () => void;
  onStartPolygon: () => void;
}) {
  return (
    <>
      {createMode ? (
        <ZoneCreationOptions
          labels={labels}
          disabled={disabled}
          onRadius={onStartRadius}
          onPostal={onStartPostal}
          onPolygon={onStartPolygon}
        />
      ) : (
        <div className="k-map-zone-editor__saved">
          {editingZoneId && (
            <p className="k-map-zone-editor__hint">{labels.finishEditing}</p>
          )}
          <ul className="k-map-zone-editor__zones">
            <li>
              <button
                type="button"
                className="k-map-zone-editor__zone-select"
                aria-pressed={!selectedZoneId}
                disabled={disabled}
                onClick={onShowAll}
              >
                <span>
                  <strong>{labels.allZones}</strong>
                </span>
              </button>
            </li>
            {zones.map((zone) => (
              <li key={zone.id}>
                <button
                  type="button"
                  className="k-map-zone-editor__zone-select"
                  aria-pressed={selectedZoneId === zone.id}
                  disabled={disabled}
                  onClick={() => onSelect(zone)}
                >
                  <span
                    className="k-map-zone-editor__swatch"
                    style={{
                      background: zone.color
                        ? mapZoneCssColor(zone.color)
                        : undefined,
                    }}
                  />
                  <span>
                    <strong>{zone.name}</strong>
                    <small>
                      {zone.kind === "circle"
                        ? `${labels.radiusTitle} · ${zone.circle?.radiusKm.toFixed(1)} km`
                        : zone.source
                          ? `${zone.kind === "postal" ? labels.postalTitle : labels.customArea} · ${zone.source.code}`
                          : labels.customArea}
                    </small>
                  </span>
                </button>
                <div className="k-map-zone-editor__zone-actions">
                  <KIconButton
                    icon="pencil"
                    label={`${labels.editZone}: ${zone.name}`}
                    data-zone-editor-edit={zone.id}
                    variant="ghost"
                    disabled={disabled}
                    onClick={() => onEdit(zone)}
                  />
                  <KIconButton
                    icon="trash"
                    label={`${labels.deleteZone}: ${zone.name}`}
                    variant="ghost"
                    disabled={disabled}
                    onClick={() => onDelete(zone)}
                  />
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}

export function ZoneCreationOptions({
  labels,
  disabled,
  showIntro = true,
  onRadius,
  onPostal,
  onPolygon,
}: {
  labels: KMapZoneEditorLabels;
  disabled: boolean;
  showIntro?: boolean;
  onRadius: () => void;
  onPostal: () => void;
  onPolygon: () => void;
}) {
  const entries = [
    [labels.radiusTitle, labels.radiusDescription, onRadius],
    [labels.postalTitle, labels.postalDescription, onPostal],
    [labels.polygonTitle, labels.polygonDescription, onPolygon],
  ] as const;
  return (
    <>
      {showIntro && <p className="k-map-zone-editor__hint">{labels.intro}</p>}
      <div className="k-map-zone-editor__entries">
        {entries.map(([title, description, action], index) => (
          <button
            key={title}
            type="button"
            disabled={disabled}
            onClick={action}
          >
            <span aria-hidden="true">
              <svg viewBox="0 0 96 72" focusable="false">
                <path d="M0 16H96M0 48H96M24 0V72M67 0V72M0 70L96 4" fill="none" stroke="currentColor" opacity=".14" strokeWidth="5" />
                <g fill="currentColor" fillOpacity=".16" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round">
                  {index === 0 ? <><circle cx="48" cy="36" r="25"/><path d="M48 36H73" strokeDasharray="3 3"/><circle cx="48" cy="36" r="3" fillOpacity="1"/></> : index === 1 ? <><path d="M15 12L42 9L53 29L34 45L12 36Z"/><path d="M53 29L80 18L85 49L61 61L34 45Z" fillOpacity=".32"/></> : <><path d="M17 19L49 10L79 28L66 60L29 55L12 38Z"/>{[[17,19],[49,10],[79,28],[66,60],[29,55],[12,38]].map(([cx,cy]) => <circle key={cx} cx={cx} cy={cy} r="2.5" fillOpacity="1"/>)}</>}
                </g>
              </svg>
            </span>
            <strong>{title}</strong>
            <small>{description}</small>
          </button>
        ))}
      </div>
    </>
  );
}

export function EmptyZoneStart({
  labels,
  disabled,
  onRadius,
  onPostal,
  onPolygon,
}: {
  labels: KMapZoneEditorLabels;
  disabled: boolean;
  onRadius: () => void;
  onPostal: () => void;
  onPolygon: () => void;
}) {
  return (
    <div className="k-map-zone-editor__empty">
      <strong>{labels.createFirstZone}</strong>
      <p>{labels.empty}</p>
      <ZoneCreationOptions
        labels={labels}
        disabled={disabled}
        showIntro={false}
        onRadius={onRadius}
        onPostal={onPostal}
        onPolygon={onPolygon}
      />
    </div>
  );
}

export function PostalPanel({
  labels,
  areas,
  query,
  selection,
  disabled,
  onBack,
  onQuery,
  onToggle,
  onApply,
}: {
  labels: KMapZoneEditorLabels;
  areas: readonly KMapPostalArea[];
  query: string;
  selection: readonly string[];
  disabled: boolean;
  onBack: () => void;
  onQuery: (value: string) => void;
  onToggle: (id: string) => void;
  onApply: () => void;
}) {
  return (
    <>
      <PanelHeader labels={labels} stage="postal" onBack={onBack} />
      <KInput
        value={query}
        placeholder={labels.postalSearch}
        aria-label={labels.postalSearch}
        onChange={(event) => onQuery(event.target.value)}
      />
      <p className="k-map-zone-editor__source">
        {labels.sampleData}: {areas[0]?.sourceLabel ?? "—"}
      </p>
      <div className="k-map-zone-editor__postal-list">
        {areas.length ? (
          areas.map((area) => (
            <div key={area.id}>
              <KCheckbox
                label={
                  area.label === area.code
                    ? area.code
                    : `${area.code} · ${area.label}`
                }
                value={selection.includes(area.id)}
                disabled={disabled || !!area.assignedZoneId}
                onValueChange={() => onToggle(area.id)}
              />
              {area.assignedZoneId && (
                <small>{labels.assignedPostalArea}</small>
              )}
            </div>
          ))
        ) : (
          <p>{labels.postalEmpty}</p>
        )}
      </div>
      <div className="k-map-zone-editor__actions">
        <span>
          {labels.postalSelection}: {selection.length}
        </span>
        <KButton disabled={disabled || !selection.length} onClick={onApply}>
          {labels.apply}
        </KButton>
      </div>
    </>
  );
}

export function DraftPanel({
  labels,
  draft,
  stage,
  error,
  disabled,
  onBack,
  onUpdate,
  onGeometryUpdate,
}: {
  labels: KMapZoneEditorLabels;
  draft: KMapZone;
  stage: "radius" | "polygon";
  error: string | null;
  disabled: boolean;
  onBack: () => void;
  onUpdate: (zone: KMapZone) => void;
  onGeometryUpdate: (zone: KMapZone) => void;
}) {
  const setRadius = (value: number) => {
    if (!draft.circle) return;
    const radiusKm = Math.max(0.5, Math.min(100, value || 0.5));
    onUpdate({
      ...draft,
      circle: { ...draft.circle, radiusKm },
      coordinates: createCircleCoordinates(draft.circle.center, radiusKm),
    });
  };
  return (
    <>
      <PanelHeader labels={labels} stage={stage} onBack={onBack} />
      <div className="k-map-zone-editor__draft">
        {stage === "radius" && draft.circle ? (
          <div className="k-map-zone-editor__radius">
            <div>
              <strong>{labels.radius}</strong>
              <span>
                {draft.circle.radiusKm.toFixed(1)} km · {labels.airDistance}
              </span>
            </div>
            <KSlider
              value={draft.circle.radiusKm}
              min={0.5}
              max={25}
              step={0.5}
              label={labels.radius}
              disabled={disabled}
              valueLabel={(value) => `${value} Kilometer`}
              onValueChange={setRadius}
            />
            <KInput
              type="number"
              min={0.5}
              max={100}
              step={0.5}
              value={draft.circle.radiusKm}
              aria-label={`${labels.radius} in Kilometern`}
              disabled={disabled}
              onChange={(event) => setRadius(Number(event.target.value))}
            />
          </div>
        ) : (
          <>
            {draft.source && (
              <p className="k-map-zone-editor__source">
                {draft.kind === "postal"
                  ? labels.postalTitle
                  : labels.customArea}{" "}
                · {draft.source.country} {draft.source.code} ·{" "}
                {draft.source.provider}
                {draft.source.version ? ` · ${draft.source.version}` : ""}
              </p>
            )}
            <p className="k-map-zone-editor__hint">{labels.addVertexHint}</p>
            <div className="k-map-zone-editor__vertex-heading">
              <strong>{labels.vertices}</strong>
              <span>{draft.coordinates.length}</span>
            </div>
            {!!draft.coordinates.length && (
              <KButton
                variant="ghost"
                disabled={disabled}
                onClick={() =>
                  onGeometryUpdate({
                    ...draft,
                    kind: draft.kind === "postal" ? "polygon" : draft.kind,
                    coordinates: draft.coordinates.slice(0, -1),
                  })
                }
              >
                {labels.removePoint}
              </KButton>
            )}
          </>
        )}
        {error && (
          <p className="k-map-zone-editor__error" role="alert">
            {error}
          </p>
        )}
      </div>
    </>
  );
}
