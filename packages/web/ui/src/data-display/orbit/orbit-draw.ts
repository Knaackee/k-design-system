import {
  kOrbitConnectionPoint,
  kOrbitLocalPoint,
  projectKOrbitScene,
  projectKOrbitWorldPoint,
  type KOrbitConnection,
  type KOrbitLevel,
  type KOrbitNode,
  type KOrbitPoint,
  type KOrbitSceneProjection,
  type KOrbitSignalStyle,
  type KOrbitViewState,
} from "./orbit-model.js";
import {
  drawKOrbitGlow,
  drawKOrbitFlatNode,
  drawKOrbitParticle,
  drawKOrbitPing,
  drawKOrbitRim,
  drawKOrbitSphereFallback,
  drawKOrbitStatus,
  drawKOrbitProgress,
  kOrbitToneColor,
} from "./orbit-painter.js";

export interface KOrbitFrameSignal {
  connectionId?: string;
  nodeId?: string;
  progress: number;
  style: KOrbitSignalStyle;
  sourcePing: boolean;
  arrivalPing: boolean;
}

export interface KOrbitPalette {
  surface: string;
  nodeSurfaces: Record<import("./orbit-model.js").KOrbitTone, string>;
  nodeBorder: string;
  track: string;
  primary: string;
  muted: string;
  info: string;
  success: string;
  warning: string;
  error: string;
  glow: string;
  shadow: string;
  progressWidth?: number;
  trackWidth: number;
  trackOpacity: number;
  connectionColor: string;
  connectionWidth: number;
  connectionDash: number;
  connectionGap: number;
  connectionOpacity: number;
  particleSize: number;
  trailLength: number;
  pingRadius: number;
  glowBlur: number;
  glowOpacity: number;
  centerRadiusRatio: number;
  nodeSize: number;
  pulseDuration: number;
  labelOffset: number;
  labelSize: number;
  labelLineHeight: number;
}

export type KOrbitSpherePainter = (
  node: KOrbitNode,
  point: KOrbitPoint,
  radius: number,
) => boolean;

interface DrawCommand {
  depth: number;
  draw(): void;
}

