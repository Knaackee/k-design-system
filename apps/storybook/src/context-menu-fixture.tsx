import { useState } from "react";
import {
  KCard,
  KContainer,
  KContextMenu,
  KStack,
  KText,
  type KMenuAction,
} from "@k-design-system/ui";

export function ContextMenuFixture() {
  const [result, setResult] = useState("No action selected");
  const actions: KMenuAction[] = [
    {
      id: "copy",
      label: "Copy link",
      icon: "copy",
      onSelect: () => setResult("Copy link selected"),
    },
    {
      id: "move",
      label: "Move to",
      icon: "folder",
      children: [
        {
          id: "project-orbit",
          label: "Orbit",
          icon: "folder",
          onSelect: () => setResult("Moved to Orbit"),
        },
        {
          id: "project-design",
          label: "Design system",
          icon: "folder",
          onSelect: () => setResult("Moved to Design system"),
        },
      ],
    },
    {
      id: "share",
      label: "Share",
      icon: "link",
      disabled: true,
    },
    {
      id: "delete",
      label: "Delete",
      icon: "trash",
      destructive: true,
      separatorBefore: true,
      onSelect: () => setResult("Delete selected"),
    },
  ];
  return (
    <div className="k-primitive-fixture">
      <KContainer>
        <KStack align="stretch" gap="section">
          <KText variant="heading4">Context menu</KText>
          <KContextMenu label="Document actions" actions={actions}>
            <KCard className="k-context-menu-fixture__target">
              <KStack gap="content">
                <KText variant="label">Project brief</KText>
                <KText variant="bodySmall">
                  Right-click or long-press this card.
                </KText>
              </KStack>
            </KCard>
          </KContextMenu>
          <KText role="status">{result}</KText>
        </KStack>
      </KContainer>
    </div>
  );
}
