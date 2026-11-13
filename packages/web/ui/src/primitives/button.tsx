import {
  Children,
  forwardRef,
  type ButtonHTMLAttributes,
  type ReactNode,
} from "react";
import { TruncatedContent } from "../internal/truncated-content.js";

export type KButtonVariant = "primary" | "secondary" | "ghost";

export interface KButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Shows progress and prevents additional activation. */
  loading?: boolean;
  /** Fill the parent width: a call to action with a centred label. */
  fullWidth?: boolean;
  /** Semantic visual role. */
  variant?: KButtonVariant;
  /** Destructive confirmation; preserves the variant's shape and target size. */
  tone?: "default" | "destructive";
  children: ReactNode;
}

export const KButton = forwardRef<HTMLButtonElement, KButtonProps>(
  function KButton(
    {
      children,
      className,
      disabled,
      loading = false,
      fullWidth = false,
      variant = "primary",
      tone = "default",
      type = "button",
      ...props
    },
    ref,
  ) {
    const classes = ["k-button", `k-button--${variant}`, className]
      .filter(Boolean)
      .join(" ");

    return (
      <span
        className={`k-button-target${fullWidth ? " k-button-target--full-width" : ""}`}
      >
        <button
          {...props}
          ref={ref}
          type={type}
          className={classes}
          data-variant={variant}
          data-tone={tone === "default" ? undefined : tone}
          disabled={disabled || loading}
          aria-busy={loading || undefined}
        >
          {loading ? (
            <span className="k-button__spinner" aria-hidden="true" />
          ) : null}
          <span className="k-button__content">
            {Children.map(children, (child) => (
              <TruncatedContent>{child}</TruncatedContent>
            ))}
          </span>
        </button>
      </span>
    );
  },
);

// A stable name: page headers and rows recognise it across bundles.
KButton.displayName = "KButton";
