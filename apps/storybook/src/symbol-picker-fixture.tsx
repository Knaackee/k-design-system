import { useState } from "react";
import {
  KIconPicker,
  KEmojiPicker,
  type KSymbolItem,
} from "@k-design-system/ui";
export function SymbolPickerFixture({ emoji = false }: { emoji?: boolean }) {
  const [value, setValue] = useState<string | null>(null);
  const [recent, setRecent] = useState<string[]>(
    emoji
      ? ["1f600", "1f603", "1f604", "1f601"]
      : ["heart", "star", "search", "clock"],
  );
  const select = (item: KSymbolItem) => {
    setValue(item.id);
    setRecent((ids) =>
      [item.id, ...ids.filter((id) => id !== item.id)].slice(0, 24),
    );
  };
  const Picker = emoji ? KEmojiPicker : KIconPicker;
  const content = <Picker value={value} onSelect={select} recentIds={recent} />;
  return (
    <div style={{ maxWidth: 440, display: "grid", gap: 16 }}>{content}</div>
  );
}
