import {
  greatIconExtensions,
  greatIconImages,
} from "../generated/great-icons.js";

export interface KFileIconProps {
  name: string;
  kind?: "file" | "folder";
  expanded?: boolean;
  size?: number;
}

/** Original VSCode Great Icons assets. File names remain the accessible label of the row. */
export function KFileIcon({
  name,
  kind = "file",
  expanded = false,
  size = 16,
}: KFileIconProps) {
  const extension = name.includes(".")
    ? name.split(".").pop()!.toLowerCase()
    : "";
  const key =
    kind === "folder"
      ? expanded
        ? "_fd_default-open"
        : "_fd_default"
      : (greatIconExtensions[extension] ?? "_file");
  return (
    <img
      className="k-file-icon"
      src={greatIconImages[key]}
      alt=""
      aria-hidden="true"
      width={size}
      height={size}
      draggable={false}
      style={{ objectFit: "contain", flexShrink: 0 }}
    />
  );
}
