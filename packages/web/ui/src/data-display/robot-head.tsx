import {
  forwardRef,
  useEffect,
  useId,
  useImperativeHandle,
  useRef,
  type CSSProperties,
  type HTMLAttributes,
} from "react";
import { getShape } from "./robot-head-engine/tv/geometry.js";
import { RobotSim, restPose } from "./robot-head-engine/tv/sim.js";
import {
  RobotRenderer,
  frameFor,
  type Palette,
} from "./robot-head-engine/tv/render.js";
import { linear } from "./robot-head-engine/tv/light.js";
import { subscribe, pointer } from "./robot-head-engine/ticker.js";
import {
  robotAudioUnit,
  type KRobotHeadAudioSource,
} from "./robot-head-audio.js";
import type {
  RobotHeadShape,
  RobotHeadState,
} from "./robot-head-engine/types.js";

export type KRobotHeadShape = RobotHeadShape;
export type KRobotHeadState = RobotHeadState;
export const kRobotHeadShapes = [
  "rectangle",
  "square",
  "circle",
  "hexagon",
] as const;
export const kRobotHeadStates = [
  "idle",
  "thinking",
  "searching",
  "listening",
  "speaking",
  "working",
  "happy",
  "error",
  "sleeping",
] as const;

export interface KRobotHeadHandle {
  /** Same reaction as activation. Returns false while paused/reduced-motion. */
  react(): boolean;
  /** Reset time, pose and random sequence using the current seed. */
  reset(): void;
}
export interface KRobotHeadProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "color" | "children"
> {
  shape?: KRobotHeadShape;
  state?: KRobotHeadState;
  /** Resting layout square; glow/hops deliberately overflow it. Default 160. */
  size?: number;
  /** CSS colors/variables, or --k-robot-head-color / -trim-color / -screen-color. */
  color?: string;
  trimColor?: string;
  screenColor?: string;
  speed?: number;
  /** Freeze the current frame; resumes without catching up elapsed time. */
  paused?: boolean;
  reducedMotion?: boolean;
  interactive?: boolean;
  antenna?: boolean;
  floorShadow?: boolean;
  /** 0–1. Changing the seed resets the animation. */
  seed?: number;
  /** undefined: document pointer; null: no tracking; object: consumer target. */
  target?: { x: number; y: number } | null;
  /** target coordinates are normalized -1…1 relative to the resting head. */
  audio?: KRobotHeadAudioSource;
  /** Fired once per mouse/touch/keyboard activation, even with reactions off. */
  onActivate?: () => void;
  onReactionStart?: () => void;
  onReactionEnd?: () => void;
}

function hashSeed(id: string) {
  let h = 2166136261;
  for (let i = 0; i < id.length; i++)
    h = Math.imul(h ^ id.charCodeAt(i), 16777619);
  return ((h >>> 0) % 1000) / 1000;
}

