import { useLayoutEffect, useRef, type ReactNode } from "react";
export interface KEditableCellProps {
  /** Accessible action name, supplied by the consumer. */
  label: string;
  display: ReactNode;
  editor: ReactNode;
  editing?: boolean;
  /** Inline inset of the resting trigger; its minimum hit height is unchanged. */
  paddingInline?: number;
  /** Omit for a read-only display. Editor owns validation and commit/cancel. */
  onEdit?: () => void;
}
/** A controlled display/editor slot; it never owns or persists a cell value. */
export function KEditableCell({
  label,
  display,
  editor,
  editing = false,
  paddingInline,
  onEdit,
}: KEditableCellProps) {
  const editorRoot = useRef<HTMLDivElement>(null);
  const outsidePointer = useRef(false);
  const trigger = useRef<HTMLButtonElement>(null);
  const previous = useRef(editing);
  const blurTarget = useRef<HTMLElement | null>(null);
  useLayoutEffect(() => {
    if (
      previous.current &&
      !editing &&
      document.activeElement === document.body
    )
      (blurTarget.current?.isConnected
        ? blurTarget.current
        : outsidePointer.current
          ? null
          : trigger.current
      )?.focus();
    if (!previous.current && editing) {
      blurTarget.current = null;
      outsidePointer.current = false;
    }
    previous.current = editing;
  }, [editing]);
  useLayoutEffect(() => {
    if (!editing) return;
    const outside = (event: PointerEvent) => {
      if (
        event.target instanceof Node &&
        !editorRoot.current?.contains(event.target)
      )
        outsidePointer.current = true;
    };
    document.addEventListener("pointerdown", outside, true);
    return () => document.removeEventListener("pointerdown", outside, true);
  }, [editing]);
  if (
    paddingInline !== undefined &&
    (!Number.isFinite(paddingInline) || paddingInline < 0)
  )
    throw new RangeError(
      "KEditableCell paddingInline must be finite and nonnegative",
    );
  if (!label.trim())
    throw new Error("KEditableCell requires an accessible label");
  if (editing)
    return (
      <div
        ref={editorRoot}
        style={{ display: "contents" }}
        onBlurCapture={(event) => {
          blurTarget.current =
            event.relatedTarget instanceof HTMLElement
              ? event.relatedTarget
              : null;
        }}
      >
        {editor}
      </div>
    );
  return onEdit ? (
    <button
      ref={trigger}
      type="button"
      className="k-editable-cell"
      style={{ paddingInline }}
      aria-label={label}
      onClick={onEdit}
    >
      {display}
    </button>
  ) : (
    <>{display}</>
  );
}
