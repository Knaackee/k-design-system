import { useState } from "react";
import { KIcon, type KIconName } from "../primitives/icon.js";
export function OptionMedia({
  imageSrc,
  icon,
}: {
  imageSrc?: string;
  icon?: KIconName;
}) {
  const [failed, setFailed] = useState<string>();
  if (!imageSrc && !icon) return null;
  return (
    <span className="k-option-media" aria-hidden="true">
      {imageSrc && failed !== imageSrc ? (
        <img src={imageSrc} alt="" onError={() => setFailed(imageSrc)} />
      ) : (
        <KIcon name={icon ?? "user"} />
      )}
    </span>
  );
}
