import { StrictMode, useState } from "react";
import { createRoot } from "react-dom/client";

import "@k-design-system/tokens/tokens.css";
import "@k-design-system/ui/styles.css";
import "./theme.css";
import "./app.css";

import { applyKAdaptive } from "@k-design-system/ui/adaptive";
import { KButton } from "@k-design-system/ui/primitives/button";
import { KCard } from "@k-design-system/ui/primitives/card";
import { KStack } from "@k-design-system/ui/primitives/layout";
import { KText } from "@k-design-system/ui/primitives/text";
import { KField } from "@k-design-system/ui/forms/field";
import { KInput } from "@k-design-system/ui/forms/input";
import { KRadioGroup } from "@k-design-system/ui/forms/radio-group";

function App() {
  const [notificationLevel, setNotificationLevel] = useState("important");
  const [workspaceName, setWorkspaceName] = useState("");
  const [savedCount, setSavedCount] = useState(0);

  return (
    <main data-consumer-theme="dark" data-theme="dark">
      <section className="consumer-shell">
        <KText variant="heading2">Consumer-owned configuration</KText>
        <KText>
          Components come from the submodule. Branding and state stay in this
          application.
        </KText>
        <KCard className="consumer-card">
          <KStack gap="action" align="stretch">
            <KText variant="heading4">Workspace settings</KText>
            <KField label="Workspace name">
              <KInput
                placeholder="Product Lab"
                value={workspaceName}
                clearable
                onClear={() => setWorkspaceName("")}
                onChange={(event) => setWorkspaceName(event.target.value)}
              />
            </KField>
            <KRadioGroup
              label="Notifications"
              value={notificationLevel}
              items={[
                { value: "all", label: "All updates" },
                { value: "important", label: "Important updates only" },
                { value: "none", label: "No updates" },
              ]}
              onValueChange={setNotificationLevel}
            />
            <KButton
              fullWidth
              onClick={() => setSavedCount((count) => count + 1)}
            >
              Save settings
            </KButton>
            <KText variant="caption">
              {savedCount === 0
                ? "No changes saved yet"
                : `Saved ${savedCount} time${savedCount === 1 ? "" : "s"}: ${workspaceName || "Product Lab"}`}
            </KText>
          </KStack>
        </KCard>
      </section>
    </main>
  );
}

const root = document.getElementById("root");

if (!root) {
  throw new Error("Missing application root");
}

// Decision 0010: resolve adaptive axes from the window and pointer.
applyKAdaptive(document.documentElement);

createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
