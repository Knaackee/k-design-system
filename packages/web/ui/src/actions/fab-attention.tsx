import { useEffect, useRef, useState, type CSSProperties } from "react";
import { KChatBubble } from "../chat/chat-bubble.js";
import type { KFabItem } from "./fab.js";

export interface KFabAttention {
  id: string;
  itemId: string;
}

/** Append new notices last. The newest gets an immediate pulse, then all rotate.
 * The consumer removes acknowledged notices; animation never acknowledges them.
 */
export function FabAttention({
  notices,
  items,
  size,
  showMs,
  pauseMs,
  peekFraction,
  holdMs,
  onSelect,
}: {
  notices: readonly KFabAttention[];
  items: readonly KFabItem[];
  size?: number;
  showMs: number;
  pauseMs: number;
  peekFraction: number;
  holdMs: number;
  onSelect?: (notice: KFabAttention) => void;
}) {
  const [index, setIndex] = useState(() =>
    Math.max(
      0,
      notices.filter((notice) =>
        items.some((item) => item.id === notice.itemId && !item.disabled),
      ).length - 1,
    ),
  );
  const [cycle, setCycle] = useState(0);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const [reduced, setReduced] = useState(false);
  const eligible = notices.filter((notice) =>
    items.some((item) => item.id === notice.itemId && !item.disabled),
  );
  const key = JSON.stringify(
    eligible.map((notice) => [notice.id, notice.itemId]),
  );
  const hold = Number.isFinite(holdMs) ? Math.max(0, holdMs) : 324;
  const duration = Math.max(
    hold + 600,
    Number.isFinite(showMs) ? showMs : 1800,
  );
  const pause = Number.isFinite(pauseMs) ? Math.max(0, pauseMs) : 7000;
  const peek = Number.isFinite(peekFraction)
    ? Math.min(1, Math.max(0, peekFraction))
    : 0.5;
  const root = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const query = matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setReduced(query.matches);
    update();
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, []);
  useEffect(() => {
    if (!eligible.length || reduced || hovered || focused) return;
    const timer = setTimeout(() => {
      setIndex((value) => (value + 1) % eligible.length);
      setCycle((value) => value + 1);
    }, duration + pause);
    return () => clearTimeout(timer);
  }, [key, eligible.length, duration, pause, reduced, hovered, focused, cycle]);
  const notice = eligible[index % eligible.length];
  const item = items.find((item) => item.id === notice?.itemId);
  useEffect(() => {
    if (!root.current || reduced || hovered || focused) return;
    const motion = duration - hold;
    const rise = (motion * 432) / 1476;
    const point = (time: number, height: number, easing: string): Keyframe => ({
      offset: time / duration,
      transform: `translateY(${-100 * peek * height}%)`,
      easing,
    });
    const animation = root.current.animate(
      [
        point(0, 0, "ease-in-out"),
        point(rise, 1, "linear"),
        point(rise + hold, 1, "ease-in"),
        point(hold + (motion * 792) / 1476, 0, "ease-out"),
        point(hold + (motion * 972) / 1476, 0.36, "ease-in"),
        point(hold + (motion * 1152) / 1476, 0, "ease-out"),
        point(hold + (motion * 1260) / 1476, 0.14, "ease-in"),
        point(hold + (motion * 1368) / 1476, 0, "ease-out"),
        point(hold + (motion * 1422) / 1476, 0.04, "ease-in"),
        point(duration, 0, "linear"),
      ],
      { duration, fill: "both" },
    );
    return () => animation.cancel();
  }, [
    notice?.id,
    item?.id,
    cycle,
    duration,
    hold,
    peek,
    reduced,
    hovered,
    focused,
  ]);
  if (!notice || !item) return null;
  return (
    <span
      key={`${notice.id}-${cycle}`}
      ref={root}
      className="k-fab__attention"
      style={{ "--k-fab-attention-peek": `${-100 * peek}%` } as CSSProperties}
      onPointerEnter={() => setHovered(true)}
      onPointerLeave={() => setHovered(false)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    >
      <KChatBubble
        size={size}
        label={item.label}
        title={item.label}
        onClick={() => {
          onSelect?.(notice);
          item.onSelect();
        }}
      >
        {item.content}
      </KChatBubble>
    </span>
  );
}