/** Original Canvas artwork with consumer-controlled interaction and audio. */
export const KRobotHead = forwardRef<KRobotHeadHandle, KRobotHeadProps>(
  function KRobotHead(
    {
      shape = "rectangle",
      state = "idle",
      size = 160,
      color,
      trimColor,
      screenColor,
      speed = 1,
      paused = false,
      reducedMotion = false,
      interactive = true,
      antenna = true,
      floorShadow = true,
      seed,
      target,
      audio,
      onActivate,
      onReactionStart,
      onReactionEnd,
      onClick,
      onKeyDown,
      onKeyUp,
      className,
      style,
      "aria-label": label = "Robot",
      ...rest
    },
    ref,
  ) {
    const box = useRef<HTMLSpanElement>(null);
    const canvas = useRef<HTMLCanvasElement>(null);
    const swatches = useRef<HTMLSpanElement>(null);
    const id = useId();
    const sizeValue = Number.isFinite(size)
      ? Math.max(16, Math.min(1024, size))
      : 160;
    const seedValue = seed === undefined ? hashSeed(id) : robotAudioUnit(seed);
    const frame = frameFor(getShape(shape), antenna, sizeValue);
    const latest = useRef({
      state,
      speed,
      paused,
      reducedMotion,
      interactive,
      target,
      audio,
      onReactionStart,
      onReactionEnd,
    });
    latest.current = {
      state,
      speed,
      paused,
      reducedMotion,
      interactive,
      target,
      audio,
      onReactionStart,
      onReactionEnd,
    };
    const control = useRef<KRobotHeadHandle>({
      react: () => false,
      reset() {},
    });
    const invalidate = useRef<() => void>(() => {});
    useImperativeHandle(
      ref,
      () => ({
        react: () => control.current.react(),
        reset: () => control.current.reset(),
      }),
      [],
    );

    useEffect(() => {
      const el = box.current,
        c = canvas.current,
        colors = swatches.current;
      if (!el || !c || !colors) return;
      const ctx = c.getContext("2d");
      if (!ctx) return;
      const renderer = new RobotRenderer();
      let sim = new RobotSim(seedValue, latest.current.state);
      const preference = matchMedia("(prefers-reduced-motion: reduce)");
      let visible = true;
      let unsubscribe: (() => void) | undefined;
      let reactionEnd = -1;
      let level = 0;
      const bands: number[] = [];
      const colorCanvas = document.createElement("canvas");
      colorCanvas.width = colorCanvas.height = 1;
      const colorContext = colorCanvas.getContext("2d")!;
      let palette: Palette;
      const resolveColors = () => {
        const rgb = Array.from(colors.children).map((span) => {
          colorContext.clearRect(0, 0, 1, 1);
          colorContext.fillStyle = getComputedStyle(span).color;
          colorContext.fillRect(0, 0, 1, 1);
          return Array.from(colorContext.getImageData(0, 0, 1, 1).data).slice(
            0,
            3,
          ) as [number, number, number];
        });
        palette = {
          shell: {
            albedo: linear(rgb[0]),
            f0: 0.05,
            metal: 0.15,
            spec: 0.55,
            shininess: 70,
            rim: 0.9,
          },
          trim: {
            albedo: linear(rgb[1]),
            f0: 0.2,
            metal: 0.65,
            spec: 0.8,
            shininess: 45,
            rim: 0.7,
          },
          led: rgb[2],
        };
      };
      const reduced = () => latest.current.reducedMotion || preference.matches;
      const running = () =>
        !latest.current.paused && latest.current.speed > 0 && !reduced();
      const draw = () => {
        const dpr = Math.min(2, window.devicePixelRatio || 1);
        const w = Math.round((frame.box + frame.padSide * 2) * dpr);
        const h = Math.round(
          (frame.box + frame.padTop + frame.padBottom) * dpr,
        );
        if (c.width !== w || c.height !== h) {
          c.width = w;
          c.height = h;
        }
        const still = reduced() || sim.age === 0;
        renderer.draw(
          ctx,
          frame,
          dpr,
          still ? restPose(latest.current.state) : sim.pose,
          still ? null : sim,
          latest.current.state,
          getShape(shape),
          palette,
          { antenna, floorShadow },
        );
      };
      const tick = (dt: number) => {
        const p = latest.current;
        sim.setState(p.state);
        if (p.target !== undefined) {
          sim.pointer =
            p.target &&
            Number.isFinite(p.target.x) &&
            Number.isFinite(p.target.y)
              ? {
                  x: Math.max(-1, Math.min(1, p.target.x)) * 260,
                  y: Math.max(-1, Math.min(1, p.target.y)) * 260,
                }
              : null;
        } else if (p.interactive && Number.isFinite(pointer.x)) {
          const bounds = el.getBoundingClientRect();
          const x = pointer.x - bounds.left - bounds.width / 2;
          const y = pointer.y - bounds.top - frame.cy + frame.padTop;
          sim.pointer = Math.hypot(x, y) < 700 ? { x, y } : null;
        } else sim.pointer = null;
        if (p.audio !== undefined) {
          const sample = typeof p.audio === "function" ? p.audio() : p.audio;
          const next = robotAudioUnit(sample?.level ?? 0);
          level +=
            (next - level) *
            (1 - Math.exp(-dt / (next > level ? 0.035 : 0.09)));
          sim.face.audioLevel = level;
          bands.length = Math.min(32, sample?.bands?.length ?? 0);
          for (let i = 0; i < bands.length; i++)
            bands[i] = robotAudioUnit(sample!.bands![i]);
          sim.face.audioBands = bands;
        } else {
          sim.face.audioLevel = undefined;
          sim.face.audioBands = undefined;
        }
        sim.update(dt * (Number.isFinite(p.speed) ? Math.min(4, p.speed) : 1));
        if (reactionEnd >= 0 && sim.time >= reactionEnd) {
          reactionEnd = -1;
          p.onReactionEnd?.();
        }
        draw();
      };
      const sync = () => {
        unsubscribe?.();
        unsubscribe = undefined;
        resolveColors();
        draw();
        if (visible && running()) unsubscribe = subscribe(tick);
      };
      control.current = {
        react() {
          if (!running()) return false;
          sim.poke();
          const first = reactionEnd < 0;
          reactionEnd = sim.time + 1.6;
          if (first) latest.current.onReactionStart?.();
          return true;
        },
        reset() {
          sim = new RobotSim(seedValue, latest.current.state);
          reactionEnd = -1;
          level = 0;
          sync();
        },
      };
      invalidate.current = sync;
      const observer = new IntersectionObserver(([entry]) => {
        visible = entry.isIntersecting;
        sync();
      });
      observer.observe(el);
      const theme = new MutationObserver(sync);
      // Resolve tokens when the consumer's theme scope changes, including ancestors.
      for (
        let parent: Element | null = el;
        parent;
        parent = parent.parentElement
      )
        theme.observe(parent, {
          attributes: true,
          attributeFilter: ["style", "class", "data-theme", "data-brand"],
        });
      preference.addEventListener("change", sync);
      sync();
      return () => {
        unsubscribe?.();
        observer.disconnect();
        theme.disconnect();
        preference.removeEventListener("change", sync);
        control.current = { react: () => false, reset() {} };
        invalidate.current = () => {};
      };
    }, [shape, sizeValue, seedValue, antenna, floorShadow]);

    useEffect(() => {
      invalidate.current();
    }, [paused, reducedMotion, speed, state, color, trimColor, screenColor]);
    const actionable = interactive || !!onActivate || !!onClick;
    return (
      <span
        {...rest}
        ref={box}
        className={["k-robot-head", className].filter(Boolean).join(" ")}
        role={actionable ? "button" : "img"}
        tabIndex={actionable ? 0 : undefined}
        aria-label={label}
        data-state={state}
        style={
          {
            ...style,
            position: "relative",
            display: "inline-block",
            flex: "none",
            width: sizeValue,
            height: sizeValue,
            cursor: actionable ? "pointer" : undefined,
          } as CSSProperties
        }
        onClick={(event) => {
          onClick?.(event);
          if (event.defaultPrevented) return;
          if (interactive) control.current.react();
          onActivate?.();
        }}
        onKeyDown={(event) => {
          onKeyDown?.(event);
          if (
            !event.defaultPrevented &&
            actionable &&
            (event.key === "Enter" || event.key === " ")
          ) {
            event.preventDefault();
            if (event.key === "Enter" && !event.repeat)
              event.currentTarget.click();
          }
        }}
        onKeyUp={(event) => {
          onKeyUp?.(event);
          if (!event.defaultPrevented && actionable && event.key === " ") {
            event.preventDefault();
            event.currentTarget.click();
          }
        }}
      >
        <span ref={swatches} aria-hidden="true" style={{ display: "none" }}>
          <span
            style={{ color: color ?? "var(--k-robot-head-color, #2b49a3)" }}
          />
          <span
            style={{
              color: trimColor ?? "var(--k-robot-head-trim-color, #93a6c8)",
            }}
          />
          <span
            style={{
              color: screenColor ?? "var(--k-robot-head-screen-color, #e8f2ff)",
            }}
          />
        </span>
        <canvas
          ref={canvas}
          aria-hidden="true"
          style={{
            position: "absolute",
            pointerEvents: "none",
            left: -frame.padSide,
            top: -frame.padTop,
            width: frame.box + 2 * frame.padSide,
            height: frame.box + frame.padTop + frame.padBottom,
          }}
        />
      </span>
    );
  },
);
