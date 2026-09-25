import type { ReactNode } from "react";
import { KAvatar } from "../basic-components.js";
import { KMenuButton, type KMenuAction } from "./menu-button.js";

export type KUserMenuAction = Omit<KMenuAction, "children">;
export interface KUserMenuProps {
  userName: string;
  description?: ReactNode;
  avatarSrc?: string;
  avatarFallback?: ReactNode;
  /** Replace the avatar, e.g. with a consumer-owned image or status badge. */
  avatar?: ReactNode;
  actions: readonly KUserMenuAction[];
  label?: string;
  disabled?: boolean;
  /** Override the non-interactive account heading; null hides it. */
  header?: ReactNode;
  onOpenChange?: (open: boolean) => void;
}

/** Avatar-triggered user actions. Navigation and authentication belong to the consumer. */
export function KUserMenu({
  userName,
  description,
  avatarSrc,
  avatarFallback,
  avatar,
  actions,
  label = "User menu",
  disabled,
  header,
  onOpenChange,
}: KUserMenuProps) {
  const image = avatar ?? (
    <KAvatar src={avatarSrc} alt={userName} fallback={avatarFallback} />
  );
  return (
    <KMenuButton
      label={label}
      actions={actions}
      disabled={disabled}
      align="end"
      overflow
      triggerVariant="ghost"
      triggerClassName="k-user-menu__trigger"
      triggerContent={<span aria-hidden="true">{image}</span>}
      onOpenChange={onOpenChange}
      header={
        header === undefined ? (
          <div className="k-user-menu__identity">
            <span aria-hidden="true">{image}</span>
            <div className="k-user-menu__details">
              <span className="k-user-menu__name">{userName}</span>
              {description != null && (
                <span
                  className="k-user-menu__description"
                  title={
                    typeof description === "string" ? description : undefined
                  }
                >
                  {description}
                </span>
              )}
            </div>
          </div>
        ) : (
          header
        )
      }
    />
  );
}
