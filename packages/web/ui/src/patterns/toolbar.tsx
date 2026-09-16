import { useLayoutEffect, useRef, type ReactNode } from "react";

export interface KToolbarProps {
  label: string;
  children: ReactNode;
}

/** Action-only toolbar: wraps without hiding actions; one tab stop. */
export function KToolbar({ label, children }: KToolbarProps) {
  const root = useRef<HTMLDivElement>(null);
  const controls = () =>
    Array.from(
      root.current?.querySelectorAll<HTMLButtonElement>(
        "button:not(:disabled)",
      ) ?? [],
    ).filter((button) => !button.closest('[role="menu"]'));
  useLayoutEffect(() => {
    function update() {
      const buttons = controls();
      const active =
        buttons.find((button) => button === document.activeElement) ??
        buttons.find((button) => button.tabIndex === 0) ??
        buttons[0];
      buttons.forEach(
        (button) => (button.tabIndex = button === active ? 0 : -1),
      );
    }
    update();
    const observer = new MutationObserver(update);
    if (root.current)
      observer.observe(root.current, {
        subtree: true,
        childList: true,
        attributes: true,
        attributeFilter: ["disabled"],
      });
    return () => observer.disconnect();
  });
  return (
    <div
      ref={root}
      role="toolbar"
      aria-label={label}
      aria-orientation="horizontal"
      className="k-toolbar"
      onFocus={(event) => {
        const buttons = controls();
        const target: EventTarget = event.target;
        if (target instanceof HTMLButtonElement && buttons.includes(target))
          buttons.forEach(
            (button) => (button.tabIndex = button === target ? 0 : -1),
          );
      }}
      onKeyDown={(event) => {
        if ((event.target as HTMLElement).closest('[role="menu"]')) return;
        const buttons = controls();
        const index = buttons.indexOf(
          document.activeElement as HTMLButtonElement,
        );
        if (index < 0) return;
        const rtl = getComputedStyle(root.current!).direction === "rtl";
        const delta = (event.key === "ArrowRight" ? 1 : -1) * (rtl ? -1 : 1);
        const next =
          event.key === "Home"
            ? 0
            : event.key === "End"
              ? buttons.length - 1
              : ["ArrowRight", "ArrowLeft"].includes(event.key)
                ? (index + delta + buttons.length) % buttons.length
                : undefined;
        if (next !== undefined) {
          event.preventDefault();
          buttons[next]?.focus();
        }
      }}
    >
      {children}
    </div>
  );
}
