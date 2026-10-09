import { forwardRef, type CSSProperties } from "react";
import { KButton, type KButtonProps } from "../primitives/button.js";

export interface KChatBubbleProps extends KButtonProps {
  /** Accessible action name, independent of the visual content. */
  label: string;
  size?: number;
  /** Keeps content mounted while a consumer waits for an animation to load. */
  visible?: boolean;
}

/** Presentation only. Position and chat state belong to the consumer. */
export const KChatBubble = forwardRef<HTMLButtonElement, KChatBubbleProps>(
  function KChatBubble(
    { label, size = 64, visible = true, className, style, children, ...props },
    ref,
  ) {
    return (
      <span
        className="k-chat-bubble-host"
        style={{ visibility: visible ? "visible" : "hidden" }}
      >
        <KButton
          variant="secondary"
          {...props}
          ref={ref}
          aria-label={label}
          className={["k-chat-bubble", className].filter(Boolean).join(" ")}
          style={
            { "--k-chat-bubble-size": `${size}px`, ...style } as CSSProperties
          }
        >
          {children}
        </KButton>
      </span>
    );
  },
);
