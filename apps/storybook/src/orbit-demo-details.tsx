import {
  KButton,
  KResponsiveDrawer,
  KText,
  type KOrbitNode,
} from "@k-design-system/ui";
export function OrbitDemoDetails({
  node,
  pinnedId,
  onClose,
  onPin,
}: {
  node: KOrbitNode | null;
  pinnedId: string | null;
  onClose(): void;
  onPin(id: string | null): void;
}) {
  return (
    <KResponsiveDrawer
      open={node !== null}
      onOpenChange={(open) => {
        if (!open) onClose();
      }}
      title={node?.label ?? "Node details"}
      description={node?.description}
    >
      {node && (
        <div className="k-orbit-demo__details">
          <KText variant="body">Stable ID: {node.id}</KText>
          <KText variant="bodySmall">Parent: {node.parentId ?? "None"}</KText>
          <KText variant="bodySmall">Level: {node.levelId ?? "Center"}</KText>
          {node.progress !== undefined && (
            <KText variant="bodySmall">Progress: {node.progress}%</KText>
          )}
          <KButton onClick={() => onPin(pinnedId === node.id ? null : node.id)}>
            {pinnedId === node.id ? "Stop following" : "Follow node"}
          </KButton>
        </div>
      )}
    </KResponsiveDrawer>
  );
}
