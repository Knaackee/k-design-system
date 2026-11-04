import { useState } from "react";
import {
  KBottomSheet,
  KButton,
  KStack,
  KSwitch,
  KText,
} from "@k-design-system/ui";
export function SheetScrollHandoffFixture() {
  const [open, setOpen] = useState(false);
  const [checked, setChecked] = useState<Record<number, boolean>>({});
  return (
    <KStack gap="section">
      <KText>
        Scroll the settings, then pull down without lifting your finger. The
        sheet takes over at the top. A short pull returns it to its position.
      </KText>
      <KButton onClick={() => setOpen(true)}>Open scrollable sheet</KButton>
      <KBottomSheet
        open={open}
        onOpenChange={setOpen}
        title="Settings"
        actions={<KButton onClick={() => setOpen(false)}>Done</KButton>}
      >
        <KStack gap="section">
          {Array.from({ length: 24 }, (_, i) => (
            <KSwitch
              key={i}
              label={`Setting ${i + 1}`}
              checked={Boolean(checked[i])}
              onCheckedChange={(value) =>
                setChecked({ ...checked, [i]: value })
              }
            />
          ))}
        </KStack>
      </KBottomSheet>
    </KStack>
  );
}
