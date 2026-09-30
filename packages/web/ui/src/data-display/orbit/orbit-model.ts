import type { ReactNode } from "react";
export type KOrbitTone = "neutral" | "info" | "success" | "warning" | "error";
export type KOrbitLineStyle = "solid" | "dashed" | "dotted";
export type KOrbitSignalStyle = "point" | "trail" | "pings";
export type KOrbitNodeStatus =
  "idle" | "active" | "question" | "error" | "completed";
export interface KOrbitLevel {
  id: string;
  label: string;
  radius: number;
  inclination?: number;
  azimuth?: number;
  periodSeconds?: number;
  direction?: 1 | -1;
}
export interface KOrbitNode {
  id: string;
  label: string;
  description?: string;
  levelId?: string;
  parentId?: string;
  phase?: number;
  /** Overrides the orbit period and direction for this node. */
  periodSeconds?: number;
  direction?: 1 | -1;
  /** CSS colors, including consumer CSS token variables. */
  backgroundColor?: string;
  borderColor?: string;
  /** Undefined derives a badge from status; null hides it. */
  badge?: { content: ReactNode; label?: string; tone?: KOrbitTone } | null;
  /** Pulse opacity multiplier, from 0 to 1. */
  pulseIntensity?: number;
  /** Planet radius in the same world units as its orbit. Independent of hierarchy. */
  radius?: number;
  disabled?: boolean;
  tone?: KOrbitTone;
  status?: KOrbitNodeStatus;
  pulse?: boolean;
  pulsePeriodMs?: number;
  statusLabel?: string;
  /** Optional determinate progress, 0–100. */
  progress?: number;
  /** Custom content is centered inside the planet; avatar fills its circle. */
  /** Flat icon circle by default; sphere explicitly opts into the shaded material. */
  appearance?: "sphere" | "icon" | "avatar";
  content?: ReactNode;
}
export interface KOrbitConnection {
  id: string;
  sourceId: string;
  targetId: string;
  direction?: "forward" | "reverse" | "both";
  label?: string;
  tone?: KOrbitTone;
  lineStyle?: KOrbitLineStyle;
  signalStyle?: KOrbitSignalStyle;
  sourcePing?: boolean;
  arrivalPing?: boolean;
  visible?: boolean;
}
export interface KOrbitViewState {
  yaw: number;
  pitch: number;
  zoom: number;
  offset: { x: number; y: number };
}
export interface KOrbitSignal {
  id: string;
  /** Exactly one target: a communication connection or a local node ping. */
  connectionId?: string;
  nodeId?: string;
  durationMs?: number;
  style?: KOrbitSignalStyle;
  sourcePing?: boolean;
  arrivalPing?: boolean;
}
export type KOrbitSignalResult =
  "accepted" | "capacity" | "invalid" | "inactive";