export function drawKOrbit(
  context: CanvasRenderingContext2D,
  size: { width: number; height: number },
  levels: readonly KOrbitLevel[],
  nodes: readonly KOrbitNode[],
  connections: readonly KOrbitConnection[],
  signals: readonly KOrbitFrameSignal[],
  view: KOrbitViewState,
  elapsed: number,
  palette: KOrbitPalette,
  centerFallback = true,
  reducedMotion = false,
  drawCenterLayer?: () => boolean,
  sceneExtent?: number,
  drawSphereLayer?: KOrbitSpherePainter,
  nodeScales: ReadonlyMap<string, number> = new Map(),
  projectedScene?: KOrbitSceneProjection,
): Map<string, KOrbitPoint> {
  const scene =
    projectedScene ??
    projectKOrbitScene(
      levels,
      nodes,
      view,
      elapsed,
      size.width,
      size.height,
      palette.centerRadiusRatio,
      sceneExtent,
    );
  for (const [id, radius] of scene.radii)
    scene.radii.set(id, radius * (nodeScales.get(id) ?? 1));
  const commands: DrawCommand[] = [];
  context.clearRect(0, 0, size.width, size.height);
  context.lineCap = "round";

  addRingCommands(
    commands,
    context,
    scene,
    view,
    size,
    palette,
    nodes,
    nodeScales,
  );
  for (const connection of connections) {
    if (
      !connection.visible &&
      !signals.some(({ connectionId }) => connectionId === connection.id)
    )
      continue;
    const source = scene.points.get(connection.sourceId);
    const target = scene.points.get(connection.targetId);
    if (!source || !target) continue;
    addCurveCommands(
      commands,
      context,
      scene,
      source,
      target,
      40,
      connection.tone
        ? kOrbitToneColor(connection.tone, palette)
        : palette.connectionColor,
      palette.connectionWidth,
      palette.connectionOpacity,
      connection.lineStyle === "dotted"
        ? [palette.connectionWidth, palette.connectionGap]
        : connection.lineStyle === "solid"
          ? []
          : [palette.connectionDash, palette.connectionGap],
    );
  }

  for (const node of nodes) {
    const point = scene.points.get(node.id);
    const radius = scene.radii.get(node.id);
    if (!point || !radius) continue;
    commands.push({
      depth: point.depth,
      draw: () => {
        const root = !node.levelId;
        const sphere = node.appearance === "sphere";
        if (root && sphere) drawKOrbitGlow(context, point, radius, palette);
        const customDrawn = !sphere
          ? drawKOrbitFlatNode(context, point, radius, node, palette)
          : (root && drawCenterLayer?.()) ||
            drawSphereLayer?.(node, point, radius) ||
            false;
        if (!customDrawn && (centerFallback || !root))
          drawKOrbitSphereFallback(context, point, radius, node, palette);
        drawKOrbitRim(context, point, radius, palette, node);
        drawKOrbitProgress(context, node, point, radius, palette);
        drawKOrbitStatus(
          context,
          node,
          point,
          radius,
          elapsed,
          reducedMotion,
          palette,
          nodeScales.get(node.id) ?? 1,
        );
      },
    });
  }

  for (const signal of signals) {
    if (signal.nodeId) {
      const point = scene.points.get(signal.nodeId);
      const node = nodes.find((node) => node.id === signal.nodeId);
      if (point && node)
        addPingCommand(
          commands,
          context,
          scene,
          point,
          signal.progress,
          kOrbitToneColor(node.tone, palette),
          palette,
        );
      continue;
    }
    const connection = connections.find(({ id }) => id === signal.connectionId);
    const source = connection && scene.points.get(connection.sourceId);
    const target = connection && scene.points.get(connection.targetId);
    if (!connection || !source || !target) continue;
    const paths =
      connection.direction === "reverse"
        ? ([[target, source]] as const)
        : connection.direction === "both"
          ? ([
              [source, target],
              [target, source],
            ] as const)
          : ([[source, target]] as const);
    for (const [start, end] of paths)
      addSignalCommands(
        commands,
        context,
        scene,
        signal,
        start,
        end,
        kOrbitToneColor(connection.tone, palette),
        palette,
      );
  }

  commands.sort((a, b) => a.depth - b.depth);
  for (const command of commands) command.draw();
  context.setLineDash([]);
  context.globalAlpha = 1;
  return scene.points;
}

function addRingCommands(
  commands: DrawCommand[],
  context: CanvasRenderingContext2D,
  scene: KOrbitSceneProjection,
  view: KOrbitViewState,
  size: { width: number; height: number },
  palette: KOrbitPalette,
  nodes: readonly KOrbitNode[],
  nodeScales: ReadonlyMap<string, number>,
): void {
  for (const ring of scene.rings) {
    const visibility = Math.min(
      1,
      Math.max(
        0,
        ...nodes
          .filter(
            (node) =>
              node.levelId === ring.level.id && node.parentId === ring.parentId,
          )
          .map((node) => nodeScales.get(node.id) ?? 1),
      ),
    );
    let previous: KOrbitPoint | undefined;
    let dashOffset = 0;
    for (let index = 0; index <= 192; index += 1) {
      const local = kOrbitLocalPoint(ring.level, (index / 192) * Math.PI * 2);
      const point = projectKOrbitWorldPoint(
        {
          x: ring.anchor.x + local.x,
          y: ring.anchor.y + local.y,
          z: ring.anchor.z + local.z,
        },
        view,
        size.width,
        size.height,
        scene.sceneExtent,
      );
      if (previous)
        dashOffset = addSegment(
          commands,
          context,
          scene,
          previous,
          point,
          palette.track,
          palette.trackWidth,
          palette.trackOpacity * visibility,
          [],
          dashOffset,
        );
      previous = point;
    }
  }
}

