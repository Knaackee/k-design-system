import { forwardRef, type ReactNode, type TextareaHTMLAttributes } from "react";
import { useField } from "./field.js";

export interface KTextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  /** A bottom end action, hidden for disabled or read-only text. */
  trailingAction?: ReactNode;
}

/** Plain multiline text. Native form values, validation and keyboard behavior. */
export const KTextarea = forwardRef<HTMLTextAreaElement, KTextareaProps>(
  function KTextarea(
    { className = "", rows = 4, trailingAction, ...props },
    ref,
  ) {
    const field = useField();
    const action = !props.disabled && !props.readOnly ? trailingAction : null;
    const textarea = (
      <textarea
        id={field.id}
        aria-describedby={field.description}
        aria-invalid={field.invalid || undefined}
        required={field.required}
        {...props}
        ref={ref}
        rows={rows}
        className={`k-input k-textarea ${className}`}
      />
    );
    return action ? (
      <span className="k-textarea-target">
        {textarea}
        <span className="k-textarea-trailing-action">{action}</span>
      </span>
    ) : (
      textarea
    );
  },
);
