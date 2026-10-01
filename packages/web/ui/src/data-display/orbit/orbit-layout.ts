import {
  validateKOrbit,
  type KOrbitLevel,
  type KOrbitNode,
} from "./orbit-model.js";

/** Reserve each child's complete moving subtree, rather than only its node. */
export function layoutKOrbit(
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  gap = 12,
): { levels: KOrbitLevel[]; nodes: KOrbitNode[] } {
  validateKOrbit(levels, nodes, []);
  if (!Number.isFinite(gap) || gap < 0)
    throw new Error("KOrbit layoutGap must be finite and non-negative");
  const byLevel = new Map(levels.map((level) => [level.id, level]));
  const children = new Map<string, KOrbitNode[]>();
  for (const node of nodes) {
    if (!node.parentId) continue;
    const siblings = children.get(node.parentId) ?? [];
    siblings.push(node);
    children.set(node.parentId, siblings);
  }
  const result = new Map<string, KOrbitNode>();
  const resolvedLevels: KOrbitLevel[] = [];
  const reserved = new Map<string, number>();
  const visit = (node: KOrbitNode): number => {
    const known = reserved.get(node.id);
    if (known !== undefined) return known;
    result.set(node.id, node);
    let outer = node.radius ?? 12;
    const groups = new Map<string, KOrbitNode[]>();
    for (const child of children.get(node.id) ?? []) {
      visit(child);
      const level = byLevel.get(child.levelId!)!;
      const key = JSON.stringify([
        level.id,
        child.periodSeconds ?? level.periodSeconds ?? 60,
        child.direction ?? level.direction ?? 1,
      ]);
      const group = groups.get(key) ?? [];
      group.push(child);
      groups.set(key, group);
    }
    const ordered = [...groups.entries()].sort(([a], [b]) =>
      a < b ? -1 : a > b ? 1 : 0,
    );
    for (const [key, siblings] of ordered) {
      const level = byLevel.get(siblings[0]!.levelId!)!;
      const footprint = Math.max(
        ...siblings.map((child) => reserved.get(child.id)!),
      );
      // Different speeds use disjoint annuli; equal-speed siblings share a ring.
      const spacing =
        siblings.length > 1
          ? (2 * footprint + gap) / (2 * Math.sin(Math.PI / siblings.length))
          : 0;
      const radius = Math.max(level.radius, outer + footprint + gap, spacing);
      const id = JSON.stringify(["k-orbit-layout", node.id, key]);
      resolvedLevels.push({
        ...level,
        id,
        radius,
        inclination: 0,
        azimuth: 0,
        periodSeconds: siblings[0]!.periodSeconds ?? level.periodSeconds ?? 60,
        direction: siblings[0]!.direction ?? level.direction ?? 1,
      });
      siblings.forEach((child, index) =>
        result.set(child.id, {
          ...result.get(child.id)!,
          levelId: id,
          phase: (index * Math.PI * 2) / siblings.length,
        }),
      );
      outer = radius + footprint;
    }
    reserved.set(node.id, outer);
    return outer;
  };
  for (const node of nodes) if (!node.parentId) visit(node);
  // Unparented orbit nodes retain their explicitly supplied levels.
  for (const node of nodes)
    if (!node.parentId && node.levelId)
      resolvedLevels.push(byLevel.get(node.levelId)!);
  return {
    levels: [
      ...new Map(resolvedLevels.map((level) => [level.id, level])).values(),
    ],
    nodes: nodes.map((node) => result.get(node.id)!),
  };
}
