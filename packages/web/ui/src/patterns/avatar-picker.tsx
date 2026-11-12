import type { ReactNode } from "react";
import { useKLocalization } from "../localization/provider.js";
import { KText } from "../primitives/text.js";

/** One shape; the app draws the icon, so its own avatars stay its own. */
export interface KAvatarShape {
  id: string;
  label: string;
  icon: ReactNode;
}

export interface KAvatarColor {
  value: string;
  label: string;
}

export interface KAvatarPickerProps {
  shapes: readonly KAvatarShape[];
  colors: readonly KAvatarColor[];
  shape: string;
  color: string;
  onShapeChange: (id: string) => void;
  onColorChange: (value: string) => void;
  className?: string;
}

/** Shape and colour of an avatar (Decision 0017). */
export function KAvatarPicker({
  shapes,
  colors,
  shape,
  color,
  onShapeChange,
  onColorChange,
  className,
}: KAvatarPickerProps) {
  const { messages } = useKLocalization();
  return (
    <div className={["k-avatar-picker", className].filter(Boolean).join(" ")}>
      <KText as="p" variant="label" className="k-avatar-picker__label">
        {messages.avatarShape}
      </KText>
      <div
        className="k-avatar-picker__shapes"
        role="group"
        aria-label={messages.avatarShape}
      >
        {shapes.map((option) => (
          <button
            key={option.id}
            type="button"
            className="k-avatar-picker__shape"
            aria-pressed={option.id === shape}
            onClick={() => onShapeChange(option.id)}
          >
            <span className="k-avatar-picker__icon" aria-hidden>
              {option.icon}
            </span>
            <KText as="span" variant="caption">
              {option.label}
            </KText>
          </button>
        ))}
      </div>
      <KText as="p" variant="label" className="k-avatar-picker__label">
        {messages.avatarColor}
      </KText>
      <div
        className="k-avatar-picker__colors"
        role="group"
        aria-label={messages.avatarColor}
      >
        {colors.map((option) => (
          <button
            key={option.value}
            type="button"
            className="k-avatar-picker__color"
            style={{ background: option.value }}
            aria-pressed={option.value === color}
            aria-label={option.label}
            onClick={() => onColorChange(option.value)}
          />
        ))}
      </div>
    </div>
  );
}
