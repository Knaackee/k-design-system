import { useEffect, useRef, type ReactNode } from "react";
import type { KDataTableDraftController } from "./data-table-draft.js";
const ownership = new WeakMap<Node, { controller: object; id: string }>();
function owner(target: EventTarget | null) {
  let node = target instanceof Node ? target : null;
  while (node) {
    const found = ownership.get(node);
    if (found) return found;
    node = node.parentNode;
  }
}
/** Wrap each cell (including its inline popover) with the same controller/row ID.
 * For portals or modal routes outside this DOM subtree use retainInteraction. */
export function KDataTableDraftInteraction<T>({
  controller,
  rowId,
  children,
  keyboardActions = true,
}: {
  controller: KDataTableDraftController<T>;
  rowId: string;
  children: ReactNode;
  keyboardActions?: boolean;
}) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const element = ref.current!;
    ownership.set(element, { controller, id: rowId });
    let frame = 0;
    const schedule = (target: EventTarget | null) => {
      cancelAnimationFrame(frame);
      const next = owner(target);
      if (next?.controller === controller && next.id === rowId) {
        cancelAnimationFrame(frame);
        return;
      }
      frame = requestAnimationFrame(() => {
        const active = owner(document.activeElement);
        if (active?.controller === controller && active.id === rowId)
          cancelAnimationFrame(frame);
        else controller.leave(rowId);
      });
    };
    const focus = (e: FocusEvent) => schedule(e.target);
    const pointer = (e: PointerEvent) => {
      // A nonfocusable outside target still ends the row interaction.
      const next = owner(e.target);
      if (next?.controller === controller && next.id === rowId)
        cancelAnimationFrame(frame);
      else {
        cancelAnimationFrame(frame);
        frame = requestAnimationFrame(() => controller.leave(rowId));
      }
    };
    document.addEventListener("focusin", focus, true);
    document.addEventListener("pointerdown", pointer, true);
    return () => {
      cancelAnimationFrame(frame);
      ownership.delete(element);
      document.removeEventListener("focusin", focus, true);
      document.removeEventListener("pointerdown", pointer, true);
    };
  }, [controller, rowId]);
  return (
    <div
      ref={ref}
      style={{ display: "contents" }}
      onKeyDown={(event) => {
        if (
          !keyboardActions ||
          event.defaultPrevented ||
          event.nativeEvent.isComposing ||
          !controller.get(rowId)
        )
          return;
        if (event.key === "Escape") {
          event.preventDefault();
          event.stopPropagation();
          controller.cancel(rowId, "escape");
        } else if (event.key === "Enter") {
          event.preventDefault();
          event.stopPropagation();
          void controller.commit(rowId, "enter");
        }
      }}
    >
      {children}
    </div>
  );
}
