import { useEffect, useRef, useState, type CSSProperties } from "react";
import { KButton } from "../primitives/button.js";
import {
  planMapZoneCommit,
  planMapZoneCommits,
} from "../maps/map-zone-boolean.js";
import {
  validateMapZone,
  type KMapZone,
  type KMapZoneValidationError,
} from "../maps/map-zone-geometry.js";
import { ZoneEditorMap } from "./map-zone-editor-map.js";
import { useZoneEditorFit, useZoneEditorPanel } from "./map-zone-editor-fit.js";
import { ZoneEditorOverlays } from "./map-zone-editor-overlays.js";
import {
  normalizeZoneSettings,
  useZoneEditorProperties,
} from "./map-zone-editor-properties-state.js";
import { ZoneEditorPropertiesActions } from "./map-zone-editor-properties.js";
import { EmptyZoneStart } from "./map-zone-editor-panels.js";
import { ZoneEditorFloatingPanel } from "./map-zone-editor-floating-panel.js";
import { kDefaultMapZoneEditorLabels } from "./map-zone-editor-labels.js";
import { ZoneEditorToolbar } from "./map-zone-editor-toolbar.js";
import { useZoneEditorTransition } from "./map-zone-editor-transition.js";
import { useZoneEditorCommit } from "./map-zone-editor-commit.js";
import type {
  KMapZoneEditorProps,
  KMapZoneEditorStage,
} from "./map-zone-editor-types.js";
import {
  copyZone,
  createPolygonZone,
  createPostalZones,
  createRadiusZone,
  editorVisibleZones,
  filterPostalAreas,
  isZoneChange,
  isZoneDraftDirty,
  isZoneDraftStale,
  removeZone,
  zoneCoordinates,
  zoneValidationMessage,
} from "./map-zone-editor-state.js";
export function KMapZoneEditor({
  zones,
  editRequest,
  selectedZoneId,
  mapProps,
  onChange,
  onSelect,
  onValidationError,
  postalAreas = [],
  onPostalQueryChange,
  onPendingChangesChanged,
  onUndoActionChange,
  startCenter = mapProps.center,
  defaultRadiusKm = 3,
  labels: overrides,
  disabled = false,
  panelOpen,
  defaultPanelOpen = false,
  onPanelOpenChange,
  bottomOverlayInset = 0,
  fitMaxZoom = 17.5,
  fitDurationMs = 320,
  edgePan = {},
  propertyOptions,
  defaultZoneSettings,
}: KMapZoneEditorProps) {
  const labels = { ...kDefaultMapZoneEditorLabels, ...overrides };
  const [stage, setStage] = useState<KMapZoneEditorStage>("home");
  const [draft, setDraft] = useState<KMapZone | null>(null);
  const [history, setHistory] = useState<KMapZone[]>([]);
  const [baseSnapshot, setBaseSnapshot] = useState<string | null>();
  const [postalSelection, setPostalSelection] = useState<string[]>([]);
  const [postalQuery, setPostalQuery] = useState("");
  const [createMode, setCreateMode] = useState(false);
  const [showZoneList, setShowZoneList] = useState(false);
  const [fitRevision, setFitRevision] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState<KMapZone | null>(null);
  const [attribution, setAttribution] = useState({ open: false, height: 0 });
  const [fitCoordinates, setFitCoordinates] = useZoneEditorFit(
    zones,
    selectedZoneId,
    draft,
  );
  const dragSnapshot = useRef<KMapZone | null>(null);
  const zonesRef = useRef(zones);
  zonesRef.current = zones;
  const [isPanelOpen, setPanelOpen] = useZoneEditorPanel(
    panelOpen,
    defaultPanelOpen,
    onPanelOpenChange,
    () => setFitRevision((value) => value + 1),
  );
  const messageFor = (code: KMapZoneValidationError["code"]) =>
    zoneValidationMessage(labels, code);
  const changedExternally = isZoneDraftStale(draft, baseSnapshot, zones);
  const liveError = draft
    ? changedExternally
      ? ({ code: "external-change", message: labels.externalChange } as const)
      : validateMapZone(draft)
    : null;
  const draftDirty = isZoneDraftDirty(draft, baseSnapshot);
  const postalMatches = filterPostalAreas(postalAreas, postalQuery);
  const updateDraft = (next: KMapZone) => {
    if (!draft) return;
    setHistory((values) => [...values, copyZone(draft)]);
    setDraft(next);
  };
  const propertiesFromMap = useRef(false);
  const propertyState = useZoneEditorProperties({
    zones,
    draft,
    onUpdateDraft: updateDraft,
    onUpdateZones: (nextZones) => {
      zonesRef.current = nextZones;
      onChange(nextZones);
    },
    propertyOptions,
  });
  const properties = {
    ...propertyState,
    setOpen: (next: Parameters<typeof propertyState.setOpen>[0]) => {
      const open = typeof next === "function" ? next(propertyState.open) : next;
      propertyState.setOpen(open);
      if (!open && propertiesFromMap.current) setPanelOpen(false);
    },
  };
  const commits = useZoneEditorCommit({
    zones,
    onChange,
    blocked: !!draft || properties.dirty,
    message: labels.changesApplied,
    label: labels.undo,
    onUndoActionChange,
    onExternalChange: () =>
      onValidationError?.({
        code: "external-change",
        message: labels.externalChange,
      }),
  });
  const visibleZones =
    commits.previewZones ??
    editorVisibleZones(stage, zones, draft, postalAreas, postalSelection);
  const pendingChanges = draftDirty || properties.dirty;
  useEffect(() => {
    onPendingChangesChanged?.(pendingChanges);
  }, [pendingChanges, onPendingChangesChanged]);
  const transitions = useZoneEditorTransition(draftDirty || properties.dirty);
  const handledEdit = useRef<number | undefined>(undefined);
  useEffect(() => {
    if (!editRequest || disabled || handledEdit.current === editRequest.requestId) return;
    const zone = zones.find(zone => zone.id === editRequest.zoneId);
    if (!zone) return;
    handledEdit.current = editRequest.requestId;
    transitions.request(() => { propertiesFromMap.current = true; setPanelOpen(true); propertyState.openFor(zone); });
  }, [editRequest, disabled, zones, transitions, propertyState, setPanelOpen]);

  const begin = (zone: KMapZone) => {
    setDraft(copyZone(zone));
    setHistory([]);
    setBaseSnapshot(
      zones.some((value) => value.id === zone.id) ? JSON.stringify(zone) : null,
    );
    setStage(zone.kind === "circle" && zone.circle ? "radius" : "polygon");
    setFitCoordinates(zoneCoordinates([zone]));
    onSelect(zone.id);
    setPanelOpen(false);
  };
  const leaveDraft = () => {
    if (draft && !zones.some((zone) => zone.id === draft.id)) onSelect(null);
    setDraft(null);
    setHistory([]);
    setBaseSnapshot(undefined);
    setStage("home");
    setCreateMode(false);
    const selected = zones.find((zone) => zone.id === selectedZoneId);
    setFitCoordinates(
      selected ? zoneCoordinates([selected]) : zoneCoordinates(zones),
    );
  };
  const startRadius = () => {
    const radiusKm = Math.max(0.5, Math.min(100, defaultRadiusKm));
    begin({
      ...createRadiusZone(zones, labels.newZoneName, startCenter, radiusKm),
      settings: normalizeZoneSettings(defaultZoneSettings, propertyOptions)
        .settings,
    });
  };
  const startPolygon = () =>
    begin({
      ...createPolygonZone(zones, labels.newZoneName),
      settings: normalizeZoneSettings(defaultZoneSettings, propertyOptions)
        .settings,
    });
  const applyDraft = (candidate = draft) => {
    if (!candidate) return false;
    const error = changedExternally
      ? ({ code: "external-change", message: labels.externalChange } as const)
      : validateMapZone(candidate);
    if (error) {
      onValidationError?.({ ...error, message: messageFor(error.code) });
      return false;
    }
    const plan = planMapZoneCommit(zones, candidate);
    if (plan.impacts.length) transitions.close();
    return commits.request(plan, () => {
      setDraft(null);
      setHistory([]);
      setBaseSnapshot(undefined);
      setStage("home");
      setCreateMode(false);
      if (transitions.hasPending()) transitions.run();
    });
  };
  const togglePostal = (id: string) =>
    setPostalSelection((values) =>
      values.includes(id)
        ? values.filter((value) => value !== id)
        : [...values, id],
    );
  const applyPostal = () => {
    if (disabled || !postalSelection.length) return;
    const additions = createPostalZones(
      zones,
      postalAreas,
      postalSelection,
      normalizeZoneSettings(defaultZoneSettings, propertyOptions).settings,
    );
    const invalid = additions
      .map((zone) => validateMapZone(zone))
      .find(Boolean);
    if (invalid)
      return onValidationError?.({
        ...invalid,
        message: messageFor(invalid.code),
      });
    const plan = planMapZoneCommits(zones, additions);
    if (plan.impacts.length) transitions.close();
    commits.request(plan, () => {
      setPostalSelection([]);
      setStage("home");
      setCreateMode(false);
    });
  };
  const showAll = () => {
    setDraft(null);
    setHistory([]);
    setBaseSnapshot(undefined);
    setStage("home");
    onSelect(null);
    setFitCoordinates(zoneCoordinates(zones));
    setPanelOpen(false);
  };
  const openCreate = () => {
    setDraft(null);
    setHistory([]);
    setBaseSnapshot(undefined);
    onSelect(null);
    setCreateMode(true);
    setShowZoneList(false);
    setStage("home");
    setPanelOpen(true);
  };
  const undo = () => {
    const previous = history.at(-1);
    if (!previous) return;
    setDraft(copyZone(previous));
    setHistory((values) => values.slice(0, -1));
  };
  const discardChanges = () => {
    if (baseSnapshot === null) return leaveDraft();
    if (baseSnapshot === undefined) return;
    const original = JSON.parse(baseSnapshot) as KMapZone;
    setDraft(copyZone(original));
    setHistory([]);
    setStage(
      original.kind === "circle" && original.circle ? "radius" : "polygon",
    );
  };
  const requestDelete = (zone: KMapZone) =>
    transitions.request(() => setDeleteTarget(zone));
  const confirmDelete = () => {
    if (!deleteTarget) return;
    const remaining = removeZone(zonesRef.current, deleteTarget.id);
    zonesRef.current = remaining;
    onChange(remaining);
    if (selectedZoneId === deleteTarget.id) onSelect(null);
    if (draft?.id === deleteTarget.id) {
      setDraft(null);
      setHistory([]);
      setBaseSnapshot(undefined);
    }
    setDeleteTarget(null);
    properties.setOpen(false);
    setStage("home");
    setCreateMode(false);
    setFitCoordinates(zoneCoordinates(remaining));
    if (!remaining.length) setPanelOpen(false);
  };
  const emptyIdle = !zones.length && !draft && stage === "home";
  const selectedZone = zones.find((zone) => zone.id === selectedZoneId) ?? null;
  const zoneListVisible = showZoneList || (stage === "home" && !createMode);
  const panelTitle = properties.open
    ? labels.zoneProperties
    : createMode
      ? labels.addZone
      : stage === "home" || showZoneList
        ? labels.zones
        : labels[`${stage}Title`];
  const panel = (
    <ZoneEditorFloatingPanel
      labels={labels}
      zones={zones}
      selectedZoneId={selectedZoneId}
      showZoneList={showZoneList}
      createMode={createMode}
      editingZoneId={draftDirty ? (draft?.id ?? null) : null}
      stage={stage}
      draft={draft}
      draftError={liveError ? messageFor(liveError.code) : null}
      postalAreas={postalMatches}
      postalQuery={postalQuery}
      postalSelection={postalSelection}
      disabled={disabled}
      properties={properties}
      propertyOptions={propertyOptions}
      onSelect={(zone) => {
        if (draft?.id === zone.id) setShowZoneList(false);
        else transitions.request(() => begin(zone));
      }}
      onEdit={(zone) => {
        propertiesFromMap.current = false;
        if (properties.zone?.id === zone.id) properties.setOpen(true);
        else transitions.request(() => properties.openFor(zone));
      }}
      onDelete={requestDelete}
      onShowAll={() => transitions.request(showAll)}
      onStartRadius={startRadius}
      onStartPostal={() => setStage("postal")}
      onStartPolygon={startPolygon}
      onLeaveDraft={() => transitions.request(leaveDraft)}
      onPostalQuery={(query) => {
        setPostalQuery(query);
        onPostalQueryChange?.(query);
      }}
      onTogglePostal={togglePostal}
      onApplyPostal={applyPostal}
      onUpdateDraft={updateDraft}
    />
  );
  return (
    <section className="k-map-zone-editor-container" aria-label={labels.editor}>
      <div className="k-map-zone-editor" data-stage={stage}>
        <div
          className="k-map-zone-editor__map"
          data-empty={emptyIdle || undefined}
          data-attribution-open={attribution.open || undefined}
          style={
            {
              "--k-map-zone-editor-bottom-overlay-inset": `${Number.isFinite(bottomOverlayInset) ? Math.max(0, bottomOverlayInset) : 0}px`,
              "--k-map-zone-editor-attribution-height": `${attribution.height}px`,
            } as CSSProperties
          }
        >
          <ZoneEditorMap
            mapProps={mapProps}
            zones={zones}
            visibleZones={visibleZones}
            selectedZoneId={selectedZoneId}
            stage={stage}
            draft={draft}
            baseSnapshot={baseSnapshot}
            postalSelection={postalSelection}
            fitCoordinates={fitCoordinates}
            fitMaxZoom={fitMaxZoom}
            fitDurationMs={fitDurationMs}
            fitRevision={fitRevision}
            edgePan={edgePan}
            invalid={!!liveError}
            disabled={disabled}
            labels={labels}
            onUpdateDraft={updateDraft}
            onPreviewDraft={setDraft}
            onBeginDraftGesture={() => {
              if (!draft || dragSnapshot.current) return;
              dragSnapshot.current = copyZone(draft);
              setHistory((values) => [...values, copyZone(draft)]);
            }}
            onEndDraftGesture={() => {
              const snapshot = dragSnapshot.current;
              if (snapshot && draft) {
                if (!isZoneChange(snapshot, draft))
                  setHistory((values) => values.slice(0, -1));
              }
              dragSnapshot.current = null;
            }}
            onCancelDraftGesture={() => {
              const snapshot = dragSnapshot.current;
              if (!snapshot) return;
              setDraft(snapshot);
              setHistory((values) => values.slice(0, -1));
              dragSnapshot.current = null;
            }}
            onBegin={(zone) => transitions.request(() => begin(zone))}
            onTogglePostal={togglePostal}
            onAttributionChange={setAttribution}
          />
          {emptyIdle && (
            <EmptyZoneStart
              labels={labels}
              disabled={disabled}
              onRadius={startRadius}
              onPostal={() => {
                setCreateMode(false);
                setStage("postal");
                setPanelOpen(true);
              }}
              onPolygon={startPolygon}
            />
          )}
          <ZoneEditorToolbar
            zones={zones}
            selectedZoneId={selectedZoneId}
            draft={draft}
            open={isPanelOpen}
            dirty={draftDirty}
            canUndo={history.length > 0}
            disabled={disabled}
            canFinish={!!draft?.name.trim() && !liveError}
            labels={labels}
            panelTitle={panelTitle}
            panelSubtitle={properties.open ? properties.zone?.name : undefined}
            onPanelBack={
              properties.open
                ? () => transitions.request(() => properties.setOpen(false))
                : undefined
            }
            panelBackFocusId={properties.zone?.id}
            panelMode={
              properties.open
                ? "properties"
                : createMode
                  ? "create"
                  : stage === "postal"
                    ? "postal"
                    : "list"
            }
            panel={panel}
            panelActions={
              properties.open ? (
                <ZoneEditorPropertiesActions
                  controller={properties}
                  labels={labels}
                  onCancel={() =>
                    transitions.request(() => properties.setOpen(false))
                  }
                  onDelete={() => {
                    if (properties.zone) requestDelete(properties.zone);
                  }}
                />
              ) : zoneListVisible ? (
                <KButton
                  fullWidth
                  disabled={disabled}
                  onClick={() => transitions.request(openCreate)}
                >
                  {labels.addZone}
                </KButton>
              ) : undefined
            }
            onPanelEscape={
              properties.open
                ? () => transitions.request(() => properties.setOpen(false))
                : undefined
            }
            onOpenChange={(open) => {
              if (open) {
                setCreateMode(false);
                setShowZoneList(true);
                setPanelOpen(true);
              } else {
                transitions.request(() => {
                  properties.setOpen(false);
                  setPanelOpen(false);
                });
              }
            }}
            onAdd={() => transitions.request(openCreate)}
            onProperties={() => {
              const current = draft ?? selectedZone;
              if (!current) return;
              const showProperties = () => {
                propertiesFromMap.current = !isPanelOpen;
                properties.openFor(current);
                setPanelOpen(true);
              };
              if (properties.zone?.id === current.id) showProperties();
              else transitions.request(showProperties);
            }}
            onUndo={undo}
            onDiscard={discardChanges}
            onFinish={() => applyDraft()}
          />
        </div>
      </div>
      <ZoneEditorOverlays
        labels={labels}
        confirmOpen={transitions.open}
        canSave={
          (!draftDirty || (!liveError && !!draft?.name.trim())) &&
          (!properties.dirty || properties.canApply)
        }
        saveDisabledReason={
          properties.dirty && !properties.canApply
            ? labels.zoneNameRequired
            : liveError
              ? messageFor(liveError.code)
              : labels.zoneNameRequired
        }
        deleteTarget={deleteTarget}
        onContinue={transitions.continueEditing}
        onDiscard={() => {
          properties.discard();
          leaveDraft();
          transitions.run();
        }}
        onSave={() => {
          const propertyTargetsDraft =
            properties.dirty && properties.zone?.id === draft?.id;
          const candidate = propertyTargetsDraft ? properties.nextZone : draft;
          if (properties.dirty && !properties.apply()) return;
          if (draftDirty || propertyTargetsDraft) {
            if (applyDraft(candidate)) transitions.run();
          } else transitions.run();
        }}
        onCancelDelete={() => setDeleteTarget(null)}
        onConfirmDelete={confirmDelete}
        overlapImpacts={commits.pending?.impacts ?? []}
        onCancelOverlap={commits.cancel}
        onConfirmOverlap={commits.confirm}
      />
    </section>
  );
}
