import { forwardRef, type AnchorHTMLAttributes, type ReactNode } from "react";
import { KIcon } from "./icon.js";

export type KLinkVariant = "inline" | "standalone";
export type KLinkAppearance = "default" | "subtle";

export interface KLinkProps extends Omit<
  AnchorHTMLAttributes<HTMLAnchorElement>,
  "href"
> {
  href: string;
  leading?: ReactNode;
  trailing?: ReactNode;
  external?: boolean;
  variant?: KLinkVariant;
  appearance?: KLinkAppearance;
}

export const KLink = forwardRef<HTMLAnchorElement, KLinkProps>(function KLink(
  {
    children,
    className,
    external = false,
    leading,
    rel,
    target,
    trailing,
    variant = "inline",
    appearance = "default",
    ...props
  },
  ref,
) {
  const resolvedTarget = target ?? (external ? "_blank" : undefined);
  const resolvedRel = external
    ? [rel, "noopener", "noreferrer"].filter(Boolean).join(" ")
    : rel;
  return (
    <a
      {...props}
      ref={ref}
      className={[
        "k-link",
        `k-link--${variant}`,
        appearance === "subtle" && "k-link--subtle",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      target={resolvedTarget}
      rel={resolvedRel}
    >
      {leading}
      <span>{children}</span>
      {trailing ?? (external ? <KIcon name="external-link" /> : null)}
    </a>
  );
});
