export function clampCoverFlowIndex(index: number, count: number): number {
  return Math.max(
    0,
    Math.min(
      Math.max(0, count - 1),
      Math.round(Number.isFinite(index) ? index : 0),
    ),
  );
}

export function coverFlowTransform(
  offset: number,
  angle: number,
  depth: number,
  spacing: number,
  sideOffset = 68,
  sideScale = 1,
) {
  const distance = Math.abs(offset);
  const side = Math.sign(offset);
  const turn = Math.min(1, distance);
  const x = side * (turn * sideOffset + Math.max(0, distance - 1) * spacing);
  const scale = 1 - turn * (1 - sideScale);
  return `translate(-50%, -50%) translateX(${x}%) translateZ(${-turn * depth}px) rotateY(${-side * turn * angle}deg)${scale === 1 ? "" : ` scale(${scale})`}`;
}
