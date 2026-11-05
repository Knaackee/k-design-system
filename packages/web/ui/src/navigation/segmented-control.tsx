import { useRef, type HTMLAttributes, type KeyboardEvent } from "react";
import { useOptionalKHaptics } from "../feedback/haptics.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KText } from "../primitives/text.js";

export interface KSegment<T extends string = string> {
  value: T;
  label: string;
  icon?: KIconName;
}

export interface KSegmentedControlProps<T extends string = string> extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onChange"
> {
  segments: readonly KSegment<T>[];
  value: T;
  onValueChange: (value: T) => void;
  /** Accessible name of the group (for example "Period"). */
  label: string;
  disabled?: boolean;
}

/**
 * Two to five mutually exclusive options that switch a view or mode in place
 * (Apple segmented control). Not for navigation between screens and not for
 * actions. The selection slides with the `control` motion role; from 1.3×
 * text, three or more segments stack vertically.
 */
export function KSegmentedControl<T extends string = string>({
  segments,
  value,
  onValueChange,
  label,
  disabled = false,
  className,
  style,
  ...props
}: KSegmentedControlProps<T>) {
  const haptics = useOptionalKHaptics();
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  if (segments.length < 2 || segments.length > 5)
    console.error(
      "KSegmentedControl takes 2 to 5 segments (Apple HIG); use a select or tabs for more.",
    );
  const index = segments.findIndex((segment) => segment.value === value);
  const select = (next: number, focus = false) => {
    const segment = segments[next];
    if (!segment || disabled) return;
    if (focus) refs.current[next]?.focus();
    if (next === index) return;
    haptics?.perform("selection");
    onValueChange(segment.value);
  };
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const rtl = getComputedStyle(event.currentTarget).direction === "rtl";
    const step =
      event.key === "ArrowDown" ||
      event.key === (rtl ? "ArrowLeft" : "ArrowRight")
        ? 1
        : event.key === "ArrowUp" ||
            event.key === (rtl ? "ArrowRight" : "ArrowLeft")
          ? -1
          : 0;
    if (event.key === "Home") select(0, true);
    else if (event.key === "End") select(segments.length - 1, true);
    else if (step)
      select(
        (Math.max(index, 0) + step + segments.length) % segments.length,
        true,
      );
    else return;
    event.preventDefault();
  };
  return (
    <div
      role="radiogroup"
      aria-label={label}
      aria-disabled={disabled || undefined}
      className={["k-segmented-control", className].filter(Boolean).join(" ")}
      data-count={segments.length}
      data-stackable={segments.length >= 3 || undefined}
      style={
        {
          ...style,
          "--k-segment-count": segments.length,
          "--k-segment-index": Math.max(index, 0),
        } as never
      }
      onKeyDown={onKeyDown}
      {...props}
    >
      {index >= 0 ? (
        <span className="k-segmented-control__thumb" aria-hidden />
      ) : null}
      {segments.map((segment, i) => (
        <button
          key={segment.value}
          ref={(element) => {
            refs.current[i] = element;
          }}
          type="button"
          role="radio"
          aria-checked={i === index}
          tabIndex={i === Math.max(index, 0) ? 0 : -1}
          disabled={disabled}
          className="k-segmented-control__segment"
          data-selected={i === index || undefined}
          onClick={() => select(i)}
        >
          {segment.icon ? <KIcon name={segment.icon} size={16} /> : null}
          <KText
            as="span"
            variant="label"
            className="k-segmented-control__label"
          >
            {segment.label}
          </KText>
        </button>
      ))}
    </div>
  );
}
