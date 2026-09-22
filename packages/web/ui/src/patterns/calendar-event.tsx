import type { KCalendarProps, KCalendarLabels } from "./calendar-types.js";
import { shiftSlot, slotNumber, type CalendarEntry } from "./calendar-model.js";
import type { useCalendarInteraction } from "./calendar-interaction.js";
export function CalendarEvent<T>({
  props,
  entry,
  compact,
  labels,
  interaction,
  dragging = false,
}: {
  props: KCalendarProps<T>;
  entry: CalendarEntry<T>;
  compact: boolean;
  labels: KCalendarLabels;
  interaction: ReturnType<typeof useCalendarInteraction<T>>;
  dragging?: boolean;
}) {
  const { renderEvent, getEventStart, getEventEnd } = props;
  const step = entry.start.allDay ? 1440 : (props.stepMinutes ?? 30);
  return (
    <div
      className={`k-calendar-event${compact ? " k-calendar-event-compact" : ""}${dragging ? " k-calendar-event-dragging" : ""}`}
      onPointerDown={(e) => interaction.begin(e, entry)}
    >
      <div
        className="k-calendar-event-content"
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.target !== e.currentTarget) return;
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            props.onEventOpen?.(entry.event);
          }
          if (
            e.altKey &&
            ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.key)
          ) {
            e.preventDefault();
            const delta =
              e.key === "ArrowUp"
                ? -step
                : e.key === "ArrowDown"
                  ? step
                  : e.key === "ArrowLeft"
                    ? -1440
                    : 1440;
            interaction.change("move", entry, {
              start: shiftSlot(entry.start, delta),
              end: shiftSlot(entry.end, delta),
            });
          }
        }}
      >
        {renderEvent({
          event: entry.event,
          eventId: entry.id,
          compact,
          start: getEventStart(entry.event),
          end: getEventEnd(entry.event),
        })}
      </div>
      {props.onEventResize &&
        (["start", "end"] as const).map((edge) => (
          <span
            key={edge}
            role="slider"
            tabIndex={0}
            aria-label={
              edge === "start" ? labels.resizeStart : labels.resizeEnd
            }
            aria-orientation={compact ? "horizontal" : "vertical"}
            aria-valuemin={edge === "end" ? slotNumber(entry.start) + step : 0}
            aria-valuemax={
              edge === "start" ? slotNumber(entry.end) - step : 5258964959
            }
            aria-valuenow={slotNumber(entry[edge])}
            aria-valuetext={`${entry[edge].date} ${Math.floor(entry[edge].minutes / 60)}:${String(entry[edge].minutes % 60).padStart(2, "0")}`}
            className={`k-calendar-resize k-calendar-resize-${edge} ${compact ? "k-calendar-resize-horizontal" : ""}`}
            onPointerDown={(e) => interaction.begin(e, entry, edge)}
            onKeyDown={(e) => {
              e.stopPropagation();
              const sign = ["ArrowUp", "ArrowLeft"].includes(e.key)
                ? -1
                : ["ArrowDown", "ArrowRight"].includes(e.key)
                  ? 1
                  : 0;
              if (!sign) return;
              e.preventDefault();
              interaction.change(
                "resize",
                entry,
                {
                  start: entry.start,
                  end: entry.end,
                  [edge]: shiftSlot(entry[edge], sign * step),
                },
                edge,
              );
            }}
          />
        ))}
    </div>
  );
}
