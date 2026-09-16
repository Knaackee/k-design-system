import { useEffect, useRef } from "react";
import type { KTimeFormat } from "./date-values.js";
import type { KPickerLabels } from "./labels.js";
const pad = (n: number) => String(n).padStart(2, "0");
function TimeColumn({
  label,
  values,
  value,
  onChange,
}: {
  label: string;
  values: string[];
  value: string;
  onChange: (value: string) => void;
}) {
  const list = useRef<HTMLDivElement>(null),
    focusSelected = useRef(false);
  const drag = useRef<{
    id: number;
    y: number;
    top: number;
    moved: boolean;
  } | null>(null);
  const suppressClick = useRef(false);
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      const node = list.current?.querySelector<HTMLElement>(
        '[aria-pressed="true"]',
      );
      if (node && list.current) {
        list.current.scrollTop =
          node.offsetTop -
          list.current.clientHeight / 2 +
          node.offsetHeight / 2;
        if (focusSelected.current) node.focus({ preventScroll: true });
      }
      focusSelected.current = false;
    });
    return () => cancelAnimationFrame(frame);
  }, [value]);
  return (
    <div className="k-picker-time-column" role="group" aria-label={label}>
      <span>{label}</span>
      <div
        className="k-picker-time-scroll"
        ref={list}
        onPointerDown={(event) => {
          suppressClick.current = false;
          if (event.pointerType !== "mouse" || event.button !== 0) return;
          drag.current = {
            id: event.pointerId,
            y: event.clientY,
            top: event.currentTarget.scrollTop,
            moved: false,
          };
        }}
        onPointerMove={(event) => {
          if (event.buttons === 0) {
            drag.current = null;
            return;
          }
          const current = drag.current;
          if (!current || current.id !== event.pointerId) return;
          const delta = event.clientY - current.y;
          if (!current.moved && Math.abs(delta) < 4) return;
          current.moved = true;
          suppressClick.current = true;
          event.currentTarget.setPointerCapture(event.pointerId);
          event.currentTarget.scrollTop = current.top - delta;
          event.preventDefault();
        }}
        onPointerUp={() => {
          drag.current = null;
        }}
        onPointerCancel={() => {
          drag.current = null;
        }}
        onLostPointerCapture={() => {
          drag.current = null;
        }}
        onClickCapture={(event) => {
          if (suppressClick.current && event.detail > 0) {
            event.preventDefault();
            event.stopPropagation();
            suppressClick.current = false;
          }
        }}
      >
        {values.map((item, index) => (
          <button
            type="button"
            className="k-picker-day"
            key={item}
            aria-pressed={item === value}
            data-selected={item === value || undefined}
            tabIndex={item === value ? 0 : -1}
            onClick={() => onChange(item)}
            onKeyDown={(e) => {
              let next = index;
              if (e.key === "ArrowDown")
                next = Math.min(values.length - 1, index + 1);
              else if (e.key === "ArrowUp") next = Math.max(0, index - 1);
              else if (e.key === "Home") next = 0;
              else if (e.key === "End") next = values.length - 1;
              else return;
              e.preventDefault();
              focusSelected.current = true;
              onChange(values[next]);
            }}
          >
            {item}
          </button>
        ))}
      </div>
    </div>
  );
}
export function PickerTime({
  value,
  onChange,
  timeFormat,
  minuteStep,
  labels,
}: {
  value: string;
  onChange: (value: string) => void;
  timeFormat: KTimeFormat;
  minuteStep: number;
  labels: KPickerLabels;
}) {
  const [hour, minute] = value.split(":").map(Number),
    h12 = timeFormat === "h12";
  const hours = Array.from({ length: h12 ? 12 : 24 }, (_, i) =>
    pad(h12 ? i + 1 : i),
  );
  const minutes = Array.from(
    new Set([
      ...Array.from({ length: 60 / minuteStep }, (_, i) => i * minuteStep),
      minute,
    ]),
  )
    .sort((a, b) => a - b)
    .map(pad);
  return (
    <div className="k-picker-time">
      <TimeColumn
        label={labels.hours}
        values={hours}
        value={pad(h12 ? hour % 12 || 12 : hour)}
        onChange={(v) =>
          onChange(
            `${pad(h12 ? (Number(v) % 12) + (hour >= 12 ? 12 : 0) : Number(v))}:${pad(minute)}`,
          )
        }
      />
      <TimeColumn
        label={labels.minutes}
        values={minutes}
        value={pad(minute)}
        onChange={(v) => onChange(`${pad(hour)}:${v}`)}
      />
      {h12 && (
        <TimeColumn
          label={labels.period}
          values={["AM", "PM"]}
          value={hour >= 12 ? "PM" : "AM"}
          onChange={(v) =>
            onChange(
              `${pad((hour % 12) + (v === "PM" ? 12 : 0))}:${pad(minute)}`,
            )
          }
        />
      )}
    </div>
  );
}
