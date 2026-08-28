import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";

export interface KButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Shows progress and prevents additional activation. */
  loading?: boolean;
  children: ReactNode;
}

export const KButton = forwardRef<HTMLButtonElement, KButtonProps>(
  function KButton(
    {
      children,
      className,
      disabled,
      loading = false,
      type = "button",
      ...props
    },
    ref,
  ) {
    const classes = ["k-button", className].filter(Boolean).join(" ");

    return (
      <button
        {...props}
        ref={ref}
        type={type}
        className={classes}
        disabled={disabled || loading}
        aria-busy={loading || undefined}
      >
        {loading ? (
          <span className="k-button__spinner" aria-hidden="true" />
        ) : null}
        <span>{children}</span>
      </button>
    );
  },
);
