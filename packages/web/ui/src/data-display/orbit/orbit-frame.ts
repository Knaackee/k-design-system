import { drawKOrbit, type KOrbitFrameSignal } from "./orbit-draw.js";
import { kOrbitToneColor } from "./orbit-painter.js";
import { drawKOrbitCenterShader } from "./orbit-shader.js";
import {
  isKOrbitNodeOccluded,
  layoutKOrbitLabels,
} from "./orbit-label-layout.js";
import { cssNumber, kOrbitPalette } from "./orbit-palette.js";
import { projectKOrbitScene } from "./orbit-model.js";
import {
  kOrbitPresenceScale,
  type KOrbitExtentTransition,
} from "./orbit-presence.js";
import type { RendererOptions } from "./orbit-renderer.js";
import {
  resolveKOrbitCamera,
  animateKOrbitProgress,
  type KOrbitPresentation,
} from "./orbit-transitions.js";

export function drawFrame(
  context: CanvasRenderingContext2D,
  shaderTarget: HTMLCanvasElement,
  options: RendererOptions,
  size: { width: number; height: number },
  ratio: number,
  presentation: KOrbitPresentation,
  elapsed: number,
  signals: readonly KOrbitFrameSignal[],
  angles: ReadonlyMap<string, number>,
): void {
  const styles = getComputedStyle(options.root.current!);
  const colors = kOrbitPalette(styles);
  const now = performance.now();
  const duration = options.reducedMotion
    ? 0
    : cssNumber(styles, "--k-component-orbit-motion-transition-duration", 240);
  const nodes = animateKOrbitProgress(
    presentation.progress,
    options.nodes,
    now,
    duration,
  ).map((node) => {
    const element = options.nodeElements.current.get(node.id);
    if (!element || (!node.backgroundColor && !node.borderColor)) return node;
    const style = getComputedStyle(element);
    return {
      ...node,
      backgroundColor: node.backgroundColor ? style.borderTopColor : undefined,
      borderColor: node.borderColor ? style.borderBottomColor : undefined,
    };
  });
  const sceneExtent = extentAt(options.extent.current, performance.now());
  const project = (view: import("./orbit-model.js").KOrbitViewState) =>
    projectKOrbitScene(
      options.levels,
      nodes,
      view,
      elapsed,
      size.width,
      size.height,
      colors.centerRadiusRatio,
      sceneExtent,
      angles,
    );
  const view = resolveKOrbitCamera(
    presentation,
    options.view.current,
    options.pinnedId,
    (candidate) => {
      const point = project(candidate).points.get(options.pinnedId ?? "");
      return point
        ? {
            x: candidate.offset.x + size.width / 2 - point.x,
            y: candidate.offset.y + size.height / 2 - point.y,
          }
        : candidate.offset;
    },
    now,
    duration,
  );
  const scene = project(view);
  const nodeScales = new Map(
    options.nodes.map((node) => [
      node.id,
      options.reducedMotion
        ? 1
        : kOrbitPresenceScale(
            options.presenceMotion.current.get(node.id),
            performance.now(),
          ),
    ]),
  );
  const spriteSize = Math.max(
    1,
    Math.ceil((Math.max(...scene.radii.values(), 1) * 2.4 + 4) * ratio),
  );
  if (shaderTarget.width !== spriteSize || shaderTarget.height !== spriteSize) {
    shaderTarget.width = spriteSize;
    shaderTarget.height = spriteSize;
  }
  const spriteCssSize = spriteSize / ratio;
  const points = drawKOrbit(
    context,
    size,
    options.levels,
    nodes,
    options.connections.map((connection) => ({
      ...connection,
      lineStyle: connection.lineStyle ?? options.lineStyle,
    })),
    signals,
    view,
    elapsed,
    colors,
    true,
    options.reducedMotion,
    undefined,
    sceneExtent,
    (node, point, radius) => {
      const drawn = drawKOrbitCenterShader(
        shaderTarget,
        spriteCssSize,
        spriteCssSize,
        ratio,
        { x: spriteCssSize / 2, y: spriteCssSize / 2 },
        colors,
        elapsed,
        radius,
        kOrbitToneColor(node.tone, colors),
      );
      if (!drawn) return false;
      context.save();
      context.drawImage(
        shaderTarget,
        point.x - spriteCssSize / 2,
        point.y - spriteCssSize / 2,
        spriteCssSize,
        spriteCssSize,
      );
      context.restore();
      return true;
    },
    nodeScales,
    { ...scene, radii: new Map(scene.radii) },
  );
  const labels = layoutKOrbitLabels({
    nodes: options.nodes,
    visibleIds:
      options.labelVisibility === "always"
        ? undefined
        : new Set(
            options.nodes
              .filter(
                (node) =>
                  node.id === options.selectedId ||
                  options.nodeElements.current
                    .get(node.id)
                    ?.matches(":hover, :focus-visible"),
              )
              .map((node) => node.id),
          ),
    points,
    selectedId: options.selectedId,
    width: size.width,
    height: size.height,
    center: scene.center,
    centerRadius: scene.centerRadius,
    nodeRadius: colors.nodeSize / 2,
    nodeRadii: scene.radii,
    labelOffset: colors.labelOffset,
    fontSize: colors.labelSize,
    paddingInline: cssNumber(
      getComputedStyle(options.root.current!),
      "--k-space-control-gap",
      8,
    ),
    lineHeight: colors.labelLineHeight,
  });
  options.projectedPoints.current = points;
  for (const node of options.nodes) {
    const button = options.nodeElements.current.get(node.id);
    const point = points.get(node.id);
    if (!button || !point) continue;
    const radius =
      (scene.radii.get(node.id) ?? colors.nodeSize / 2) *
      (nodeScales.get(node.id) ?? 1);
    button.style.transform = `translate3d(${point.x}px, ${point.y}px, 0) translate(-50%, -50%)`;
    button.style.zIndex = String(Math.round((point.depth + 2) * 100));
    button.style.setProperty(
      "--k-orbit-depth",
      String(0.55 + 0.45 * Math.max(0, Math.min(1, (point.depth + 1) / 2))),
    );
    button.style.setProperty("--k-orbit-node-radius", `${radius}px`);
    button.style.setProperty(
      "--k-orbit-label-offset",
      `${radius + colors.labelOffset / 3}px`,
    );
    if (!node.levelId)
      button.style.setProperty(
        "--k-orbit-center-radius",
        `${scene.centerRadius}px`,
      );
    if (!node.levelId)
      button.style.setProperty(
        "--k-orbit-root-label-gap",
        `${colors.labelOffset / 3}px`,
      );
    const label = labels.get(node.id);
    button.dataset.labelSide = label?.side ?? "hidden";
    if (label)
      button.style.setProperty("--k-orbit-label-width", `${label.width}px`);
    button.style.setProperty(
      "--k-orbit-node-scale",
      String(radius / colors.nodeSize),
    );
    const occluded = isKOrbitNodeOccluded(node.id, scene);
    const inaccessible = occluded || options.departingIds.has(node.id);
    button.dataset.occluded = occluded ? "true" : "false";
    button.style.visibility = occluded ? "hidden" : "";
    button.style.pointerEvents = inaccessible ? "none" : "";
    if (inaccessible) {
      button.setAttribute("aria-hidden", "true");
      button.tabIndex = -1;
      if (document.activeElement === button) options.root.current?.focus();
    } else {
      button.removeAttribute("aria-hidden");
      button.tabIndex = 0;
    }
  }
}

function extentAt(
  transition: KOrbitExtentTransition | undefined,
  now: number,
): number | undefined {
  if (!transition) return undefined;
  if (transition.durationMs <= 0) return transition.to;
  const progress = Math.max(
    0,
    Math.min(1, (now - transition.startedAt) / transition.durationMs),
  );
  return transition.from + (transition.to - transition.from) * progress;
}
