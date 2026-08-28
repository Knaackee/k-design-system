// GENERATED FILE. DO NOT EDIT.
export const tokenNames = [
  "color.surface.canvas",
  "color.surface.raised",
  "color.text.primary",
  "color.text.muted",
  "color.border.default",
  "color.border.focus",
  "color.action.primary.background",
  "color.action.primary.hover",
  "color.action.primary.pressed",
  "color.action.primary.foreground",
  "space.controlGap",
  "space.controlInsetInline",
  "size.control",
  "radius.control",
  "font.family",
  "font.size",
  "font.weight",
  "motion.fast"
] as const;
export type KTokenName = (typeof tokenNames)[number];
export const cssVariable = (token: KTokenName): string => `--k-${token.replace(/\./g, "-").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()}`;
