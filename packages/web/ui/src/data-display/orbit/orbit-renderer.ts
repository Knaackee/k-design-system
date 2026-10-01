import { useEffect, useRef, type RefObject } from "react";
import type { KOrbitFrameSignal } from "./orbit-draw.js";
import { drawFrame } from "./orbit-frame.js";
import type { KOrbitPresentation } from "./orbit-transitions.js";
import { cssNumber } from "./orbit-palette.js";
import type {
  KOrbitController,
  KOrbitConnection,
  KOrbitLevel,
  KOrbitNode,
  KOrbitPoint,
  KOrbitSignal,
  KOrbitSignalEndReason,
  KOrbitSignalStyle,
  KOrbitViewState,
} from "./orbit-model.js";
import { advanceKOrbitAngles } from "./orbit-motion.js";
import {
  type KOrbitPresenceMotion,
  type KOrbitExtentTransition,
} from "./orbit-presence.js";

interface ActiveSignal {
  signal: KOrbitSignal;
  elapsed: number;
  duration: number;
}

export interface RendererOptions {
  root: RefObject<HTMLDivElement | null>;
  canvas: RefObject<HTMLCanvasElement | null>;
  shaderCanvas: RefObject<HTMLCanvasElement | null>;
  nodeElements: RefObject<Map<string, HTMLButtonElement>>;
  projectedPoints: RefObject<Map<string, KOrbitPoint>>;
  levels: readonly KOrbitLevel[];
  nodes: readonly KOrbitNode[];
  connections: readonly KOrbitConnection[];
  controller?: KOrbitController;
  view: RefObject<KOrbitViewState>;
  changeView(view: KOrbitViewState): void;
  interacting: RefObject<boolean>;
  inertia: RefObject<{ x: number; y: number }>;
  focused: boolean;
  paused: boolean;
  speed: number;
  maxAngularSpeed?: number;
  synchronizeLevels?: boolean;
  reducedMotion: boolean;
  elapsedSeconds?: number;
  extent: RefObject<KOrbitExtentTransition | undefined>;
  presenceMotion: RefObject<Map<string, KOrbitPresenceMotion>>;
  labelVisibility: "interaction" | "always" | "hidden";
  departingIds: ReadonlySet<string>;
  selectedId?: string | null;
  pinnedId?: string | null;
  lineStyle?: KOrbitConnection["lineStyle"];
  signalStyle?: KOrbitSignalStyle;
  maxActiveSignals?: number;
  onSignalEnd?(id: string, reason: KOrbitSignalEndReason): void;
}

