import { forwardRef, type TextareaHTMLAttributes } from "react";
import { useField } from "./field.js";

export type KTextareaProps = TextareaHTMLAttributes<HTMLTextAreaElement>;

/** Plain multiline text. Native form values, validation and keyboard behavior. */
export const KTextarea = forwardRef<HTMLTextAreaElement, KTextareaProps>(
  function KTextarea({ className = "", rows = 4, ...props }, ref) {
    const field = useField();
    return (
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
  },
);
