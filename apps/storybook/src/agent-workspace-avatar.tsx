import { useEffect, useRef, useState } from "react";
import { Alignment, Fit, Layout, Rive, RuntimeLoader } from "@rive-app/canvas";
import wasmUrl from "@rive-app/canvas/rive.wasm?url";
import fallbackUrl from "@rive-app/canvas/rive_fallback.wasm?url";

RuntimeLoader.setWasmUrl(wasmUrl);
RuntimeLoader.setWasmFallbackUrl(fallbackUrl);
let asset: Promise<ArrayBuffer> | undefined;
function characterBytes() {
  return (asset ??= fetch("/rive/rive-character-v2.riv")
    .then((response) => {
      if (!response.ok) throw new Error("Avatar unavailable");
      return response.arrayBuffer();
    })
    .catch((error) => {
      asset = undefined;
      throw error;
    }));
}

/** Gallery-owned content: the workspace itself accepts any avatar node. */
export function AgentWorkspaceAvatar({
  shape,
  color,
  status = "idle",
  size = 144,
  label = "Agent",
}: {
  shape: string;
  color: string;
  status?: string;
  size?: number;
  label?: string;
}) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const [ready, setReady] = useState(false);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    let disposed = false;
    let runtime: Rive | undefined;
    let frame = 0;
    setReady(false);
    setFailed(false);
    const media = window.matchMedia("(prefers-reduced-motion: reduce)");
    const resize = () => {
      if (!runtime || !canvas.current) return;
      // Keep the drawing buffer stable while CSS animates the visible size.
      // Resizing it on every transition frame clears the rendered character.
      const pixels = Math.ceil(size * 2 * (window.devicePixelRatio || 1));
      if (canvas.current.width === pixels && canvas.current.height === pixels)
        return;
      canvas.current.width = pixels;
      canvas.current.height = pixels;
      const { width, height } = canvas.current;
      const margin = Math.min(width, height) * 0.3;
      runtime.layout = runtime.layout.copyWith({
        minX: margin,
        minY: margin,
        maxX: width - margin,
        maxY: height - margin,
      });
    };
    const motion = () => {
      const vm = runtime?.viewModelInstance;
      if (vm?.boolean("reducedMotion"))
        vm.boolean("reducedMotion")!.value = media.matches;
      if (vm?.boolean("fidgets"))
        vm.boolean("fidgets")!.value = status === "idle" && !media.matches;
    };
    const visibility = () => {
      if (document.hidden) runtime?.pause();
      else runtime?.play();
    };
    window.addEventListener("resize", resize);
    void characterBytes()
      .then((buffer) => {
        if (disposed || !canvas.current) return;
        runtime = new Rive({
          buffer,
          canvas: canvas.current,
          artboard: "Avatar",
          stateMachines: "Avatar",
          autoplay: true,
          autoBind: false,
          shouldDisableRiveListeners: true,
          layout: new Layout({ fit: Fit.Contain, alignment: Alignment.Center }),
          onLoad: () => {
            if (disposed || !runtime) return;
            const vm = runtime
              .viewModelByName("Avatar")
              ?.instanceByName("Default");
            if (!vm) {
              setFailed(true);
              return;
            }
            runtime.bindViewModelInstance(vm);
            for (const [name, value] of Object.entries({
              bodyShape: shape,
              shapeTransition: "hard",
              status,
              pickMe: "off",
              accessory: "none",
              head: "none",
              neck: "none",
              faceAcc: "none",
            })) {
              const field = vm.enum(name);
              if (field) field.value = value;
            }
            motion();
            resize();
            // A shape commit applies its defaults first. Reveal only the final color.
            frame = requestAnimationFrame(() => {
              frame = requestAnimationFrame(() => {
                if (disposed) return;
                const field = vm.color("bodyColor");
                if (field)
                  field.value =
                    (0xff000000 | parseInt(color.slice(1), 16)) >>> 0;
                frame = requestAnimationFrame(() => {
                  if (!disposed) setReady(true);
                });
              });
            });
            visibility();
          },
          onLoadError: () => {
            if (!disposed) setFailed(true);
          },
        });
      })
      .catch(() => {
        if (!disposed) setFailed(true);
      });
    media.addEventListener("change", motion);
    document.addEventListener("visibilitychange", visibility);
    return () => {
      disposed = true;
      cancelAnimationFrame(frame);
      window.removeEventListener("resize", resize);
      media.removeEventListener("change", motion);
      document.removeEventListener("visibilitychange", visibility);
      runtime?.cleanup();
    };
  }, [shape, color, status, size]);
  return (
    <span
      role="img"
      aria-label={failed ? `${label}: Avatar nicht verfügbar` : label}
      style={{
        display: "block",
        position: "relative",
        width: "100%",
        height: "100%",
        maxWidth: size,
        maxHeight: size,
        minWidth: 0,
        minHeight: 0,
        overflow: "hidden",
      }}
    >
      <canvas
        ref={canvas}
        aria-hidden
        style={{
          position: "absolute",
          width: "200%",
          height: "200%",
          left: "-50%",
          top: "-50%",
          opacity: ready ? 1 : 0,
        }}
      />
      {failed && (
        <span style={{ display: "grid", placeItems: "center", height: "100%" }}>
          {label.slice(0, 1)}
        </span>
      )}
    </span>
  );
}
