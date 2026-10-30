import { useKLocalization } from "../localization/provider.js";
import {
  forwardRef,
  useImperativeHandle,
  useEffect,
  useRef,
  useState,
  type ReactNode,
  type InputHTMLAttributes,
} from "react";
import { KIcon } from "../primitives/icon.js";
import { useField } from "./field.js";
import { ClearButton } from "./clear-button.js";
import { KDictationState } from "./dictation-action.js";
import { KDictationFieldAnchor } from "./dictation-anchor.js";
export interface KInputProps extends Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "size"
> {
  /** Decorative leading content inside the input, matching Flutter KInput. */
  leading?: ReactNode;
  /** An end action, hidden for disabled, read-only or password input. */
  trailingAction?: ReactNode;
  dictationState?: KDictationState;
  /** Saved UTF-16 insertion offset; defaults to the current caret. */
  dictationOffset?: number;
  clearable?: boolean;
  clearLabel?: string;
  /** Update the application value when a controlled input is cleared. */
  onClear?: () => void;
}
export const KInput = forwardRef<HTMLInputElement, KInputProps>(function KInput(
  {
    className = "",
    leading,
    clearable = false,
    clearLabel,
    onClear,
    trailingAction,
    dictationState,
    dictationOffset,
    value,
    defaultValue,
    onChange,
    ...props
  }: KInputProps,
  ref,
) {
  const { messages } = useKLocalization();
  const field = useField();
  const input = useRef<HTMLInputElement>(null);
  useImperativeHandle(ref, () => input.current!, []);
  const [localValue, setLocalValue] = useState(defaultValue ?? "");
  useEffect(() => {
    const form = input.current?.form;
    const reset = () =>
      queueMicrotask(() => setLocalValue(input.current?.value ?? ""));
    form?.addEventListener("reset", reset);
    return () => form?.removeEventListener("reset", reset);
  });
  const current = value ?? localValue;
  const canClear =
    clearable &&
    String(current).length > 0 &&
    !props.disabled &&
    !props.readOnly &&
    (value === undefined || !!onClear);
  const action =
    !props.disabled && !props.readOnly && props.type !== "password"
      ? trailingAction
      : null;
  const showAnchor =
    !props.disabled &&
    !props.readOnly &&
    props.type !== "password" &&
    (dictationState === KDictationState.recording ||
      dictationState === KDictationState.processing);
  return (
    <span
      className="k-input-target k-input-clearable"
      data-clearable={canClear || undefined}
      data-trailing-action={action ? true : undefined}
      data-leading={leading ? true : undefined}
    >
      {leading && (
        <span className="k-input-leading" aria-hidden="true">
          {leading}
        </span>
      )}
      <input
        id={field.id}
        aria-describedby={field.description}
        aria-invalid={field.invalid || undefined}
        required={field.required}
        {...props}
        ref={input}
        value={value}
        defaultValue={defaultValue}
        onChange={(event) => {
          setLocalValue(event.target.value);
          onChange?.(event);
        }}
        className={`k-input ${className}`}
      />
      {showAnchor && (
        <KDictationFieldAnchor
          target={input}
          offset={dictationOffset}
          state={dictationState!}
        />
      )}
      {action && <span className="k-input-trailing-action">{action}</span>}
      {canClear && (
        <ClearButton
          label={clearLabel ?? messages.clear}
          onClear={() => {
            if (value === undefined && input.current) input.current.value = "";
            setLocalValue("");
            onClear?.();
            input.current?.focus();
          }}
        />
      )}
    </span>
  );
});
export function KSearchField(props: KInputProps) {
  return (
    <span className="k-search-field">
      <KIcon name="search" />
      <KInput type="search" {...props} />
    </span>
  );
}
