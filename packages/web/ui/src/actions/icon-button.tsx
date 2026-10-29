import { forwardRef } from "react";
import { KButton, type KButtonProps } from "../primitives/button.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export interface KIconButtonProps extends Omit<KButtonProps, "children"> {
  icon: KIconName;
  label: string;
  strokeWidth?: number;
}

export const KIconButton = forwardRef<HTMLButtonElement, KIconButtonProps>(
  function KIconButton(
    {
      icon,
      label,
      className = "",
      variant = "ghost",
      loading = false,
      strokeWidth,
      ...props
    },
    ref,
  ) {
    return (
      <KButton
        {...props}
        ref={ref}
        loading={loading}
        variant={variant}
        aria-label={label}
        title={label}
        className={`k-icon-button ${className}`}
      >
        {loading ? null : (
          <KIcon name={icon} color="currentColor" strokeWidth={strokeWidth} />
        )}
      </KButton>
    );
  },
);
