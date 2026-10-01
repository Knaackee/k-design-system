import { useState, type ReactNode } from "react";
import { KIcon, type KIconName } from "../primitives/icon.js";
export function OptionMedia({
  imageSrc,
  icon,
  leading,
}: {
  imageSrc?: string;
  icon?: KIconName;
  leading?: ReactNode;
}) {
  const [failed, setFailed] = useState<string>();
  if (!leading && !imageSrc && !icon) return null;
  return (
    <span className="k-option-media" aria-hidden="true">
      {leading ??
        (imageSrc && failed !== imageSrc ? (
          <img src={imageSrc} alt="" onError={() => setFailed(imageSrc)} />
        ) : (
          <KIcon name={icon ?? "user"} />
        ))}
    </span>
  );
}
