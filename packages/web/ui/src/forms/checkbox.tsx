import { useEffect, useRef, type InputHTMLAttributes } from "react";
import { KIcon } from "../primitives/icon.js";
export interface KCheckboxProps extends Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "type" | "checked" | "onChange" | "children" | "value"
> {
  label: string;
  value: boolean | null;
  onValueChange?: (value: boolean) => void;
}
export function KCheckbox({
  label,
  value,
  onValueChange,
  className = "",
  ...props
}: KCheckboxProps) {
  const ref = useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (ref.current) ref.current.indeterminate = value === null;
  }, [value]);
  return (
    <label className={`k-checkbox ${className}`}>
      <input
        {...props}
        ref={ref}
        type="checkbox"
        checked={value === true}
        onChange={(event) => onValueChange?.(event.target.checked)}
      />
      <span className="k-checkbox__box" aria-hidden="true">
        {value !== false && (
          <KIcon name={value === null ? "minus" : "check"} size={12} />
        )}
      </span>
      <span>{label}</span>
    </label>
  );
}
