import { useRef, useState } from "react";

export function useZoneEditorTransition(dirty: boolean) {
  const [open, setOpen] = useState(false);
  const pending = useRef<(() => void) | null>(null);
  return {
    open,
    hasPending: () => pending.current !== null,
    request: (transition: () => void) => {
      if (!dirty) return transition();
      pending.current = transition;
      setOpen(true);
    },
    continueEditing: () => {
      pending.current = null;
      setOpen(false);
    },
    run: () => {
      const transition = pending.current;
      pending.current = null;
      setOpen(false);
      transition?.();
    },
    close: () => setOpen(false),
  };
}
