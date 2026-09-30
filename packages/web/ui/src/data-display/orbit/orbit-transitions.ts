import type { KOrbitNode, KOrbitViewState } from "./orbit-model.js";
interface ProgressTransition {
  from: number;
  to: number;
  start: number;
  duration: number;
}
export interface KOrbitPresentation {
  pinnedId?: string | null;
  view?: KOrbitViewState;
  returning?: { from: KOrbitViewState; start: number };
  progress: Map<string, ProgressTransition>;
}
function ease(now: number, start: number, duration: number) {
  const t =
    duration <= 0 ? 1 : Math.max(0, Math.min(1, (now - start) / duration));
  return t * t * (3 - 2 * t);
}
const mix = (from: number, to: number, t: number) => from + (to - from) * t;

/** Follow uses projected coordinates, including the whole moving ancestor chain. */
export function resolveKOrbitCamera(
  state: KOrbitPresentation,
  target: KOrbitViewState,
  pinnedId: string | null | undefined,
  followOffset: (view: KOrbitViewState) => { x: number; y: number },
  now: number,
  duration: number,
): KOrbitViewState {
  if (state.pinnedId && !pinnedId && state.view)
    state.returning = { from: state.view, start: now };
  let view = target;
  if (pinnedId) {
    state.returning = undefined;
    view = { ...target, offset: followOffset(target) };
  } else if (state.returning) {
    const { from, start } = state.returning;
    const t = ease(now, start, duration);
    view = {
      yaw: mix(from.yaw, target.yaw, t),
      pitch: mix(from.pitch, target.pitch, t),
      zoom: mix(from.zoom, target.zoom, t),
      offset: {
        x: mix(from.offset.x, target.offset.x, t),
        y: mix(from.offset.y, target.offset.y, t),
      },
    };
    if (t === 1) state.returning = undefined;
  }
  state.pinnedId = pinnedId;
  state.view = view;
  return view;
}

export function animateKOrbitProgress(
  state: Map<string, ProgressTransition>,
  nodes: readonly KOrbitNode[],
  now: number,
  duration: number,
): readonly KOrbitNode[] {
  const ids = new Set(
    nodes.filter((n) => n.progress !== undefined).map((n) => n.id),
  );
  for (const id of state.keys()) if (!ids.has(id)) state.delete(id);
  return nodes.map((node) => {
    if (node.progress === undefined) return node;
    let item = state.get(node.id);
    if (!item || duration === 0)
      item = { from: node.progress, to: node.progress, start: now, duration };
    const current = mix(
      item.from,
      item.to,
      ease(now, item.start, item.duration),
    );
    if (node.progress !== item.to)
      item = { from: current, to: node.progress, start: now, duration };
    state.set(node.id, item);
    return {
      ...node,
      progress:
        duration === 0
          ? node.progress
          : mix(item.from, item.to, ease(now, item.start, item.duration)),
    };
  });
}
