export interface KMapPinDragOptions {
  activation?: "drag" | "longPress";
  longPressMs?: number;
  scale?: number;
  durationMs?: number;
}

export function resolvePinDrag(options: KMapPinDragOptions = {}) {
  const result = {
    activation: options.activation ?? "drag",
    longPressMs: options.longPressMs ?? 400,
    scale: options.scale ?? 1.15,
    durationMs: options.durationMs ?? 160,
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
  return result;
}
