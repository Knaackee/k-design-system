import type {
  KOrbitNode,
  KOrbitPoint,
  KOrbitSceneProjection,
} from "./orbit-model.js";

export type KOrbitLabelSide =
  "right" | "left" | "below" | "above" | "center" | "hidden";

export interface KOrbitLabelPlacement {
  side: KOrbitLabelSide;
  width: number;
}

interface LayoutOptions {
  nodes: readonly KOrbitNode[];
  points: ReadonlyMap<string, KOrbitPoint>;
  selectedId?: string | null;
  visibleIds?: ReadonlySet<string>;
  width: number;
  height: number;
  center: { x: number; y: number };
  centerRadius: number;
  nodeRadius: number;
  nodeRadii?: ReadonlyMap<string, number>;
  labelOffset: number;
  fontSize: number;
  paddingInline?: number;
  lineHeight: number;
}

interface Rect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

export interface KOrbitHitCandidate {
  id: string;
  x: number;
  y: number;
  radius: number;
  label?: Rect;
}

export function resolveKOrbitPointerNode(
  pointer: { x: number; y: number },
  candidates: readonly KOrbitHitCandidate[],
): string | undefined {
  const labels = candidates.filter(
    ({ label }) =>
      label &&
      pointer.x >= label.left &&
      pointer.x <= label.right &&
      pointer.y >= label.top &&
      pointer.y <= label.bottom,
  );
  if (labels.length) return nearest(pointer, labels).id;
  const markers = candidates.filter(
    ({ x, y, radius }) => Math.hypot(pointer.x - x, pointer.y - y) <= radius,
  );
  return markers.length ? nearest(pointer, markers).id : undefined;
}

export function layoutKOrbitLabels(
  options: LayoutOptions,
): Map<string, KOrbitLabelPlacement> {
  const result = new Map<string, KOrbitLabelPlacement>();
  const occupied: Rect[] = [];
  const ordered = options.nodes
    .filter((node) => !options.visibleIds || options.visibleIds.has(node.id))
    .sort(
      (a, b) =>
        priority(a, options.selectedId) - priority(b, options.selectedId) ||
        (a.id < b.id ? -1 : a.id > b.id ? 1 : 0),
    );
  const sphere = {
    left: options.center.x - options.centerRadius,
    top: options.center.y - options.centerRadius,
    right: options.center.x + options.centerRadius,
    bottom: options.center.y + options.centerRadius,
  };
  for (const node of ordered) {
    const point = options.points.get(node.id);
    if (!point) continue;
    const labelWidth = Math.min(
      132,
      Math.max(
        options.fontSize * node.label.length * 0.6 +
          2 * (options.paddingInline ?? 0),
        options.fontSize * 2,
      ),
    );
    const labelHeight = options.lineHeight;
    const labelOffset = options.nodeRadii
      ? (options.nodeRadii.get(node.id) ?? options.nodeRadius) +
        options.labelOffset / 3
      : options.labelOffset;
    if (!node.levelId) {
      occupied.push({
        left: point.x - labelWidth / 2,
        top: point.y + options.centerRadius + 6,
        right: point.x + labelWidth / 2,
        bottom: point.y + options.centerRadius + 6 + labelHeight,
      });
      result.set(node.id, { side: "center", width: labelWidth });
      continue;
    }
    const candidates: readonly [KOrbitLabelSide, Rect][] = [
      [
        "right",
        rect(
          point.x + labelOffset,
          point.y - labelHeight / 2,
          labelWidth,
          labelHeight,
        ),
      ],
      [
        "left",
        rect(
          point.x - labelOffset - labelWidth,
          point.y - labelHeight / 2,
          labelWidth,
          labelHeight,
        ),
      ],
      [
        "below",
        rect(
          point.x - labelWidth / 2,
          point.y + labelOffset,
          labelWidth,
          labelHeight,
        ),
      ],
      [
        "above",
        rect(
          point.x - labelWidth / 2,
          point.y - labelOffset - labelHeight,
          labelWidth,
          labelHeight,
        ),
      ],
    ];
    const placement = candidates.find(([, candidate]) =>
      available(candidate, node.id, sphere, occupied, options),
    );
    if (placement) occupied.push(placement[1]);
    result.set(node.id, {
      side: placement?.[0] ?? "hidden",
      width: labelWidth,
    });
  }
  return result;
}

function priority(node: KOrbitNode, selectedId?: string | null): number {
  if (!node.levelId) return 0;
  if (node.id === selectedId) return 1;
  if (node.status === "question") return 2;
  if (node.status === "active") return 3;
  return 4;
}

function available(
  candidate: Rect,
  nodeId: string,
  sphere: Rect,
  occupied: readonly Rect[],
  options: LayoutOptions,
): boolean {
  if (
    candidate.left < 4 ||
    candidate.top < 4 ||
    candidate.right > options.width - 4 ||
    candidate.bottom > options.height - 4 ||
    intersects(candidate, sphere) ||
    occupied.some((other) => intersects(candidate, other))
  )
    return false;
  return !options.nodes.some((node) => {
    if (node.id === nodeId || !node.levelId) return false;
    const point = options.points.get(node.id);
    return point
      ? intersectsCircle(
          candidate,
          point,
          options.nodeRadii?.get(node.id) ?? options.nodeRadius,
        )
      : false;
  });
}

/** Hide a node's label and hit target only when its whole planet is obscured. */
export function isKOrbitNodeOccluded(
  id: string,
  scene: KOrbitSceneProjection,
): boolean {
  const point = scene.points.get(id);
  if (!point) return true;
  const radius = scene.radii.get(id) ?? 0;
  return [...scene.points].some(
    ([otherId, other]) =>
      otherId !== id &&
      other.depth > point.depth &&
      Math.hypot(point.x - other.x, point.y - other.y) + radius <
        (scene.radii.get(otherId) ?? 0),
  );
}

function rect(left: number, top: number, width: number, height: number): Rect {
  return { left, top, right: left + width, bottom: top + height };
}

function intersects(a: Rect, b: Rect): boolean {
  return !(
    a.right <= b.left ||
    a.left >= b.right ||
    a.bottom <= b.top ||
    a.top >= b.bottom
  );
}

function intersectsCircle(
  rectangle: Rect,
  point: KOrbitPoint,
  radius: number,
): boolean {
  const x = Math.max(rectangle.left, Math.min(point.x, rectangle.right));
  const y = Math.max(rectangle.top, Math.min(point.y, rectangle.bottom));
  return Math.hypot(point.x - x, point.y - y) < radius;
}

function nearest(
  pointer: { x: number; y: number },
  candidates: readonly KOrbitHitCandidate[],
): KOrbitHitCandidate {
  return [...candidates].sort((a, b) => {
    const distance =
      (pointer.x - a.x) ** 2 +
      (pointer.y - a.y) ** 2 -
      ((pointer.x - b.x) ** 2 + (pointer.y - b.y) ** 2);
    return distance || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  })[0]!;
}
