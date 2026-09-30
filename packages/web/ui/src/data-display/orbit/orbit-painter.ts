import type { KOrbitNode, KOrbitPoint, KOrbitTone } from "./orbit-model.js";
import type { KOrbitPalette } from "./orbit-draw.js";

export function kOrbitToneColor(
  tone: KOrbitTone | undefined,
  palette: KOrbitPalette,
): string {
  if (tone === "success") return palette.success;
  if (tone === "warning") return palette.warning;
  if (tone === "error") return palette.error;
  if (tone === "info") return palette.info;
  return palette.primary;
}

function statusTone(node: KOrbitNode): KOrbitTone | undefined {
  if (node.status === "question") return "warning";
  if (node.status === "error") return "error";
  if (node.status === "completed") return "success";
  if (node.status === "active") return node.tone ?? "info";
  return node.tone;
}

export function drawKOrbitParticle(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  color: string,
  palette: KOrbitPalette,
): void {
  context.beginPath();
  context.arc(point.x, point.y, palette.particleSize / 2, 0, Math.PI * 2);
  context.fillStyle = color;
  context.shadowBlur = palette.glowBlur;
  context.shadowColor = color;
  context.fill();
  context.shadowBlur = 0;
}

export function drawKOrbitGlow(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  radius: number,
  palette: KOrbitPalette,
): void {
  context.beginPath();
  context.arc(point.x, point.y, radius * 1.08, 0, Math.PI * 2);
  context.fillStyle = palette.glow;
  context.globalAlpha = palette.glowOpacity;
  context.shadowBlur = palette.glowBlur;
  context.shadowColor = palette.glow;
  context.fill();
  context.globalAlpha = 1;
  context.shadowBlur = 0;
}

export function drawKOrbitSphereFallback(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  radius: number,
  node: KOrbitNode,
  palette: KOrbitPalette,
): void {
  const base = kOrbitToneColor(node.tone, palette);
  const sphere = context.createRadialGradient(
    point.x - radius * 0.36,
    point.y - radius * 0.42,
    radius * 0.05,
    point.x,
    point.y,
    radius,
  );
  sphere.addColorStop(0, palette.surface);
  sphere.addColorStop(0.24, base);
  sphere.addColorStop(0.76, palette.primary);
  sphere.addColorStop(1, palette.shadow);
  context.beginPath();
  context.arc(point.x, point.y, radius, 0, Math.PI * 2);
  context.fillStyle = sphere;
  context.fill();
}

export function drawKOrbitRim(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  radius: number,
  palette: KOrbitPalette,
  node: KOrbitNode,
): void {
  context.beginPath();
  context.arc(point.x, point.y, radius, 0, Math.PI * 2);
  const tone = statusTone(node);
  context.strokeStyle =
    node.borderColor ??
    (tone && tone !== "neutral"
      ? kOrbitToneColor(tone, palette)
      : node.appearance === "sphere"
        ? palette.muted
        : palette.nodeBorder);
  context.lineWidth = palette.connectionWidth;
  context.stroke();
}

export function drawKOrbitStatus(
  context: CanvasRenderingContext2D,
  node: KOrbitNode,
  point: KOrbitPoint,
  nodeRadius: number,
  elapsed: number,
  reducedMotion: boolean,
  palette: KOrbitPalette,
  presenceScale = 1,
): void {
  const pulse =
    node.pulse ?? (node.status === "active" || node.status === "question");
  if (!pulse || reducedMotion) return;
  const period = node.pulsePeriodMs ?? palette.pulseDuration;
  const progress = ((elapsed * 1000) % period) / period;
  const color = node.borderColor ?? kOrbitToneColor(statusTone(node), palette);
  context.beginPath();
  context.arc(
    point.x,
    point.y,
    nodeRadius + (3 + progress * 10) * presenceScale,
    0,
    Math.PI * 2,
  );
  context.strokeStyle = color;
  context.lineWidth = palette.connectionWidth;
  context.globalAlpha =
    (node.pulseIntensity ?? 1) *
    (1 - progress) *
    (0.55 + 0.45 * Math.max(0, Math.min(1, (point.depth + 1) / 2)));
  context.stroke();
  context.globalAlpha = 1;
}

export function drawKOrbitPing(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  baseRadius: number,
  progress: number,
  color: string,
  radius: number,
): void {
  context.beginPath();
  context.arc(
    point.x,
    point.y,
    baseRadius + 3 + progress * radius,
    0,
    Math.PI * 2,
  );
  context.strokeStyle = color;
  context.globalAlpha = 1 - progress;
  context.lineWidth = 2;
  context.stroke();
  context.globalAlpha = 1;
}

export function drawKOrbitFlatNode(
  context: CanvasRenderingContext2D,
  point: KOrbitPoint,
  radius: number,
  node: KOrbitNode,
  palette: KOrbitPalette,
): boolean {
  context.beginPath();
  context.arc(point.x, point.y, radius, 0, Math.PI * 2);
  context.fillStyle =
    node.backgroundColor ?? palette.nodeSurfaces[node.tone ?? "neutral"];
  context.fill();
  return true;
}

export function drawKOrbitProgress(
  context: CanvasRenderingContext2D,
  node: KOrbitNode,
  point: KOrbitPoint,
  radius: number,
  palette: KOrbitPalette,
): void {
  if (node.progress === undefined || node.progress <= 0) return;
  context.beginPath();
  context.arc(
    point.x,
    point.y,
    radius,
    -Math.PI / 2,
    -Math.PI / 2 + (Math.PI * 2 * node.progress) / 100,
  );
  context.strokeStyle =
    node.borderColor ?? kOrbitToneColor(statusTone(node), palette);
  context.lineWidth =
    ((palette.progressWidth ?? palette.connectionWidth * 2) * radius * 2) /
    palette.nodeSize;
  context.stroke();
}