export type KOrbitSignalEndReason = "completed" | "cancelled";
export interface KOrbitPoint {
  x: number;
  y: number;
  depth: number;
}
export interface KOrbitPoint3 {
  x: number;
  y: number;
  z: number;
}
export interface KOrbitRing {
  parentId?: string;
  level: KOrbitLevel;
  anchor: KOrbitPoint3;
}
export interface KOrbitSceneProjection {
  points: Map<string, KOrbitPoint>;
  radii: Map<string, number>;
  rings: readonly KOrbitRing[];
  center: { x: number; y: number };
  scale: number;
  sceneExtent: number;
  maxLevelRadius: number;
  centerRadius: number;
}
interface ControllerBridge {
  trigger(signal: KOrbitSignal): KOrbitSignalResult;
  cancel(id: string): boolean;
  cancelAll(notify: boolean): void;
}
/** Stable imperative entry point for transient visual communication events. */
export class KOrbitController {
  #bridge?: ControllerBridge;
  triggerSignal(signal: KOrbitSignal): KOrbitSignalResult {
    return this.#bridge?.trigger(signal) ?? "inactive";
  }
  cancelSignal(id: string): boolean {
    return this.#bridge?.cancel(id) ?? false;
  }
  cancelAll(): void {
    this.#bridge?.cancelAll(true);
  }
  dispose(): void {
    this.#bridge?.cancelAll(false);
    this.#bridge = undefined;
  }
  /** @internal Used by KOrbit to connect a mounted scene. */
  bind(bridge: ControllerBridge): () => void {
    this.#bridge?.cancelAll(false);
    this.#bridge = bridge;
    return () => {
      if (this.#bridge === bridge) this.#bridge = undefined;
    };
  }
}
export const kOrbitDefaultView: KOrbitViewState = {
  yaw: 0,
  pitch: 0,
  zoom: 1,
  offset: { x: 0, y: 0 },
};
export function validateKOrbit(
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  connections: readonly KOrbitConnection[],
): void {
  uniqueIds(levels, "level");
  uniqueIds(nodes, "node");
  uniqueIds(connections, "connection");
  const levelIds = new Set(levels.map(({ id }) => id));
  const nodeIds = new Set(nodes.map(({ id }) => id));
  for (const level of levels) {
    finitePositive(level.radius, `level \"${level.id}\" radius`);
    if (level.periodSeconds !== undefined)
      finitePositive(
        level.periodSeconds,
        `level \"${level.id}\" periodSeconds`,
      );
    finiteOptional(level.inclination, `level \"${level.id}\" inclination`);
    finiteOptional(level.azimuth, `level \"${level.id}\" azimuth`);
  }
  for (const node of nodes) {
    if (node.periodSeconds !== undefined)
      finitePositive(node.periodSeconds, `node "${node.id}" periodSeconds`);
    if (
      node.pulseIntensity !== undefined &&
      (!Number.isFinite(node.pulseIntensity) ||
        node.pulseIntensity < 0 ||
        node.pulseIntensity > 1)
    )
      throw new Error("KOrbit pulseIntensity must be between 0 and 1");
    if (
      node.direction !== undefined &&
      node.direction !== 1 &&
      node.direction !== -1
    )
      throw new Error("KOrbit direction must be 1 or -1");
    if (
      node.progress !== undefined &&
      (!Number.isFinite(node.progress) ||
        node.progress < 0 ||
        node.progress > 100)
    )
      throw new Error("KOrbit progress must be between 0 and 100");
    finiteOptional(node.phase, `node \"${node.id}\" phase`);
    if (node.radius !== undefined)
      finitePositive(node.radius, `node \"${node.id}\" radius`);
    if (node.pulsePeriodMs !== undefined)
      finitePositive(node.pulsePeriodMs, `node \"${node.id}\" pulsePeriodMs`);
    if (node.levelId && !levelIds.has(node.levelId))
      throw new Error(
        `KOrbit node \"${node.id}\" references missing level \"${node.levelId}\"`,
      );
    if (node.parentId && !nodeIds.has(node.parentId))
      throw new Error(
        `KOrbit node \"${node.id}\" references missing parent \"${node.parentId}\"`,
      );
    if (node.parentId && !node.levelId)
      throw new Error(
        `KOrbit child node \"${node.id}\" must reference a level`,
      );
    const visited = new Set<string>([node.id]);
    let parent = node.parentId;
    while (parent) {
      if (visited.has(parent))
        throw new Error(`KOrbit parent cycle includes node \"${parent}\"`);
      visited.add(parent);
      parent = nodes.find(({ id }) => id === parent)?.parentId;
    }
  }
  for (const connection of connections) {
    if (!nodeIds.has(connection.sourceId) || !nodeIds.has(connection.targetId))
      throw new Error(
        `KOrbit connection \"${connection.id}\" has a missing endpoint`,
      );
  }
}
function uniqueIds(items: readonly { id: string }[], kind: string): void {
  const ids = new Set<string>();
  for (const item of items) {
    if (!item.id) throw new Error(`KOrbit ${kind} IDs must not be empty`);
    if (ids.has(item.id))
      throw new Error(`KOrbit duplicate ${kind} ID \"${item.id}\"`);
    ids.add(item.id);
  }
}
function finitePositive(value: number, name: string): void {
  if (!Number.isFinite(value) || value <= 0)
    throw new Error(`KOrbit ${name} must be positive and finite`);
}
function finiteOptional(value: number | undefined, name: string): void {
  if (value !== undefined && !Number.isFinite(value))
    throw new Error(`KOrbit ${name} must be finite`);
}
export function kOrbitLevelPeriod(
  level: KOrbitLevel,
  maxLevelRadius: number,
): number {
  return level.periodSeconds ?? 60;
}
export function projectKOrbitPoint(
  level: KOrbitLevel | undefined,
  phase: number,
  elapsedSeconds: number,
  view: KOrbitViewState,
  width: number,
  height: number,
  sceneExtent: number,
  maxLevelRadius = level?.radius ?? 1,
): KOrbitPoint {
  if (!level)
    return {
      x: width / 2 + view.offset.x,
      y: height / 2 + view.offset.y,
      depth: 0,
    };
  const period = kOrbitLevelPeriod(level, maxLevelRadius);
  const angle =
    phase + (elapsedSeconds / period) * Math.PI * 2 * (level.direction ?? 1);
  return projectKOrbitWorldPoint(
    kOrbitLocalPoint(level, angle),
    view,
    width,
    height,
    sceneExtent,
  );
}
export function projectKOrbitScene(
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  view: KOrbitViewState,
  elapsedSeconds: number,
  width: number,
  height: number,
  centerRadiusRatio = 0.296,
  sceneExtentOverride?: number,
  angles?: ReadonlyMap<string, number>,
): KOrbitSceneProjection {
  const levelById = new Map(levels.map((level) => [level.id, level]));
  const nodeById = new Map(nodes.map((node) => [node.id, node]));
  const maxLevelRadius = Math.max(1, ...levels.map(({ radius }) => radius));
  const sceneExtent = sceneExtentOverride ?? kOrbitSceneExtent(levels, nodes);
  const world = new Map<string, KOrbitPoint3>();
  const worldFor = (node: KOrbitNode): KOrbitPoint3 => {
    const known = world.get(node.id);
    if (known) return known;
    const parent = node.parentId ? nodeById.get(node.parentId) : undefined;
    const anchor = parent ? worldFor(parent) : origin();
    const level = node.levelId ? levelById.get(node.levelId) : undefined;
    const phase = node.phase ?? 0;
    const point = level
      ? add(
          anchor,
          kOrbitLocalPoint(
            level,
            phase +
              ((angles ? (angles.get(node.id) ?? 0) : undefined) ??
                (elapsedSeconds /
                  (node.periodSeconds ??
                    kOrbitLevelPeriod(level, maxLevelRadius))) *
                  Math.PI *
                  2 *
                  (node.direction ?? level.direction ?? 1)),
          ),
        )
      : anchor;
    world.set(node.id, point);
    return point;
  };
  const points = new Map<string, KOrbitPoint>();
  for (const node of nodes)
    points.set(
      node.id,
      projectKOrbitWorldPoint(worldFor(node), view, width, height, sceneExtent),
    );
  const rings = new Map<string, KOrbitRing>();
  for (const node of nodes) {
    if (!node.levelId) continue;
    const key = `${node.parentId ?? ""}\u0000${node.levelId}`;
    if (!rings.has(key))
      rings.set(key, {
        parentId: node.parentId,
        level: levelById.get(node.levelId)!,
        anchor: node.parentId
          ? worldFor(nodeById.get(node.parentId)!)
          : origin(),
      });
  }
  const scale = kOrbitScale(width, height, sceneExtent, view.zoom);
  const radii = new Map(
    nodes.map((node) => [
      node.id,
      scale *
        (node.radius ??
          (node.levelId
            ? levelById.get(node.levelId)!.radius * 0.14
            : sceneExtent * centerRadiusRatio)),
    ]),
  );
  return {
    points,
    radii,
    rings: [...rings.values()],
    center: {
      x: width / 2 + view.offset.x,
      y: height / 2 + view.offset.y,
    },
    scale,
    sceneExtent,
    maxLevelRadius,
    centerRadius:
      radii.get(nodes.find((node) => !node.levelId)?.id ?? "") ??
      sceneExtent * scale * centerRadiusRatio,
  };
}
export function kOrbitSceneExtent(
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
): number {
  const radii = new Map(levels.map(({ id, radius }) => [id, radius]));
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const extents = new Map<string, number>();
  const extentFor = (node: KOrbitNode): number => {
    const known = extents.get(node.id);
    if (known !== undefined) return known;
    const extent =
      (node.levelId ? (radii.get(node.levelId) ?? 0) : 0) +
      (node.parentId ? extentFor(byId.get(node.parentId)!) : 0);
    extents.set(node.id, extent);
    return extent;
  };
  return Math.max(
    1,
    ...nodes.map((node) => extentFor(node) + (node.radius ?? 0)),
  );
}
export function kOrbitLocalPoint(
  level: KOrbitLevel,
  angle: number,
): KOrbitPoint3 {
  const radial = Math.sin(angle) * level.radius;
  const inclination = level.inclination ?? 0;
  const azimuth = level.azimuth ?? 0;
  const x = Math.cos(angle) * level.radius;
  const y = radial * Math.cos(inclination);
  const z = radial * Math.sin(inclination);
  const cosine = Math.cos(azimuth);
  const sine = Math.sin(azimuth);
  return { x: x * cosine - y * sine, y: x * sine + y * cosine, z };
}
export function projectKOrbitWorldPoint(
  point: KOrbitPoint3,
  view: KOrbitViewState,
  width: number,
  height: number,
  sceneExtent: number,
): KOrbitPoint {
  const pitched = rotateX(point, view.pitch);
  const rotated = rotateY(pitched, view.yaw);
  const extent = Math.max(sceneExtent, 1);
  const scale = kOrbitScale(width, height, extent, view.zoom);
  return {
    x: width / 2 + view.offset.x + rotated.x * scale,
    y: height / 2 + view.offset.y - rotated.y * scale,
    depth: rotated.z / extent,
  };
}
function kOrbitScale(
  width: number,
  height: number,
  sceneExtent: number,
  zoom: number,
): number {
  return (Math.max(1, Math.min(width, height) - 64) / (2 * sceneExtent)) * zoom;
}
function rotateX(point: KOrbitPoint3, angle: number): KOrbitPoint3 {
  const cosine = Math.cos(angle);
  const sine = Math.sin(angle);
  return {
    x: point.x,
    y: point.y * cosine - point.z * sine,
    z: point.y * sine + point.z * cosine,
  };
}
function rotateY(point: KOrbitPoint3, angle: number): KOrbitPoint3 {
  const cosine = Math.cos(angle);
  const sine = Math.sin(angle);
  return {
    x: point.x * cosine + point.z * sine,
    y: point.y,
    z: -point.x * sine + point.z * cosine,
  };
}
function origin(): KOrbitPoint3 {
  return { x: 0, y: 0, z: 0 };
}
function add(a: KOrbitPoint3, b: KOrbitPoint3): KOrbitPoint3 {
  return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
}
export function kOrbitConnectionPoint(
  source: KOrbitPoint,
  target: KOrbitPoint,
  progress: number,
): KOrbitPoint {
  const dx = target.x - source.x;
  const dy = target.y - source.y;
  const length = Math.hypot(dx, dy) || 1;
  const bend = Math.min(48, length * 0.18);
  const control = {
    x: (source.x + target.x) / 2 - (dy / length) * bend,
    y: (source.y + target.y) / 2 + (dx / length) * bend,
  };
  const inverse = 1 - progress;
  return {
    x:
      inverse * inverse * source.x +
      2 * inverse * progress * control.x +
      progress * progress * target.x,
    y:
      inverse * inverse * source.y +
      2 * inverse * progress * control.y +
      progress * progress * target.y,
    depth: source.depth + (target.depth - source.depth) * progress,
  };
}
export function kOrbitZoomAt(
  view: KOrbitViewState,
  nextZoom: number,
  focal: { x: number; y: number },
  center: { x: number; y: number },
): KOrbitViewState {
  const ratio = nextZoom / view.zoom;
  return {
    ...view,
    zoom: nextZoom,
    offset: {
      x: focal.x - center.x - (focal.x - center.x - view.offset.x) * ratio,
      y: focal.y - center.y - (focal.y - center.y - view.offset.y) * ratio,
    },
  };
}
