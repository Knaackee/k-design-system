import { useEffect, useRef, useState, type ReactNode } from "react";
import { KPopover } from "../extended-components.js";

/** Optional, read-only information supplied by the workspace consumer. */
export function AgentAvatarInfo({
  avatar,
  label,
  content,
  accessibleLabel,
}: {
  avatar: ReactNode;
  label?: ReactNode;
  content?: ReactNode;
  accessibleLabel: string;
}) {
  const [open, setOpen] = useState(false);
  const anchorRef = useRef<HTMLDivElement>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const origin = useRef<{ x: number; y: number } | undefined>(undefined);
  const clear = () => {
    clearTimeout(timer.current);
    timer.current = undefined;
  };
  useEffect(() => clear, []);
  return (
    <div
      className="k-agent-chat-workspace__avatar-info"
      onKeyDown={(event) => {
        if (open && event.key === "Escape") {
          setOpen(false);
          event.stopPropagation();
        }
      }}
    >
      <div ref={anchorRef} className="k-agent-chat-workspace__avatar">
        {content ? (
          <KPopover
            portal
            showArrow
            anchorRef={anchorRef}
            open={open}
            onOpenChange={setOpen}
            label={accessibleLabel}
            trigger={
              <button
                type="button"
                className="k-agent-chat-workspace__avatar-trigger"
                aria-label={accessibleLabel}
                aria-haspopup="dialog"
                onPointerDown={(event) => {
                  if (event.button !== 0 || !event.isPrimary) return;
                  clear();
                  origin.current = { x: event.clientX, y: event.clientY };
                  timer.current = setTimeout(() => {
                    setOpen(true);
                  }, 500);
                }}
                onPointerMove={(event) => {
                  if (
                    origin.current &&
                    Math.hypot(
                      event.clientX - origin.current.x,
                      event.clientY - origin.current.y,
                    ) > 8
                  )
                    clear();
                }}
                onPointerUp={clear}
                onPointerCancel={clear}
                onPointerLeave={clear}
                onContextMenu={(event) => event.preventDefault()}
                onClickCapture={(event) => {
                  if (event.detail > 0) {
                    event.stopPropagation();
                    event.preventDefault();
                  }
                }}
              >
                {avatar}
              </button>
            }
          >
            {content}
          </KPopover>
        ) : (
          avatar
        )}
      </div>
      {label ? (
        content ? (
          <button
            type="button"
            className="k-agent-chat-workspace__avatar-label"
            aria-label={accessibleLabel}
            aria-haspopup="dialog"
            aria-expanded={open}
            onPointerDown={(event) => event.stopPropagation()}
            onClick={() => setOpen(!open)}
          >
            {label}
          </button>
        ) : (
          <span className="k-agent-chat-workspace__avatar-label">{label}</span>
        )
      ) : null}
    </div>
  );
}
