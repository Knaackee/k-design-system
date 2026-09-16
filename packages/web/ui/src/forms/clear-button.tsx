import { KIcon } from "../primitives/icon.js";
export function ClearButton({
  label,
  onClear,
}: {
  label: string;
  onClear: () => void;
}) {
  return (
    <button
      type="button"
      className="k-form-clear"
      aria-label={label}
      onPointerDown={(event) => event.preventDefault()}
      onClick={onClear}
    >
      <KIcon name="x" />
    </button>
  );
}
