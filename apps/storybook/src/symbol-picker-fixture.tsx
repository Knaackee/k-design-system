import { useState } from "react";
import {
  KIconPicker,
  KEmojiPicker,
  KText,
  type KSymbolItem,
} from "@k-design-system/ui";
export function SymbolPickerFixture({ emoji = false }: { emoji?: boolean }) {
  const [value, setValue] = useState<string | null>(null);
  const [recent, setRecent] = useState<string[]>([]);
  const [label, setLabel] = useState("");
  const select = (item: KSymbolItem) => {
    setValue(item.id);
    setLabel(item.label);
    setRecent((ids) =>
      [item.id, ...ids.filter((id) => id !== item.id)].slice(0, 24),
    );
  };
  const Picker = emoji ? KEmojiPicker : KIconPicker;
  const content = <Picker value={value} onSelect={select} recentIds={recent} />;
  return (
    <div style={{ maxWidth: 440, display: "grid", gap: 16 }}>
      {content}
      <KText variant="bodySmall">
        {label ? `Selected: ${label}` : "Choose a reaction or an icon"}
      </KText>
    </div>
  );
}
