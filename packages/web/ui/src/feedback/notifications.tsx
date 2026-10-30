import { Children, useEffect, useRef, useState, type ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";

export type KNotificationTone = "neutral" | "success" | "warning" | "error";
export interface KNotificationOptions {
  icon?: ReactNode;
  action?: ReactNode;
  onDismiss?: () => void;
  dismissLabel?: string;
  tone?: KNotificationTone;
  /** Milliseconds until dismissal; 0 keeps the notification persistent. */
  duration?: number;
}
export interface KToastProps extends KNotificationOptions {
  title: ReactNode;
  description?: ReactNode;
}
export interface KSnackbarProps extends KNotificationOptions {
  message: ReactNode;
}

function Notification({
  title,
  description,
  icon,
  action,
  onDismiss,
  dismissLabel = "Dismiss",
  tone = "neutral",
  duration = 0,
  compact = false,
}: KToastProps & { compact?: boolean }) {
  const callback = useRef(onDismiss);
  callback.current = onDismiss;
  const dismissed = useRef(false);
  const remaining = useRef(duration);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const dismiss = () => {
    if (dismissed.current) return;
    dismissed.current = true;
    callback.current?.();
  };
  useEffect(() => {
    remaining.current = duration;
  }, [duration]);
  useEffect(() => {
    if (!onDismiss || duration <= 0 || hovered || focused || dismissed.current)
      return;
    const start = Date.now();
    const timer = window.setTimeout(dismiss, Math.max(0, remaining.current));
    return () => {
      window.clearTimeout(timer);
      remaining.current = Math.max(0, remaining.current - (Date.now() - start));
    };
  }, [duration, hovered, focused, !!onDismiss]);
  return (
    <div
      className={`k-toast${compact ? " k-snackbar" : ""}`}
      data-tone={tone}
      role={tone === "error" ? "alert" : "status"}
      aria-atomic="true"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocusCapture={() => setFocused(true)}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget))
          setFocused(false);
      }}
    >
      {icon ? <span className="k-toast__icon">{icon}</span> : null}
      <div className="k-toast__content">
        {compact ? (
          <span className="k-snackbar__message">{title}</span>
        ) : (
          <strong>{title}</strong>
        )}
        {description ? <span>{description}</span> : null}
      </div>
      {action ? <span className="k-toast__action">{action}</span> : null}
      {onDismiss ? (
        <KIconButton icon="x" label={dismissLabel} onClick={dismiss} />
      ) : null}
    </div>
  );
}
export function KToast(props: KToastProps) {
  return <Notification {...props} />;
}
export function KSnackbar({ message, ...props }: KSnackbarProps) {
  return <Notification {...props} title={message} compact />;
}
export interface KToastViewportProps {
  bottomOffset?: number;
  children: ReactNode;
  label?: string;
  /** Occupied height in CSS pixels, including exit motion; zero once cleared. */
  onHeightChange?: (height: number) => void;
  position?: "bottom-end" | "top-end" | "bottom-center";
}
/** Non-modal overlay. Mount inside the application's theme provider. */
export function KToastViewport({
  children,
  label = "Notifications",
  onHeightChange,
  position = "bottom-end",
  bottomOffset,
}: KToastViewportProps) {
  const visible = Children.toArray(children).length > 0;
  const [retained, setRetained] = useState(children);
  const viewport = useRef<HTMLElement>(null);
  const heightCallback = useRef(onHeightChange);
  heightCallback.current = onHeightChange;
  useEffect(() => {
    const element = viewport.current;
    if (!element) return;
    const report = () =>
      heightCallback.current?.(element.getBoundingClientRect().height);
    report();
    const observer = new ResizeObserver(report);
    observer.observe(element);
    return () => {
      observer.disconnect();
      heightCallback.current?.(0);
    };
  }, []);

  useEffect(() => {
    if (visible) {
      setRetained(children);
      return;
    }
    const durations = viewport.current
      ? getComputedStyle(viewport.current).transitionDuration.split(",")
      : [];
    const milliseconds = Math.max(
      0,
      ...durations.map(
        (value) => parseFloat(value) * (value.trim().endsWith("ms") ? 1 : 1000),
      ),
    );
    const timer = window.setTimeout(() => setRetained(null), milliseconds);
    return () => window.clearTimeout(timer);
  }, [visible, children]);
  return (
    <section
      ref={viewport}
      style={
        bottomOffset === undefined
          ? undefined
          : { bottom: `max(${bottomOffset}px, env(safe-area-inset-bottom))` }
      }
      className="k-toast-viewport"
      data-visible={visible || undefined}
      inert={!visible}
      aria-hidden={!visible}
      data-position={position}
      aria-label={label}
    >
      {visible ? children : retained}
    </section>
  );
}
