/** Shared, visibility-aware clock. Last subscriber removes all global listeners. */
type Tick = (dt: number) => void;
const subscribers = new Set<Tick>();
export const pointer = { x: NaN, y: NaN };
let frame = 0;
let last = 0;
const away = () => {
  pointer.x = pointer.y = NaN;
};
const move = (event: PointerEvent) => {
  if (event.isPrimary) {
    pointer.x = event.clientX;
    pointer.y = event.clientY;
  }
};
const end = (event: PointerEvent) => {
  if (event.pointerType !== "mouse") away();
};
function stop() {
  cancelAnimationFrame(frame);
  frame = 0;
  last = 0;
}
function start() {
  if (!frame && subscribers.size && !document.hidden)
    frame = requestAnimationFrame(loop);
}
function visibility() {
  if (document.hidden) {
    stop();
    away();
  } else start();
}
function loop(now: number) {
  frame = 0;
  const dt = last ? Math.min(0.1, (now - last) / 1000) : 0;
  last = now;
  subscribers.forEach((fn) => fn(dt));
  start();
}
export function subscribe(fn: Tick): () => void {
  if (!subscribers.size) {
    document.addEventListener("pointermove", move, { passive: true });
    document.addEventListener("pointerdown", move, { passive: true });
    document.addEventListener("pointerup", end);
    document.addEventListener("pointercancel", away);
    document.addEventListener("pointerleave", away);
    document.addEventListener("visibilitychange", visibility);
    window.addEventListener("blur", away);
  }
  subscribers.add(fn);
  start();
  return () => {
    subscribers.delete(fn);
    if (subscribers.size) return;
    stop();
    away();
    document.removeEventListener("pointermove", move);
    document.removeEventListener("pointerdown", move);
    document.removeEventListener("pointerup", end);
    document.removeEventListener("pointercancel", away);
    document.removeEventListener("pointerleave", away);
    document.removeEventListener("visibilitychange", visibility);
    window.removeEventListener("blur", away);
  };
}