function addCurveCommands(
  commands: DrawCommand[],
  context: CanvasRenderingContext2D,
  scene: KOrbitSceneProjection,
  source: KOrbitPoint,
  target: KOrbitPoint,
  steps: number,
  color: string,
  width: number,
  opacity: number,
  dash: readonly number[],
  from = 0,
  to = 1,
): void {
  let previous = kOrbitConnectionPoint(source, target, from);
  let dashOffset = 0;
  for (let index = 1; index <= steps; index += 1) {
    const point = kOrbitConnectionPoint(
      source,
      target,
      from + (to - from) * (index / steps),
    );
    dashOffset = addSegment(
      commands,
      context,
      scene,
      previous,
      point,
      color,
      width,
      opacity,
      dash,
      dashOffset,
    );
    previous = point;
  }
}

function addSegment(
  commands: DrawCommand[],
  context: CanvasRenderingContext2D,
  scene: KOrbitSceneProjection,
  start: KOrbitPoint,
  end: KOrbitPoint,
  color: string,
  width: number,
  opacity: number,
  dash: readonly number[],
  dashOffset: number,
): number {
  const midpoint = {
    x: (start.x + end.x) / 2,
    y: (start.y + end.y) / 2,
    depth: (start.depth + end.depth) / 2,
  };
  const length = Math.hypot(end.x - start.x, end.y - start.y);
  if (behindSphere(midpoint, scene)) return dashOffset + length;
  commands.push({
    depth: midpoint.depth,
    draw: () => {
      context.beginPath();
      context.moveTo(start.x, start.y);
      context.lineTo(end.x, end.y);
      context.strokeStyle = color;
      context.lineWidth = width;
      context.globalAlpha = opacity;
      context.setLineDash([...dash]);
      context.lineDashOffset = -dashOffset;
      context.stroke();
      context.globalAlpha = 1;
    },
  });
  return dashOffset + length;
}

function behindSphere(
  point: KOrbitPoint,
  scene: KOrbitSceneProjection,
): boolean {
  for (const [id, center] of scene.points) {
    const radius = scene.radii.get(id) ?? 0;
    const distance = Math.hypot(point.x - center.x, point.y - center.y);
    if (distance >= radius) continue;
    const surfaceDepth =
      center.depth +
      Math.sqrt(radius * radius - distance * distance) /
        (scene.scale * scene.sceneExtent);
    if (point.depth < surfaceDepth) return true;
  }
  return false;
}

function addSignalCommands(
  commands: DrawCommand[],
  context: CanvasRenderingContext2D,
  scene: KOrbitSceneProjection,
  signal: KOrbitFrameSignal,
  source: KOrbitPoint,
  target: KOrbitPoint,
  color: string,
  palette: KOrbitPalette,
): void {
  const span = Math.min(0.4, palette.trailLength / 160);
  if (signal.style === "trail")
    addCurveCommands(
      commands,
      context,
      scene,
      source,
      target,
      12,
      color,
      palette.particleSize,
      0.6,
      [],
      Math.max(0, signal.progress - span),
      signal.progress,
    );
  if (signal.style !== "pings") {
    const point = kOrbitConnectionPoint(source, target, signal.progress);
    if (!behindSphere(point, scene))
      commands.push({
        depth: point.depth,
        draw: () => drawKOrbitParticle(context, point, color, palette),
      });
  }
  if (signal.sourcePing && signal.progress < 0.22)
    addPingCommand(
      commands,
      context,
      scene,
      source,
      signal.progress / 0.22,
      color,
      palette,
    );
  if (signal.arrivalPing && signal.progress > 0.78)
    addPingCommand(
      commands,
      context,
      scene,
      target,
      (signal.progress - 0.78) / 0.22,
      color,
      palette,
    );
}

function addPingCommand(
  commands: DrawCommand[],
  context: CanvasRenderingContext2D,
  scene: KOrbitSceneProjection,
  point: KOrbitPoint,
  progress: number,
  color: string,
  palette: KOrbitPalette,
): void {
  const endpointRadius = [...scene.points].find(
    ([, candidate]) => candidate === point,
  )?.[0];
  const baseRadius = endpointRadius
    ? (scene.radii.get(endpointRadius) ?? 0)
    : 0;
  commands.push({
    depth:
      point.depth +
      (baseRadius + palette.pingRadius) / (scene.scale * scene.sceneExtent),
    draw: () =>
      drawKOrbitPing(
        context,
        point,
        baseRadius,
        progress,
        color,
        palette.pingRadius,
      ),
  });
}
