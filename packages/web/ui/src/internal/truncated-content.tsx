import { useEffect, useRef, useState, type ReactNode } from "react";

/** Keeps the original content and accessible name; reveals clipped text in the top layer. */
export function TruncatedContent({ children }: { children: ReactNode }) {
  const content = useRef<HTMLSpanElement>(null);
  const hint = useRef<HTMLSpanElement>(null);
  const [clipped, setClipped] = useState(false);
  const [interactive, setInteractive] = useState(false);
  const [open, setOpen] = useState(false);
  const [text, setText] = useState("");
  useEffect(() => {
    const node = content.current;
    if (!node) return;
    const measure = () => {
      setClipped(node.scrollWidth > node.clientWidth + 1);
      setInteractive(
        !!node.closest("button, a, [role=button]") ||
          !!node.querySelector(
            "button, a, input, select, textarea, [tabindex]",
          ),
      );
      setText(node.textContent ?? "");
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(node);
    const control = node.closest("button, a, [role=button]");
    const show = () => setOpen(true);
    const hide = () => setOpen(false);
    control?.addEventListener("focus", show);
    control?.addEventListener("blur", hide);
    return () => {
      observer.disconnect();
      control?.removeEventListener("focus", show);
      control?.removeEventListener("blur", hide);
    };
  }, [children]);
  useEffect(() => {
    const popup = hint.current;
    const node = content.current;
    if (!popup || !node) return;
    if (!open || !clipped) {
      if (popup.matches(":popover-open")) popup.hidePopover();
      return;
    }
    popup.showPopover();
    const anchor = node.getBoundingClientRect();
    const bounds = popup.getBoundingClientRect();
    popup.style.left = `${Math.max(0, Math.min(anchor.left, innerWidth - bounds.width))}px`;
    popup.style.top = `${Math.max(0, anchor.bottom + bounds.height <= innerHeight ? anchor.bottom : anchor.top - bounds.height)}px`;
    const close = () => setOpen(false);
    const escape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpen(false);
        event.preventDefault();
        event.stopPropagation();
      }
    };
    document.addEventListener("keydown", escape, true);
    window.addEventListener("scroll", close, true);
    window.addEventListener("resize", close);
    return () => {
      window.removeEventListener("scroll", close, true);
      window.removeEventListener("resize", close);
      document.removeEventListener("keydown", escape, true);
    };
  }, [open, clipped]);
  return (
    <span
      className="k-truncated"
      tabIndex={clipped && !interactive ? 0 : undefined}
      onPointerEnter={() => setOpen(true)}
      onPointerLeave={() => setOpen(false)}
      onFocus={() => setOpen(true)}
      onBlur={() => setOpen(false)}
      onKeyDown={(event) => {
        if (event.key === "Escape" && open) {
          setOpen(false);
          event.stopPropagation();
        }
      }}
    >
      <span ref={content} className="k-truncated__content">
        {children}
      </span>
      {clipped ? (
        <span
          ref={hint}
          popover="manual"
          role="tooltip"
          aria-hidden="true"
          className="k-truncated__hint"
        >
          {text}
        </span>
      ) : null}
    </span>
  );
}
