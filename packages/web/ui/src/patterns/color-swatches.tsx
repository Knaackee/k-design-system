import { useRef, type CSSProperties } from "react";
import { KIcon } from "../primitives/icon.js";

export interface KColorSwatch {
  value: string;
  label: string;
  /** A host-owned brand colour or gradient; defaults to value. */
  background?: string;
  foreground?: string;
}
export interface KColorSwatchesProps {
  options: readonly KColorSwatch[];
  value: string;
  onValueChange: (value: string) => void;
  label: string;
  disabled?: boolean;
}

/** Named colour choices with one keyboard tab stop and arrow-key selection. */
export function KColorSwatches({
  options,
  value,
  onValueChange,
  label,
  disabled = false,
}: KColorSwatchesProps) {
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const selected = options.findIndex((option) => option.value === value);
  return (
    <div
      className="k-color-swatches"
      role="radiogroup"
      aria-label={label}
      aria-disabled={disabled || undefined}
    >
      {options.map((option, index) => (
        <button
          key={option.value}
          type="button"
          role="radio"
          aria-checked={option.value === value}
          aria-label={option.label}
          title={option.label}
          disabled={disabled}
          tabIndex={index === Math.max(0, selected) ? 0 : -1}
          ref={(node) => {
            refs.current[index] = node;
          }}
          style={
            {
              "--k-swatch-color": option.background ?? option.value,
              "--k-swatch-foreground": option.foreground,
            } as CSSProperties
          }
          onClick={() => onValueChange(option.value)}
          onKeyDown={(event) => {
            if (disabled) return;
            const rtl =
              getComputedStyle(event.currentTarget).direction === "rtl";
            const step =
              event.key === "ArrowDown" ||
              event.key === (rtl ? "ArrowLeft" : "ArrowRight")
                ? 1
                : event.key === "ArrowUp" ||
                    event.key === (rtl ? "ArrowRight" : "ArrowLeft")
                  ? -1
                  : 0;
            if (!step && event.key !== "Home" && event.key !== "End") return;
            event.preventDefault();
            const next =
              event.key === "Home"
                ? 0
                : event.key === "End"
                  ? options.length - 1
                  : (index + step + options.length) % options.length;
            onValueChange(options[next].value);
            refs.current[next]?.focus();
          }}
        >
          <span>
            {option.value === value && <KIcon name="check" size={16} />}
          </span>
        </button>
      ))}
    </div>
  );
}
