import {
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type MouseEvent,
  type ReactElement,
} from "react";
import { KButton } from "../../primitives/button.js";
import { KContextMenu } from "../../actions/context-menu.js";
import type { KMenuAction } from "../../actions/menu-button.js";
import { KSlider } from "../../extended-components.js";
import { useKOrbitGestures } from "./orbit-gestures.js";
import { useKOrbitPresence } from "./orbit-presence.js";
import { layoutKOrbit } from "./orbit-layout.js";
import { resolveKOrbitPointerNode } from "./orbit-label-layout.js";
import { useKOrbitRenderer } from "./orbit-renderer.js";
import {
  KOrbitController,
  kOrbitDefaultView,
  kOrbitSceneExtent,
  validateKOrbit,
  type KOrbitConnection,
  type KOrbitLevel,
  type KOrbitNode,
  type KOrbitSignalEndReason,
  type KOrbitSignalStyle,
  type KOrbitViewState,
} from "./orbit-model.js";

export interface KOrbitLabels {
  stage?: string;
  instructions?: string;
  reset?: string;
  pause?: string;
  resume?: string;
  speed?: string;
}
export interface KOrbitProps {
  /** Flat, subtree-aware spacing. Explicit geometry remains the default. */
  autoLayout?: boolean;
  /** Minimum world-unit clearance between reserved subtrees. Default 12. */
  layoutGap?: number;
  levels: readonly KOrbitLevel[];
  nodes: readonly KOrbitNode[];
  connections?: readonly KOrbitConnection[];
  controller?: KOrbitController;
  /** Controlled camera target. Null releases tracking and restores the default view. */
  pinnedId?: string | null;
  onPinnedChange?(id: string | null): void;
  selectedId?: string | null;
  defaultSelectedId?: string | null;
  onSelectionChange?(id: string | null): void;
  onNodeActivate?(node: KOrbitNode): void;
  nodeActions?(node: KOrbitNode): readonly KMenuAction[];
  view?: KOrbitViewState;
  defaultView?: KOrbitViewState;
  onViewChange?(view: KOrbitViewState): void;
  onInteractionStart?(): void;
  onInteractionEnd?(): void;
  onSignalEnd?(id: string, reason: KOrbitSignalEndReason): void;
  paused?: boolean;
  onPausedChange?(paused: boolean): void;
  motionSpeed?: number;
  onMotionSpeedChange?(speed: number): void;
  /** Effective local angular speed limit after motionSpeed, degrees/second. Default 12. */
  maxAngularSpeed?: number;
  maxActiveSignals?: number;
  /** Positive inclusive [minimum, maximum] zoom; updates clamp the current view. */
  zoomBounds?: readonly [number, number];
  lineStyle?: KOrbitConnection["lineStyle"];
  signalStyle?: KOrbitSignalStyle;
  reducedMotion?: boolean;
  elapsedSeconds?: number;
  interactionMode?: "dedicated" | "embedded";
  showControls?: boolean;
  labelVisibility?: "interaction" | "always" | "hidden";
  labels?: KOrbitLabels;
  className?: string;
  style?: CSSProperties;
}
const fallbackLabels: Required<KOrbitLabels> = {
  stage: "Interactive orbit",
  instructions:
    "Drag with the left mouse button to pan, the right button to rotate. Use arrow keys to rotate, plus or minus to zoom, and Home to reset.",
  reset: "Reset view",
  pause: "Pause motion",
  resume: "Resume motion",
  speed: "Motion speed",
};
export function KOrbit(input: KOrbitProps): ReactElement {
  const layout = useMemo(
    () =>
      input.autoLayout
        ? layoutKOrbit(input.levels, input.nodes, input.layoutGap)
        : null,
    [input.autoLayout, input.layoutGap, input.levels, input.nodes],
  );
  const props = layout ? { ...input, ...layout } : input;
  const connections = props.connections ?? [];
  useMemo(
    () => validateKOrbit(props.levels, props.nodes, connections),
    [props.levels, props.nodes, connections],
  );
  const root = useRef<HTMLDivElement>(null);
  const instructionsId = useId();
  const canvas = useRef<HTMLCanvasElement>(null);
  const shaderCanvas = useRef<HTMLCanvasElement>(null);
  const nodeElements = useRef(new Map<string, HTMLButtonElement>());
  const projectedPoints = useRef(
    new Map<string, { x: number; y: number; depth: number }>(),
  );
  const latest = useRef(props);
  latest.current = props;
  const [internalSelection, setInternalSelection] = useState(
    props.defaultSelectedId ?? null,
  );
  const selected =
    props.selectedId === undefined ? internalSelection : props.selectedId;
  const [internalView, setInternalView] = useState(() =>
    clampView(props.defaultView ?? kOrbitDefaultView, props.zoomBounds),
  );
  const currentView = useRef(
    clampView(props.view ?? internalView, props.zoomBounds),
  );
  currentView.current = clampView(props.view ?? internalView, props.zoomBounds);
  const [systemReduced, setSystemReduced] = useState(false);
  const [focused, setFocused] = useState(false);
  const [contextMenuOpen, setContextMenuOpen] = useState(false);
  const labels = { ...fallbackLabels, ...props.labels };
  const speed = props.motionSpeed ?? 1;
  if (
    !Number.isFinite(speed) ||
    speed < 0 ||
    !Number.isFinite(props.maxAngularSpeed ?? 12) ||
    (props.maxAngularSpeed ?? 12) < 0
  )
    throw new Error(
      "KOrbit speed and maxAngularSpeed must be finite and non-negative",
    );
  const reduced = props.reducedMotion ?? systemReduced;
  const paused = props.paused ?? false;
  const zoomBounds = props.zoomBounds ?? [0.65, 2.2];
  const pinned = props.nodes.some((node) => node.id === props.pinnedId)
    ? props.pinnedId
    : null;
  const previousPin = useRef<string | null | undefined>(null);
  const presence = useKOrbitPresence(props.levels, props.nodes, root, reduced);
  const changeView = (next: KOrbitViewState) => {
    const value = clampView(next, zoomBounds);
    currentView.current = value;
    if (latest.current.view === undefined) setInternalView(value);
    latest.current.onViewChange?.(value);
  };
  const select = (id: string | null) => {
    if (latest.current.selectedId === undefined) setInternalSelection(id);
    latest.current.onSelectionChange?.(id);
  };
  const activate = (
    fallback: KOrbitNode,
    event: MouseEvent<HTMLButtonElement>,
  ) => {
    if (event.detail !== 0 && gestures.dragged.current) return;
    let node = fallback;
    if (event.detail !== 0) {
      const bounds = root.current?.getBoundingClientRect();
      const resolved = resolveKOrbitPointerNode(
        { x: event.clientX, y: event.clientY },
        presence.nodes.flatMap((candidate) => {
          const element = nodeElements.current.get(candidate.id);
          const point = projectedPoints.current.get(candidate.id);
          if (
            !bounds ||
            !element ||
            !point ||
            candidate.disabled ||
            presence.departingIds.has(candidate.id) ||
            element.dataset.occluded === "true"
          )
            return [];
          const label = element.querySelector<HTMLElement>(
            ".k-orbit__node-label",
          );
          const labelBounds =
            label && getComputedStyle(label).display !== "none"
              ? label.getBoundingClientRect()
              : undefined;
          return [
            {
              id: candidate.id,
              x: bounds.left + point.x,
              y: bounds.top + point.y,
              radius: element.offsetWidth / 2,
              label: labelBounds
                ? {
                    left: labelBounds.left,
                    top: labelBounds.top,
                    right: labelBounds.right,
                    bottom: labelBounds.bottom,
                  }
                : undefined,
            },
          ];
        }),
      );
      const resolvedNode = presence.nodes.find(({ id }) => id === resolved);
      if (!resolvedNode) return;
      node = resolvedNode;
    }
    if (node.disabled || presence.departingIds.has(node.id)) return;
    select(node.id);
    props.onNodeActivate?.(node);
  };
  const gestures = useKOrbitGestures({
    root,
    view: currentView,
    changeView,
    clearSelection: () => select(null),
    defaultView: props.defaultView,
    zoomBounds,
    reducedMotion: reduced,
    interactionMode: props.interactionMode,
    panDisabled: Boolean(pinned),
    contextMenuEnabled: Boolean(props.nodeActions),
    onInteractionStart: props.onInteractionStart,
    onInteractionEnd: props.onInteractionEnd,
  });
  useEffect(() => {
    if (pinned && previousPin.current !== pinned) {
      changeView({
        ...currentView.current,
        zoom:
          kOrbitSceneExtent(props.levels, props.nodes) /
          kOrbitSceneExtent(props.levels, props.nodes, pinned),
      });
    }
    if (previousPin.current && !pinned) {
      gestures.inertia.current = { x: 0, y: 0 };
      changeView({
        ...(latest.current.defaultView ?? kOrbitDefaultView),
        offset: { x: 0, y: 0 },
      });
    }
    previousPin.current = pinned;
    if (props.pinnedId && !pinned) props.onPinnedChange?.(null);
  }, [pinned, props.pinnedId]);
  useEffect(() => {
    const media = window.matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setSystemReduced(media.matches);
    update();
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  useEffect(() => {
    if (selected && !props.nodes.some(({ id }) => id === selected))
      select(null);
  }, [props.nodes, selected]);
  useKOrbitRenderer({
    root,
    canvas,
    shaderCanvas,
    nodeElements,
    projectedPoints,
    levels: presence.levels,
    nodes: presence.nodes,
    connections,
    controller: props.controller,
    view: currentView,
    changeView,
    interacting: gestures.interacting,
    inertia: gestures.inertia,
    focused,
    paused: paused || contextMenuOpen,
    speed,
    maxAngularSpeed: props.maxAngularSpeed,
    synchronizeLevels: props.autoLayout,
    reducedMotion: reduced,
    elapsedSeconds: props.elapsedSeconds,
    extent: presence.extent,
    presenceMotion: presence.motion,
    labelVisibility: props.labelVisibility ?? "interaction",
    departingIds: presence.departingIds,
    selectedId: selected,
    pinnedId: pinned,
    lineStyle: props.lineStyle,
    signalStyle: props.signalStyle,
    maxActiveSignals: props.maxActiveSignals,
    onSignalEnd: props.onSignalEnd,
  });
  return (
    <div
      className={["k-orbit", props.className].filter(Boolean).join(" ")}
      style={props.style}
    >
      <div
        ref={root}
        className="k-orbit__stage"
        role="application"
        aria-label={labels.stage}
        aria-describedby={instructionsId}
        data-pinned-id={pinned ?? undefined}
        data-label-visibility={props.labelVisibility ?? "interaction"}
        data-interaction-mode={props.interactionMode ?? "dedicated"}
        tabIndex={0}
        onFocusCapture={(event) =>
          setFocused((event.target as HTMLElement).matches(":focus-visible"))
        }
        onBlurCapture={(event) => {
          if (!event.currentTarget.contains(event.relatedTarget))
            setFocused(false);
        }}
        onKeyDown={(event) => {
          if ((event.target as HTMLElement).closest('[role="menu"]')) return;
          setFocused(true);
          if (event.key === "Home") props.onPinnedChange?.(null);
          gestures.onKeyDown(event);
        }}
        onPointerDown={(event) => {
          setFocused(false);
          gestures.onPointerDown(event);
        }}
        onContextMenu={(event) => event.preventDefault()}
        onPointerMove={gestures.onPointerMove}
        onPointerUp={gestures.onPointerEnd}
        onPointerCancel={gestures.onPointerEnd}
      >
        <span id={instructionsId} className="k-orbit__sr-only">
          {labels.instructions}
        </span>
        <canvas
          ref={shaderCanvas}
          className="k-orbit__shader"
          aria-hidden="true"
        />
        <canvas ref={canvas} aria-hidden="true" />
        {presence.nodes.map((node) => {
          const marker = (
            <button
              key={node.id}
              ref={(element) => {
                if (element) nodeElements.current.set(node.id, element);
                else nodeElements.current.delete(node.id);
              }}
              type="button"
              className="k-orbit__node"
              data-tone={node.badge?.tone ?? nodeTone(node)}
              style={
                {
                  "--k-orbit-custom-background": node.backgroundColor,
                  "--k-orbit-custom-border": node.borderColor,
                } as CSSProperties
              }
              data-appearance={node.appearance ?? "icon"}
              data-node-tone={node.tone ?? "neutral"}
              data-status={node.status ?? "idle"}
              data-center={!node.levelId || undefined}
              data-departing={presence.departingIds.has(node.id) || undefined}
              data-selected={selected === node.id || undefined}
              disabled={node.disabled || presence.departingIds.has(node.id)}
              aria-hidden={presence.departingIds.has(node.id) || undefined}
              tabIndex={presence.departingIds.has(node.id) ? -1 : undefined}
              aria-pressed={selected === node.id}
              aria-label={[
                node.label,
                node.description,
                node.badge?.label,
                node.progress !== undefined ? `${node.progress}%` : undefined,
                node.statusLabel ??
                  (node.status === "idle" ? undefined : node.status),
              ]
                .filter(Boolean)
                .join(". ")}
              onClick={(event) => activate(node, event)}
            >
              <span className="k-orbit__node-content">
                <span className="k-orbit__node-visual">
                  {node.content ??
                    (node.appearance === "sphere"
                      ? null
                      : node.label.trim().slice(0, 2).toLocaleUpperCase())}
                </span>
              </span>
              {node.badge !== null &&
                (node.badge || (node.status && node.status !== "idle")) && (
                  <span className="k-orbit__status" aria-hidden="true">
                    {node.badge
                      ? node.badge.content
                      : node.status === "question"
                        ? "?"
                        : node.status === "error"
                          ? "!"
                          : node.status === "completed"
                            ? "✓"
                            : "•"}
                  </span>
                )}
              <span className="k-orbit__node-label">{node.label}</span>
            </button>
          );
          return props.nodeActions ? (
            <KContextMenu
              key={node.id}
              label={node.label}
              actions={props.nodeActions(node)}
              onOpenChange={(open) => {
                setContextMenuOpen(open);
                if (!open) setFocused(false);
              }}
              disabled={node.disabled || presence.departingIds.has(node.id)}
            >
              {marker}
            </KContextMenu>
          ) : (
            marker
          );
        })}
      </div>
      {props.showControls && (
        <div className="k-orbit__controls">
          <KButton
            variant="secondary"
            onClick={() => {
              props.onPinnedChange?.(null);
              gestures.resetView();
            }}
          >
            {labels.reset}
          </KButton>
          {props.onPausedChange && (
            <KButton
              variant="secondary"
              onClick={() => props.onPausedChange?.(!paused)}
            >
              {paused ? labels.resume : labels.pause}
            </KButton>
          )}
          {props.onMotionSpeedChange && (
            <KSlider
              label={labels.speed}
              value={speed}
              min={0}
              max={2}
              step={0.25}
              onValueChange={props.onMotionSpeedChange}
              valueLabel={(value) => `${value}×`}
            />
          )}
        </div>
      )}
    </div>
  );
}
function nodeTone(node: KOrbitNode): KOrbitNode["tone"] {
  if (node.status === "question") return "warning";
  if (node.status === "error") return "error";
  if (node.status === "completed") return "success";
  if (node.status === "active") return node.tone ?? "info";
  return node.tone ?? "neutral";
}
function clampView(
  view: KOrbitViewState,
  bounds: readonly [number, number] = [0.65, 2.2],
): KOrbitViewState {
  if (
    !Number.isFinite(bounds[0]) ||
    !Number.isFinite(bounds[1]) ||
    bounds[0] <= 0 ||
    bounds[1] < bounds[0]
  )
    throw new Error(
      "KOrbit zoomBounds must be positive, finite and ordered [min, max]",
    );
  return {
    ...view,
    pitch: Math.max(-Math.PI / 2, Math.min(Math.PI / 2, view.pitch)),
    zoom: Math.max(bounds[0], Math.min(bounds[1], view.zoom)),
  };
}
