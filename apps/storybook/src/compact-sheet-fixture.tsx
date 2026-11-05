import { useState } from "react";
import "./compact-sheet-fixture.css";
import {
  KBottomSheet,
  KButton,
  KCheckbox,
  KField,
  KInput,
  KTextarea,
  KStack,
  KText,
} from "@k-design-system/ui";

export function CompactSheetFixture() {
  const [open, setOpen] = useState(false);
  const [longContent, setLongContent] = useState(false);
  const [distinctSurface, setDistinctSurface] = useState(false);
  const [result, setResult] = useState("No selection");
  function close(saved: boolean) {
    setResult(saved ? "Saved" : "Cancelled");
    setOpen(false);
  }
  return (
    <KStack gap="action">
      <KCheckbox
        label="Long form"
        value={longContent}
        onValueChange={setLongContent}
      />
      <KButton onClick={() => setOpen(true)}>Open sheet</KButton>
      <KCheckbox
        label="Distinct overlay surface"
        value={distinctSurface}
        onValueChange={setDistinctSurface}
      />
      <KText role="status">{result}</KText>
      <KBottomSheet
        className={
          distinctSurface ? "compact-sheet-fixture--distinct" : undefined
        }
        open={open}
        onOpenChange={(value) => (value ? setOpen(true) : close(false))}
        title="Project settings"
        description="Only the fields scroll."
        actions={
          <>
            <KButton variant="secondary" onClick={() => close(false)}>
              Cancel
            </KButton>
            <KButton onClick={() => close(true)}>Save</KButton>
          </>
        }
      >
        <KStack gap="action" align="stretch">
          <KField label="Name">
            <KInput />
          </KField>
          <KField label="Description">
            <KTextarea rows={3} />
          </KField>
          {longContent &&
            Array.from({ length: 8 }, (_, i) => (
              <KField key={i} label={`Setting ${i + 1}`}>
                <KInput />
              </KField>
            ))}
        </KStack>
      </KBottomSheet>
    </KStack>
  );
}
