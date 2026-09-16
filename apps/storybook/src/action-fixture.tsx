import { useState } from "react";
import {
  KContainer,
  KStack,
  KText,
  KToolbar,
  KButton,
  KMenuButton,
  KOverflowMenu,
  KIconButton,
  type KMenuAction,
} from "@k-design-system/ui";
export function ActionFixture({
  kind = "toolbar",
}: {
  kind?: "toolbar" | "menu" | "icon";
}) {
  const [result, setResult] = useState("No action selected");
  const actions: KMenuAction[] = [
    {
      id: "copy",
      label: "Copy link",
      icon: "link",
      onSelect: () => setResult("Copy link selected"),
    },
    {
      id: "duplicate",
      label: "Duplicate",
      icon: "copy",
      onSelect: () => setResult("Duplicate selected"),
    },
    {
      id: "export",
      label: "Export",
      icon: "download",
      disabled: true,
      onSelect: () => setResult("Export selected"),
    },
    {
      id: "archive",
      label: "Archive",
      icon: "folder",
      separatorBefore: true,
      onSelect: () => setResult("Archive selected"),
    },
    {
      id: "delete",
      label: "Delete",
      icon: "trash",
      destructive: true,
      onSelect: () => setResult("Delete selected"),
    },
  ];
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">
            {kind === "toolbar"
              ? "Workspace actions"
              : kind === "menu"
                ? "Action menu"
                : "Icon actions"}
          </KText>
          <KToolbar label="Workspace actions">
            {kind === "toolbar" ? (
              <KButton onClick={() => setResult("New item selected")}>
                New item
              </KButton>
            ) : null}
            {kind !== "icon" ? (
              <KMenuButton label="Actions" actions={actions} />
            ) : null}
            {kind !== "menu" ? (
              <KIconButton
                label="Refresh"
                icon="refresh-cw"
                onClick={() => setResult("Refresh selected")}
              />
            ) : null}
            {kind === "icon" ? (
              <KIconButton label="Unavailable" icon="download" disabled />
            ) : (
              <KOverflowMenu label="More actions" actions={actions} />
            )}
          </KToolbar>
          <KText role="status">{result}</KText>
        </KStack>
      </KContainer>
    </div>
  );
}
