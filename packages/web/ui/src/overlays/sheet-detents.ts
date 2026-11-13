export type KSheetDetent = "half" | "full";

/** Closing is always the zero snap; named detents are ordered independently of input order. */
export function sheetDetentConfiguration(
  detents: readonly KSheetDetent[] | undefined,
  initial: KSheetDetent = "half",
) {
  const enabled = Boolean(detents?.length);
  const points = enabled && detents?.includes("half") ? [0, 0.5, 1] : [0, 1];
  return {
    enabled,
    points,
    initialSnap:
      enabled && initial === "half" && points.length === 3
        ? 1
        : points.length - 1,
  };
}

/** A gesture handed off from an inner list settles at the nearest allowed height. */
export function sheetHandoffSnap(
  offset: number,
  height: number,
  points: readonly number[],
  active: number,
  flingDown: boolean,
  dismissible: boolean,
  cancelled: boolean,
) {
  if (cancelled || height <= 0) return active;
  const first = dismissible ? 0 : 1;
  if (flingDown) return Math.max(first, active - 1);
  const visible = Math.max(0, Math.min(1, 1 - offset / height));
  let nearest = first;
  for (let index = first + 1; index < points.length; index++) {
    if (Math.abs(points[index] - visible) < Math.abs(points[nearest] - visible))
      nearest = index;
  }
  return nearest;
}
