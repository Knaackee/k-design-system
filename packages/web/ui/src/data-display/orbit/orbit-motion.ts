import type { KOrbitLevel, KOrbitNode } from "./orbit-model.js";

/** Integrate local angles so live speed/period changes never rewind positions. */
export function advanceKOrbitAngles(
  angles: Map<string, number>,
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  delta: number,
  speed = 1,
  maxAngularSpeed = 12,
): Map<string, number> {
  const byId = new Map(levels.map((level) => [level.id, level]));
  const ids = new Set(nodes.map((node) => node.id));
  for (const id of angles.keys()) if (!ids.has(id)) angles.delete(id);
  for (const node of nodes) {
    const level = node.levelId ? byId.get(node.levelId) : undefined;
    if (!level) continue;
    const degrees = Math.min(
      maxAngularSpeed,
      (360 * speed) / (node.periodSeconds ?? level.periodSeconds ?? 60),
    );
    angles.set(
      node.id,
      ((angles.get(node.id) ?? 0) +
        ((delta * degrees * Math.PI) / 180) *
          (node.direction ?? level.direction ?? 1)) %
        (Math.PI * 2),
    );
  }
  return angles;
}