export function useKOrbitRenderer(options: RendererOptions): void {
  const latest = useRef(options);
  latest.current = options;
  const active = useRef(new Map<string, ActiveSignal>());
  const elapsed = useRef(0);
  const angles = useRef(new Map<string, number>());
  const presentation = useRef<KOrbitPresentation>({ progress: new Map() });
  const visible = useRef(true);

  const finishSignal = (
    id: string,
    reason: KOrbitSignalEndReason,
    notify = true,
  ) => {
    if (!active.current.delete(id)) return false;
    if (notify) latest.current.onSignalEnd?.(id, reason);
    return true;
  };
  const cancelAll = (notify: boolean) => {
    const ids = [...active.current.keys()];
    active.current.clear();
    if (notify)
      ids.forEach((id) => latest.current.onSignalEnd?.(id, "cancelled"));
  };

  useEffect(() => {
    for (const [id, item] of active.current) {
      const connection = options.connections.find(
        ({ id: connectionId }) => connectionId === item.signal.connectionId,
      );
      if (
        item.signal.nodeId
          ? !options.nodes.some((node) => node.id === item.signal.nodeId) ||
            options.departingIds.has(item.signal.nodeId)
          : !connection ||
            !options.nodes.some(
              ({ id: nodeId }) => nodeId === connection.sourceId,
            ) ||
            !options.nodes.some(
              ({ id: nodeId }) => nodeId === connection.targetId,
            )
      )
        finishSignal(id, "cancelled");
    }
  }, [options.connections, options.nodes, options.departingIds]);

  useEffect(() => {
    if (!options.controller) return;
    return options.controller.bind({
      trigger(signal) {
        const current = latest.current;
        if (!visible.current) return "inactive";
        const connection = current.connections.find(
          ({ id }) => id === signal.connectionId,
        );
        const defaultDuration = current.root.current
          ? cssNumber(
              getComputedStyle(current.root.current),
              "--k-component-orbit-motion-travel-duration",
              1200,
            )
          : 1200;
        if (
          !signal.id ||
          Boolean(signal.nodeId) === Boolean(signal.connectionId) ||
          (signal.nodeId
            ? !current.nodes.some((node) => node.id === signal.nodeId) ||
              current.departingIds.has(signal.nodeId)
            : !connection ||
              current.departingIds.has(connection.sourceId) ||
              current.departingIds.has(connection.targetId)) ||
          !Number.isFinite(signal.durationMs ?? defaultDuration) ||
          (signal.durationMs ?? defaultDuration) <= 0
        )
          return "invalid";
        if (active.current.has(signal.id)) return "invalid";
        if (active.current.size >= (current.maxActiveSignals ?? 32))
          return "capacity";
        active.current.set(signal.id, {
          signal,
          elapsed: 0,
          duration: signal.durationMs ?? defaultDuration,
        });
        return "accepted";
      },
      cancel: (id) => finishSignal(id, "cancelled"),
      cancelAll,
    });
  }, [options.controller]);

  useEffect(() => {
    const element = options.root.current!;
    const observer = new IntersectionObserver(([entry]) => {
      visible.current = entry?.isIntersecting ?? false;
      if (!visible.current) cancelAll(true);
    });
    observer.observe(element);
    const visibility = () => {
      visible.current = document.visibilityState === "visible";
      if (!visible.current) cancelAll(true);
    };
    document.addEventListener("visibilitychange", visibility);
    return () => {
      observer.disconnect();
      document.removeEventListener("visibilitychange", visibility);
      cancelAll(false);
    };
  }, []);

  useEffect(() => {
    const element = options.root.current!;
    const target = options.canvas.current!;
    const shaderTarget = options.shaderCanvas.current!;
    let frame = 0;
    let last = performance.now();
    let size = { width: 1, height: 1 };
    let ratio = 1;
    const measure = () => {
      const rect = element.getBoundingClientRect();
      size = { width: rect.width, height: rect.height };
      ratio = Math.min(window.devicePixelRatio || 1, 2);
      target.width = Math.max(1, Math.round(rect.width * ratio));
      target.height = Math.max(1, Math.round(rect.height * ratio));
      shaderTarget.width = target.width;
      shaderTarget.height = target.height;
      target.style.width = `${rect.width}px`;
      target.style.height = `${rect.height}px`;
      shaderTarget.style.width = `${rect.width}px`;
      shaderTarget.style.height = `${rect.height}px`;
      target.getContext("2d")?.setTransform(ratio, 0, 0, ratio, 0, 0);
    };
    const observer = new ResizeObserver(measure);
    observer.observe(element);
    measure();
    const render = (now: number) => {
      const current = latest.current;
      const delta = Math.min(0.05, (now - last) / 1000);
      last = now;
      const play =
        visible.current &&
        !current.paused &&
        current.speed > 0 &&
        !current.interacting.current &&
        (!current.focused || Boolean(current.pinnedId));
      if (
        play &&
        !current.reducedMotion &&
        current.elapsedSeconds === undefined
      ) {
        elapsed.current += delta;
        advanceKOrbitAngles(
          angles.current,
          current.levels,
          current.nodes,
          delta,
          current.speed,
          current.maxAngularSpeed,
          current.synchronizeLevels,
        );
      }
      if (
        play &&
        !current.reducedMotion &&
        (Math.abs(current.inertia.current.x) > 0.0001 ||
          Math.abs(current.inertia.current.y) > 0.0001)
      ) {
        current.changeView({
          ...current.view.current,
          yaw: current.view.current.yaw + current.inertia.current.x * delta,
          pitch: current.view.current.pitch + current.inertia.current.y * delta,
        });
        current.inertia.current.x *= Math.pow(0.05, delta);
        current.inertia.current.y *= Math.pow(0.05, delta);
      }
      const frameSignals: KOrbitFrameSignal[] = [];
      for (const [id, item] of active.current) {
        if (visible.current) item.elapsed += delta * 1000;
        const progress = Math.min(1, item.elapsed / item.duration);
        const connection = current.connections.find(
          ({ id: connectionId }) => connectionId === item.signal.connectionId,
        );
        frameSignals.push({
          connectionId: item.signal.connectionId,
          nodeId: item.signal.nodeId,
          progress: current.reducedMotion
            ? item.signal.nodeId
              ? 0.35
              : 0.88
            : progress,
          style: current.reducedMotion
            ? "pings"
            : (item.signal.style ??
              connection?.signalStyle ??
              current.signalStyle ??
              "point"),
          sourcePing:
            !current.reducedMotion &&
            (item.signal.sourcePing ?? connection?.sourcePing ?? true),
          arrivalPing:
            item.signal.arrivalPing ?? connection?.arrivalPing ?? true,
        });
        if (progress >= 1) finishSignal(id, "completed");
      }
      const context = target.getContext("2d");
      if (context)
        drawFrame(
          context,
          shaderTarget,
          current,
          size,
          ratio,
          presentation.current,
          current.elapsedSeconds ?? elapsed.current,
          frameSignals,
          current.elapsedSeconds === undefined
            ? angles.current
            : advanceKOrbitAngles(
                new Map(),
                current.levels,
                current.nodes,
                current.elapsedSeconds,
                current.speed,
                current.maxAngularSpeed,
                current.synchronizeLevels,
              ),
        );
      frame = requestAnimationFrame(render);
    };
    frame = requestAnimationFrame(render);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  }, []);
}
