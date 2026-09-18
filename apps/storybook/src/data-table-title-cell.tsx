import { useRef, useState } from "react";
import { KEditableCell, KInput } from "@k-design-system/ui";
export function TitleCell({
  id,
  title,
  onCommit,
  onChange,
  onCancel,
  initiallyEditing = false,
  provisional = false,
  disabled = false,
}: {
  id: string;
  title: string;
  onCommit: (value: string, explicit: boolean) => void;
  onChange: (value: string) => void;
  onCancel: () => void;
  initiallyEditing?: boolean;
  provisional?: boolean;
  disabled?: boolean;
}) {
  const [editing, setEditing] = useState(initiallyEditing),
    [draft, setDraft] = useState(title);
  const active = useRef(initiallyEditing);
  function finish(commit: boolean, explicit = false) {
    if (!active.current) return;
    active.current = false;
    setEditing(false);
    if (commit) onCommit(draft, explicit);
    else if (provisional) onCancel();
  }
  return (
    <KEditableCell
      label={`Edit title for ${id}`}
      paddingInline={4}
      editing={editing}
      onEdit={
        disabled
          ? undefined
          : () => {
              setDraft(title);
              active.current = true;
              setEditing(true);
            }
      }
      display={
        <span
          title={title}
          style={{
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {title}
        </span>
      }
      editor={
        <KInput
          autoFocus
          disabled={disabled}
          aria-label={`Title for ${id}`}
          value={draft}
          onChange={(e) => {
            setDraft(e.target.value);
            onChange(e.target.value);
          }}
          onBlur={() => finish(true)}
          onKeyDown={(e) => {
            if (e.nativeEvent.isComposing) return;
            if (e.key === "Enter" || e.key === "Escape") {
              e.preventDefault();
              e.stopPropagation();
              finish(e.key === "Enter", true);
            }
          }}
        />
      }
    />
  );
}
