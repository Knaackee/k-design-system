export interface KMapPinDragOptions {
  activation?: "drag" | "longPress";
  longPressMs?: number;
  scale?: number;
  durationMs?: number;
  edgePan?: false | KMapPinEdgePanOptions;
}

export interface KMapPinEdgePanOptions {
  padding?: number;
  maxSpeed?: number;
  zoomOutPerSecond?: number;
  minZoom?: number;
}

export function edgePanVelocity(
  point: { x: number; y: number },
  size: { width: number; height: number },
  padding: number,
  maxSpeed: number,
) {
  const axis = (value: number, length: number) => {
    if (value < padding) return -maxSpeed * (1 - Math.max(0, value) / padding);
    if (value > length - padding)
      return maxSpeed * (1 - Math.max(0, length - value) / padding);
    return 0;
  };
  return { x: axis(point.x, size.width), y: axis(point.y, size.height) };
}

export function resolvePinDrag(options: KMapPinDragOptions = {}) {
  const result = {
    activation: options.activation ?? "drag",
    longPressMs: options.longPressMs ?? 400,
    scale: options.scale ?? 1.15,
    durationMs: options.durationMs ?? 160,
    edgePan:
      options.edgePan === false || options.edgePan === undefined
        ? null
        : {
            padding: options.edgePan.padding ?? 56,
            maxSpeed: options.edgePan.maxSpeed ?? 180,
            zoomOutPerSecond: options.edgePan.zoomOutPerSecond ?? 0.18,
            minZoom: options.edgePan.minZoom ?? 8,
          },
  };
  if (!["drag", "longPress"].includes(result.activation))
    throw new RangeError("KMap drag activation must be drag or longPress");
  if (!Number.isFinite(result.scale) || result.scale <= 0)
    throw new RangeError("KMap drag scale must be positive and finite");
  for (const duration of [result.longPressMs, result.durationMs]) {
    if (!Number.isFinite(duration) || duration < 0)
      throw new RangeError(
        "KMap drag durations must be nonnegative and finite",
      );
  }
  if (result.edgePan) {
    const { padding, maxSpeed, zoomOutPerSecond, minZoom } = result.edgePan;
    if (!Number.isFinite(padding) || padding <= 0)
      throw new RangeError("KMap edge padding must be positive and finite");
    if (!Number.isFinite(maxSpeed) || maxSpeed < 0)
      throw new RangeError(
        "KMap edge pan speed must be nonnegative and finite",
      );
    if (!Number.isFinite(zoomOutPerSecond) || zoomOutPerSecond < 0)
      throw new RangeError(
        "KMap edge zoom rate must be nonnegative and finite",
      );
    if (!Number.isFinite(minZoom) || minZoom < 0)
      throw new RangeError(
        "KMap edge minimum zoom must be nonnegative and finite",
      );
  }
  return result;
}
