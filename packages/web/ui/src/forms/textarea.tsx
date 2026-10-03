import {
  forwardRef,
  useRef,
  useImperativeHandle,
  type ReactNode,
  type TextareaHTMLAttributes,
} from "react";
import { useField } from "./field.js";

import { KDictationState } from "./dictation-action.js";
import { KDictationFieldAnchor } from "./dictation-anchor.js";
export interface KTextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  /** A bottom end action, hidden for disabled or read-only text. */
  trailingAction?: ReactNode;
  dictationState?: KDictationState;
  /** Saved UTF-16 insertion offset; defaults to the current caret. */
  dictationOffset?: number;
}

/** Plain multiline text. Native form values, validation and keyboard behavior. */
export const KTextarea = forwardRef<HTMLTextAreaElement, KTextareaProps>(
  function KTextarea(
    {
      className = "",
      rows = 4,
      trailingAction,
      dictationState,
      dictationOffset,
      ...props
    },
    ref,
  ) {
    const field = useField();
    const input = useRef<HTMLTextAreaElement>(null);
    useImperativeHandle(ref, () => input.current!, []);
    const showAnchor =
      !props.disabled &&
      !props.readOnly &&
      (dictationState === KDictationState.recording ||
        dictationState === KDictationState.processing);
    const action = !props.disabled && !props.readOnly ? trailingAction : null;
    const textarea = (
      <textarea
        id={field.id}
        aria-describedby={field.description}
        aria-invalid={field.invalid || undefined}
        required={field.required}
        {...props}
        ref={input}
        rows={rows}
        className={`k-input k-textarea ${className}`}
      />
    );
    return action || showAnchor ? (
      <span
        className="k-textarea-target"
        data-trailing-action={action ? true : undefined}
      >
        {textarea}
        {showAnchor && (
          <KDictationFieldAnchor
            target={input}
            offset={dictationOffset}
            state={dictationState!}
          />
        )}
        {action && <span className="k-textarea-trailing-action">{action}</span>}
      </span>
    ) : (
      textarea
    );
  },
);
