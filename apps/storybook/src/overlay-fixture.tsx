import { useState } from "react";
import { KBottomSheet, KButton, KDialog, KIconButton, KText } from "@k-design-system/ui";

export function OverlayFixture({ sheet = false }: { sheet?: boolean }) {
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState("No selection");
  const content = (
    <KText>Choose how this project should be shared with your team.</KText>
  );
  const actions = (
    <>
      <KButton onClick={() => setOpen(false)}>Cancel</KButton>
      <KButton
        onClick={() => {
          setMessage("Saved");
          setOpen(false);
        }}
      >
        Save
      </KButton>
    </>
  );
  return (
    <div
      style={{ padding: 24, display: "grid", gap: 16, justifyItems: "start" }}
    >
      <KText variant="heading4">
        {sheet ? "Bottom sheet" : "Modal dialog"}
      </KText>
      <KButton onClick={() => setOpen(true)}>
        Open {sheet ? "sheet" : "dialog"}
      </KButton>
      <KText role="status">{message}</KText>
      {sheet ? (
        <KBottomSheet
          open={open}
          onOpenChange={setOpen}
          title="Share project"
          description="Project settings"
          actions={actions}
          headerActions={<KIconButton icon="plus" label="New conversation" onClick={() => setMessage("New conversation")} />}
        >
          {content}
        </KBottomSheet>
      ) : (
        <KDialog
          open={open}
          onOpenChange={setOpen}
          title="Share project"
          description="Project settings"
          actions={actions}
          headerActions={<KIconButton icon="plus" label="New conversation" onClick={() => setMessage("New conversation")} />}
        >
          {content}
        </KDialog>
      )}
    </div>
  );
}
