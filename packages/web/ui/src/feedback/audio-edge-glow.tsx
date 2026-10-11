import { useEffect, useRef } from "react";

export type KAudioEdgeGlowState = "inactive" | "capturing" | "processing";
export interface KAudioEdgeGlowProps {
  /** Consumer character color; CSS variables and color values are supported. */
  color: string;
  state?: KAudioEdgeGlowState;
  /** Normalized microphone energy. Processing retains a quiet perimeter. */
  audioLevel?: number;
  voiceDetected?: boolean;
  /** The OS reduced-motion preference is always respected as well. */
  reducedMotion?: boolean;
}

/** Decorative screen-edge shimmer. Fill a bounded, position-relative parent. */
export function KAudioEdgeGlow({
  color,
  state = "inactive",
  audioLevel = 0,
  voiceDetected = false,
  reducedMotion = false,
}: KAudioEdgeGlowProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const repaint = useRef<(() => void) | null>(null);
  const input = useRef({ state, audioLevel, voiceDetected });
  input.current = { state, audioLevel, voiceDetected };
  const active = state !== "inactive";

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !active) return;
    const context = canvas.getContext("2d");
    if (!context) return;
    const preference = window.matchMedia("(prefers-reduced-motion: reduce)");
    let frame = 0;
    let previous = 0;
    let phase = 0;
    let energy = 0;
    let width = 0;
    let height = 0;
    const sample = document.createElement("canvas");
    sample.width = sample.height = 1;
    const sampleContext = sample.getContext("2d");
    if (!sampleContext) return;
    let resolvedColor = "";
    let palette: number[][] = [];
    function resolvePalette() {
      if (!canvas || !sampleContext) return;
      const next = getComputedStyle(canvas).color;
      if (next === resolvedColor) return;
      resolvedColor = next;
      sampleContext.clearRect(0, 0, 1, 1);
      sampleContext.fillStyle = next;
      sampleContext.fillRect(0, 0, 1, 1);
      const rgba = sampleContext.getImageData(0, 0, 1, 1).data;
      palette = [0.22, 0, -0.14].map((mix) =>
        Array.from(rgba).map((value, index) =>
          index === 3
            ? value / 255
            : Math.round(
                mix >= 0 ? value + (255 - value) * mix : value * (1 + mix),
              ),
        ),
      );
    }
    resolvePalette();
    function paint(now: number) {
      if (!context || !canvas) return;
      const still = reducedMotion || preference.matches;
      const dt = previous ? Math.min(now - previous, 100) : 16;
      previous = now;
      const value = input.current;
      const level = Number.isFinite(value.audioLevel) ? value.audioLevel : 0;
      const target =
        value.state === "capturing"
          ? Math.max(
              Math.sqrt(Math.max(0, Math.min(1, (level - 0.008) / 0.42))),
              value.voiceDetected ? 0.08 : 0,
            )
          : 0;
      energy = still
        ? target
        : energy +
          (target - energy) *
            (1 - Math.exp(-dt / (target > energy ? 70 : 260)));
      if (!still) phase += (dt / 13000) * Math.PI * 2;
      else phase = 0;
      context.clearRect(0, 0, width, height);
      const radius = Math.min(28, Math.min(width, height) * 0.07);
      function layer(
        stroke: number,
        blur: number,
        opacity: number,
        rotation: number,
        lobes = false,
        offset = 0,
        reverse = false,
      ) {
        if (!context || width <= stroke || height <= stroke) return;
        const colors = reverse ? [...palette].reverse() : palette;
        const values: number[][] = [];
        for (let i = 0; i < colors.length; i++) {
          const c = colors[(i + offset) % colors.length]!;
          if (lobes)
            values.push([c[0]!, c[1]!, c[2]!, 0], c, [c[0]!, c[1]!, c[2]!, 0]);
          else values.push(c);
        }
        const gradient = context.createConicGradient(
          rotation,
          width / 2,
          height / 2,
        );
        values.forEach((c, i) =>
          gradient.addColorStop(
            i / (values.length - 1),
            `rgba(${c[0]},${c[1]},${c[2]},${c[3]! * opacity})`,
          ),
        );
        context.save();
        context.filter = `blur(${blur}px)`;
        context.strokeStyle = gradient;
        context.lineWidth = stroke;
        context.beginPath();
        context.roundRect(
          stroke / 2,
          stroke / 2,
          width - stroke,
          height - stroke,
          radius,
        );
        context.stroke();
        context.restore();
      }
      layer(
        10 + energy * 10,
        13 + energy * 10,
        0.24 + energy * 0.16,
        phase * 0.07,
      );
      layer(
        20 + energy * 34,
        24 + energy * 28,
        0.4 + energy * 0.38,
        phase * 0.16,
        true,
      );
      layer(
        14 + energy * 25,
        18 + energy * 22,
        0.34 + energy * 0.34,
        -phase * 0.11 + 1.7,
        true,
        1,
        true,
      );
      layer(
        9 + energy * 17,
        11 + energy * 15,
        0.42 + energy * 0.32,
        phase * 0.23 + 3.1,
        true,
        2,
      );
      if (!still && !document.hidden) frame = requestAnimationFrame(paint);
    }
    function restart() {
      cancelAnimationFrame(frame);
      previous = 0;
      if (!document.hidden) paint(performance.now());
    }
    const observer = new ResizeObserver(() => {
      const bounds = canvas.getBoundingClientRect();
      width = bounds.width;
      height = bounds.height;
      const ratio = window.devicePixelRatio || 1;
      canvas.width = Math.round(width * ratio);
      canvas.height = Math.round(height * ratio);
      context.setTransform(ratio, 0, 0, ratio, 0, 0);
      restart();
    });
    observer.observe(canvas);
    const themeObserver = new MutationObserver(() => {
      resolvePalette();
      restart();
    });
    for (
      let ancestor: HTMLElement | null = canvas;
      ancestor;
      ancestor = ancestor.parentElement
    ) {
      themeObserver.observe(ancestor, {
        attributes: true,
        attributeFilter: ["style", "class", "data-theme", "data-brand"],
      });
    }
    repaint.current = restart;
    preference.addEventListener("change", restart);
    document.addEventListener("visibilitychange", restart);
    restart();
    return () => {
      cancelAnimationFrame(frame);
      repaint.current = null;
      observer.disconnect();
      themeObserver.disconnect();
      preference.removeEventListener("change", restart);
      document.removeEventListener("visibilitychange", restart);
    };
  }, [active, color, reducedMotion]);

  // Static preferences still respond to consumer energy changes without a ticker.
  useEffect(() => {
    if (
      reducedMotion ||
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) {
      repaint.current?.();
    }
  }, [audioLevel, voiceDetected, state, reducedMotion]);

  return active ? (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      data-k-audio-edge-glow={state}
      style={{
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        pointerEvents: "none",
        color,
      }}
    />
  ) : null;
}
