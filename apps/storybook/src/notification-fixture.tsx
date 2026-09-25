import { useState } from "react";
import {
  KButton,
  KIcon,
  KSnackbar,
  KStack,
  KText,
  KToast,
  KToastViewport,
} from "@k-design-system/ui";

export function NotificationFixture({
  snackbar = false,
}: {
  snackbar?: boolean;
}) {
  const [visible, setVisible] = useState(false);
  const [long, setLong] = useState(false);
  const [generation, setGeneration] = useState(0);
  const [result, setResult] = useState("");
  const dismiss = () => setVisible(false);
  const show = (longMessage: boolean) => {
    setLong(longMessage);
    setGeneration((value) => value + 1);
    setVisible(true);
    setResult("");
  };
  const action = (
    <KButton
      variant="ghost"
      onClick={() => {
        dismiss();
        setResult(snackbar ? "Message restored" : "Changes opened");
      }}
    >
      {snackbar ? "Undo" : "View"}
    </KButton>
  );
  return (
    <div
      style={{
        padding: "var(--k-space-card-padding)",
        maxWidth: "100%",
        boxSizing: "border-box",
      }}
    >
      <KStack gap="control">
        <KButton onClick={() => show(false)}>
          Show {snackbar ? "snackbar" : "toast"}
        </KButton>
        <KButton variant="secondary" onClick={() => show(true)}>
          Show long message
        </KButton>
        {result ? <KText>{result}</KText> : null}
      </KStack>
      <KToastViewport position={snackbar ? "bottom-center" : "bottom-end"}>
        {visible ? (
          snackbar ? (
            <KSnackbar
              key={generation}
              message={
                long
                  ? "Your changes were saved. Everyone in the workspace will see the updated settings the next time they open the page."
                  : "Message archived"
              }
              action={action}
              duration={6000}
              onDismiss={dismiss}
            />
          ) : (
            <KToast
              key={generation}
              title="Changes saved"
              description={
                long
                  ? "Your changes were saved. Everyone in the workspace will see the updated settings the next time they open the page."
                  : "Your workspace settings are up to date."
              }
              tone="success"
              icon={<KIcon name="circle-check" />}
              action={action}
              duration={6000}
              onDismiss={dismiss}
            />
          )
        ) : null}
      </KToastViewport>
    </div>
  );
}
export function ToastFixture() {
  return <NotificationFixture />;
}
export function SnackbarFixture() {
  return <NotificationFixture snackbar />;
}
