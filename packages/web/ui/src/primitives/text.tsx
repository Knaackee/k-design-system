import { createElement, type HTMLAttributes, type ReactNode } from "react";

export type KTextVariant =
  | "heading1"
  | "heading2"
  | "heading3"
  | "heading4"
  | "heading5"
  | "heading6"
  | "body"
  | "bodySmall"
  | "label"
  | "caption";

export type KTextElement =
  "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "p" | "span" | "div";

export interface KTextProps extends HTMLAttributes<HTMLElement> {
  as?: KTextElement;
  children: ReactNode;
  variant?: KTextVariant;
}

const defaultElements: Record<KTextVariant, KTextElement> = {
  heading1: "h1",
  heading2: "h2",
  heading3: "h3",
  heading4: "h4",
  heading5: "h5",
  heading6: "h6",
  body: "p",
  bodySmall: "p",
  label: "span",
  caption: "span",
};

const variantClasses: Record<KTextVariant, string> = {
  heading1: "heading1",
  heading2: "heading2",
  heading3: "heading3",
  heading4: "heading4",
  heading5: "heading5",
  heading6: "heading6",
  body: "body",
  bodySmall: "body-small",
  label: "label",
  caption: "caption",
};

export function KText({
  as,
  children,
  className,
  variant = "body",
  ...props
}: KTextProps) {
  const element = as ?? defaultElements[variant];
  const classes = ["k-text", `k-text--${variantClasses[variant]}`, className]
    .filter(Boolean)
    .join(" ");

  return createElement(
    element,
    { ...props, className: classes, "data-variant": variant },
    children,
  );
}
