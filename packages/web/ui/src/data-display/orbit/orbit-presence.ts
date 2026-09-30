import { useEffect, useRef, useState, type RefObject } from "react";
import {
  kOrbitSceneExtent,
  type KOrbitLevel,
  type KOrbitNode,
} from "./orbit-model.js";

export interface KOrbitExtentTransition {
  from: number;
  to: number;
  startedAt: number;
  durationMs: number;
}

export interface KOrbitPresenceMotion {
  from: number;
  to: number;
  startedAt: number;
  durationMs: number;
}

/** Reversible back-eased size animation; surviving nodes keep their orbital phase. */
export function kOrbitPresenceScale(
  motion: KOrbitPresenceMotion | undefined,
  now: number,
): number {
  if (!motion) return 1;
  const t =
    motion.durationMs <= 0
      ? 1
      : Math.max(0, Math.min(1, (now - motion.startedAt) / motion.durationMs));
  const back = (x: number) =>
    1 + 2.70158 * (x - 1) ** 3 + 1.70158 * (x - 1) ** 2;
  const eased = motion.to > motion.from ? back(t) : 1 - back(1 - t);
  return Math.max(0, motion.from + (motion.to - motion.from) * eased);
}

interface KOrbitPresence {
  motion: RefObject<Map<string, KOrbitPresenceMotion>>;
  levels: readonly KOrbitLevel[];
  nodes: readonly KOrbitNode[];
  departingIds: ReadonlySet<string>;
  extent: RefObject<KOrbitExtentTransition | undefined>;
}

export function useKOrbitPresence(
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  root: RefObject<HTMLElement | null>,
  reducedMotion: boolean,
): KOrbitPresence {
  const [presentLevels, setPresentLevels] = useState(levels);
  const [presentNodes, setPresentNodes] = useState(nodes);
  const [departingIds, setDepartingIds] = useState<ReadonlySet<string>>(
    new Set(),
  );
  const motion = useRef(new Map<string, KOrbitPresenceMotion>());
  const previousLevels = useRef(levels);
  const previousNodes = useRef(nodes);
  const extent = useRef<KOrbitExtentTransition | undefined>(undefined);
  const levelSignature = JSON.stringify(
    [...levels]
      .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
      .map(({ id, radius, inclination, azimuth, periodSeconds, direction }) => [
        id,
        radius,
        inclination,
        azimuth,
        periodSeconds,
        direction,
      ]),
  );
  const nodeSignature = JSON.stringify(
    [...nodes]
      .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
      .map(({ id, levelId, parentId, phase, radius }) => [
        id,
        levelId,
        parentId,
        phase,
        radius,
      ]),
  );

  useEffect(() => {
    const durationMs = reducedMotion ? 0 : transitionDuration(root.current);
    const nextIds = new Set(nodes.map(({ id }) => id));
    const previousIds = new Set(previousNodes.current.map(({ id }) => id));
    const departing = new Set(
      presentNodes.filter(({ id }) => !nextIds.has(id)).map(({ id }) => id),
    );
    const retainedNodes = [
      ...nodes,
      ...presentNodes.filter(({ id }) => !nextIds.has(id)),
    ];
    const nextLevelIds = new Set(levels.map(({ id }) => id));
    const retainedLevels = [
      ...levels,
      ...presentLevels.filter(({ id }) => !nextLevelIds.has(id)),
    ];
    const now = performance.now();
    for (const node of retainedNodes) {
      const old = motion.current.get(node.id);
      const to = nextIds.has(node.id) ? 1 : 0;
      if (old?.to === to || (!old && previousIds.has(node.id) && to === 1))
        continue;
      motion.current.set(node.id, {
        from: old
          ? kOrbitPresenceScale(old, now)
          : previousIds.has(node.id)
            ? 1
            : 0,
        to,
        startedAt: now,
        durationMs,
      });
    }
    extent.current = {
      from: currentExtent(
        extent.current,
        now,
        kOrbitSceneExtent(previousLevels.current, previousNodes.current),
      ),
      to: Math.max(extent.current?.to ?? 0, kOrbitSceneExtent(levels, nodes)),
      startedAt: now,
      durationMs,
    };
    setPresentLevels(retainedLevels);
    setPresentNodes(retainedNodes);
    setDepartingIds(departing);
    previousLevels.current = levels;
    previousNodes.current = nodes;

    const departureTimer = window.setTimeout(() => {
      setPresentLevels(levels);
      setPresentNodes(nodes);
      setDepartingIds(new Set());
      for (const id of motion.current.keys())
        if (!nextIds.has(id)) motion.current.delete(id);
    }, durationMs);
    return () => {
      clearTimeout(departureTimer);
    };
  }, [levelSignature, nodeSignature, reducedMotion]);

  if (reducedMotion) {
    extent.current = {
      from: kOrbitSceneExtent(levels, nodes),
      to: kOrbitSceneExtent(levels, nodes),
      startedAt: 0,
      durationMs: 0,
    };
    return {
      motion,
      levels,
      nodes,
      departingIds: new Set(),
      extent,
    };
  }
  const liveLevels = new Map(levels.map((level) => [level.id, level]));
  const liveNodes = new Map(nodes.map((node) => [node.id, node]));
  return {
    motion,
    levels: presentLevels.map((level) => liveLevels.get(level.id) ?? level),
    nodes: presentNodes.map((node) => liveNodes.get(node.id) ?? node),
    departingIds,
    extent,
  };
}

function transitionDuration(element: HTMLElement | null): number {
  if (!element) return 0;
  const styles = getComputedStyle(element);
  const raw = cssValue(
    styles,
    "--k-component-orbit-motion-transition-duration",
  );
  const value = Number.parseFloat(raw);
  if (!Number.isFinite(value)) return 0;
  return raw.endsWith("ms") ? value : value * 1000;
}

function cssValue(
  styles: CSSStyleDeclaration,
  name: string,
  seen = new Set<string>(),
): string {
  if (seen.has(name)) return "";
  seen.add(name);
  const raw = styles.getPropertyValue(name).trim();
  const alias = raw.match(/^var\((--[^,)]+)(?:,\s*([^)]+))?\)$/);
  return alias
    ? cssValue(styles, alias[1]!, seen) || alias[2]?.trim() || ""
    : raw;
}

function currentExtent(
  transition: KOrbitExtentTransition | undefined,
  now: number,
  fallback: number,
): number {
  if (!transition) return fallback;
  if (transition.durationMs <= 0) return transition.to;
  const progress = Math.max(
    0,
    Math.min(1, (now - transition.startedAt) / transition.durationMs),
  );
  return transition.from + (transition.to - transition.from) * progress;
}
