import type { ReactNode } from "react";
import {
  KAvatarPicker,
  KBadge,
  KButton,
  KCard,
  KCheckbox,
  KIcon,
  KInput,
  KList,
  KListItem,
  KSaveBar,
  KSettingsRow,
  KText,
} from "@k-design-system/ui";

/**
 * Geometry parity reference (Decision 0010). Same content and IDs as the
 * Widgetbook use case `Review/GeometryParity` (`geometry_parity_fixture.dart`).
 * `tooling/geometry-parity.mjs` measures each `[data-parity]` child and
 * compares it with the Flutter measurement.
 */
export const geometryParityWidth = 320;

function Entry({ id, children }: { id: string; children: ReactNode }) {
  return (
    <div data-parity={id} style={{ display: "flow-root" }}>
      {children}
    </div>
  );
}

export function GeometryParityFixture() {
  return (
    <div style={{ padding: 16 }}>
      <div
        style={{
          width: geometryParityWidth,
          boxSizing: "content-box",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          gap: 16,
        }}
      >
        <Entry id="text-heading1">
          <KText variant="heading1">Heading one</KText>
        </Entry>
        <Entry id="text-body">
          <KText>Body text that wraps across two lines on a phone width.</KText>
        </Entry>
        <Entry id="text-small">
          <KText variant="bodySmall">
            Small supporting text under a field.
          </KText>
        </Entry>
        <Entry id="button-primary">
          <KButton>Save</KButton>
        </Entry>
        <Entry id="button-secondary">
          <KButton variant="secondary">Cancel</KButton>
        </Entry>
        <Entry id="button-ghost">
          <KButton variant="ghost">Details</KButton>
        </Entry>
        <Entry id="badge">
          <KBadge>Active</KBadge>
        </Entry>
        <Entry id="checkbox">
          <KCheckbox
            label="Remember me"
            value={true}
            onValueChange={() => {}}
          />
        </Entry>
        <div data-parity="input" style={{ alignSelf: "stretch" }}>
          <KInput aria-label="Name" placeholder="Name" />
        </div>
        <div data-parity="card-header" style={{ alignSelf: "stretch" }}>
          <KCard
            title="Rocky"
            description="Agent · working"
            menu={[{ id: "edit", label: "Edit" }]}
            actions={<KButton>Open</KButton>}
          >
            <KText>Groups the feedback by theme.</KText>
          </KCard>
        </div>
        <div data-parity="save-bar" style={{ alignSelf: "stretch" }}>
          <KSaveBar changes={2} onSave={() => {}} onDiscard={() => {}} />
        </div>
        <div data-parity="avatar-picker" style={{ alignSelf: "stretch" }}>
          <KAvatarPicker
            shapes={[
              { id: "circle", label: "Circle", icon: <KIcon name="circle" /> },
              { id: "star", label: "Star", icon: <KIcon name="star" /> },
              { id: "drop", label: "Drop", icon: <KIcon name="droplet" /> },
              { id: "heart", label: "Heart", icon: <KIcon name="heart" /> },
              { id: "cloud", label: "Cloud", icon: <KIcon name="cloud" /> },
            ]}
            colors={[
              { value: "#f43f5e", label: "Rose" },
              { value: "#22d3ee", label: "Cyan" },
              { value: "#8b5cf6", label: "Violet" },
            ]}
            shape="drop"
            color="#22d3ee"
            onShapeChange={() => {}}
            onColorChange={() => {}}
          />
        </div>
        <div data-parity="settings-group" style={{ alignSelf: "stretch" }}>
          <KList title="Network">
            <KSettingsRow
              title="Browser permissions"
              description="None yet."
              control={<KButton variant="secondary">Refresh</KButton>}
            />
            <KSettingsRow
              title="Memories"
              description="What Rocky remembers."
              control={<KButton variant="secondary">Open</KButton>}
            />
          </KList>
        </div>
        <div data-parity="list-swipe" style={{ alignSelf: "stretch" }}>
          <KList>
            <KListItem
              title="Mara Feld"
              description="Moved the appointment"
              onClick={() => {}}
              trailingActions={[
                {
                  id: "delete",
                  label: "Delete",
                  icon: "trash",
                  tone: "destructive",
                },
              ]}
            />
          </KList>
        </div>
        <div data-parity="card" style={{ alignSelf: "stretch" }}>
          <KCard>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <KText variant="heading5">Card title</KText>
              <KText>One inset, title and body share the edge.</KText>
            </div>
          </KCard>
        </div>
      </div>
    </div>
  );
}
