import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export interface KSymbolPickerAnchorProps {
  triggerLabel?: string;
  triggerContent?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}
export function SymbolPickerPopover({
  label,
  icon,
  triggerContent,
  open,
  onOpenChange,
  disabled,
  children,
}: KSymbolPickerAnchorProps & {
  label: string;
  icon: KIconName;
  disabled?: boolean;
  children: (close: () => void) => ReactNode;
}) {
  const id = useId();
  const panel = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const [localOpen, setOpen] = useState(false);
  const expanded = !disabled && (open ?? localOpen);
  function change(next: boolean) {
    if (open === undefined) setOpen(next);
    onOpenChange?.(next);
    if (!next) trigger.current?.focus();
  }
  useEffect(() => {
    const node = panel.current,
      button = trigger.current;
    if (!node || !button) return;
    if (!expanded) {
      if (node.matches(":popover-open")) node.hidePopover();
      return;
    }
    if (!node.matches(":popover-open")) node.showPopover();
    function position() {
      if (!node || !button) return;
      const anchor = (
        button.closest(".k-button-target") ?? button
      ).getBoundingClientRect();
      const bounds = node.getBoundingClientRect();
      node.style.left = `${Math.max(8, Math.min(anchor.left, innerWidth - bounds.width - 8))}px`;
      const y =
        anchor.bottom + 4 + bounds.height <= innerHeight - 8
          ? anchor.bottom + 4
          : anchor.top - bounds.height - 4;
      node.style.top = `${Math.max(8, Math.min(y, innerHeight - bounds.height - 8))}px`;
    }
    position();
    node.querySelector<HTMLInputElement>("input")?.focus();
    const observer = new ResizeObserver(position);
    observer.observe(node);
    window.addEventListener("resize", position);
    window.addEventListener("scroll", position, true);
    return () => {
      observer.disconnect();
      window.removeEventListener("resize", position);
      window.removeEventListener("scroll", position, true);
    };
  }, [expanded]);
  return (
    <>
      <KButton
        ref={trigger}
        variant="ghost"
        className="k-icon-button"
        disabled={disabled}
        aria-label={label}
        title={label}
        aria-haspopup="dialog"
        aria-expanded={expanded}
        aria-controls={id}
        onClick={() => change(!expanded)}
      >
        {triggerContent ?? <KIcon name={icon} />}
      </KButton>
      <div
        id={id}
        ref={panel}
        className="k-symbol-popover"
        popover="auto"
        role="dialog"
        aria-label={label}
        onToggle={(e) => {
          if (e.newState === "closed" && expanded) change(false);
        }}
      >
        {children(() => change(false))}
      </div>
    </>
  );
}
