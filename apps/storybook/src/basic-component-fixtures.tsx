import { useState } from "react";
import {
  KAlert,
  KAlertDialog,
  KAttachment,
  KAvatar,
  KAvatarGroup,
  KBadge,
  KBreadcrumb,
  KButton,
  KCarousel,
  KIcon,
  KIconButton,
  KText,
} from "@k-design-system/ui";

const fixtureStyle = {
  display: "grid",
  gap: 16,
  width: "min(100%, 720px)",
  maxWidth: 720,
  padding: 24,
  boxSizing: "border-box",
} as const;

export function AlertFixture() {
  return (
    <div style={fixtureStyle}>
      <KAlert
        icon="info"
        tone="info"
        title="Scheduled maintenance"
        description="The workspace will be unavailable tonight from 22:00 to 22:15."
        action={<KButton variant="ghost">Details</KButton>}
      />
      <KAlert
        icon="triangle-alert"
        tone="error"
        title="Upload failed"
        description="Check the file and try again."
      />
    </div>
  );
}

export function AlertDialogFixture() {
  const [open, setOpen] = useState(false);
  const [status, setStatus] = useState("No action");
  return (
    <div style={fixtureStyle}>
      <KButton variant="secondary" onClick={() => setOpen(true)}>
        Delete project
      </KButton>
      <KText role="status">{status}</KText>
      <KAlertDialog
        open={open}
        onOpenChange={setOpen}
        title="Delete project?"
        description="This action cannot be undone. All project data will be removed."
        media={<KIcon name="trash" size={22} />}
        cancelLabel="Cancel"
        actionLabel="Delete project"
        destructive
        onAction={() => setStatus("Project deleted")}
      />
    </div>
  );
}

export function AttachmentFixture() {
  return (
    <div style={fixtureStyle}>
      <KAttachment
        title="Product brief.pdf"
        description="2.4 MB · PDF"
        media={<KIcon name="file-text" />}
        activateLabel="Open Product brief.pdf"
        onActivate={() => undefined}
        actions={<KIconButton icon="download" label="Download" />}
      />
      <KAttachment
        title="Brand assets.zip"
        description="Uploading · 68%"
        state="uploading"
        progress={0.68}
        showLoadingIndicator
        media={<KIcon name="upload" />}
        actions={<KIconButton icon="x" label="Cancel upload" />}
      />
    </div>
  );
}

export function AvatarFixture() {
  return (
    <div style={fixtureStyle}>
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        <KAvatar size="small" alt="Mia Chen" fallback="MC" />
        <KAvatar alt="Noah Williams" fallback="NW" badge="" />
        <KAvatar size="large" alt="Ava Singh" fallback="AS" />
      </div>
      <KAvatarGroup aria-label="Project members">
        <KAvatar alt="Mia Chen" fallback="MC" />
        <KAvatar alt="Noah Williams" fallback="NW" />
        <KAvatar alt="Ava Singh" fallback="AS" />
        <KAvatar alt="Three more members" fallback="+3" />
      </KAvatarGroup>
    </div>
  );
}

export function BadgeFixture() {
  return (
    <div
      style={{
        ...fixtureStyle,
        gridTemplateColumns: "repeat(auto-fit, minmax(100px, max-content))",
      }}
    >
      <KBadge leading={<KIcon name="check" />}>Active</KBadge>
      <KBadge variant="secondary">Draft</KBadge>
      <KBadge variant="outline">In review</KBadge>
      <KBadge variant="ghost">Archived</KBadge>
      <KBadge variant="destructive" leading={<KIcon name="circle-alert" />}>
        Blocked
      </KBadge>
    </div>
  );
}

export function BreadcrumbFixture() {
  return (
    <div style={fixtureStyle}>
      <KBreadcrumb
        items={[
          { id: "home", label: "Home", onSelect: () => undefined },
          { id: "projects", label: "Projects", onSelect: () => undefined },
          { id: "orbit", label: "Orbit redesign" },
        ]}
      />
    </div>
  );
}

const slideStyle = {
  boxSizing: "border-box",
  display: "grid",
  alignContent: "end",
  minHeight: 180,
  padding: 20,
  border: "1px solid var(--k-color-border-default)",
  borderRadius: "var(--k-radius-card)",
  background: "var(--k-color-surface-raised)",
} as const;

export function CarouselFixture() {
  return (
    <div style={fixtureStyle}>
      <KCarousel label="Featured projects">
        <div style={slideStyle}>
          <KText variant="heading4">Orbit workspace</KText>
          <KText>Coordinate product work across every platform.</KText>
        </div>
        <div style={slideStyle}>
          <KText variant="heading4">Design review</KText>
          <KText>Keep decisions, files and feedback together.</KText>
        </div>
        <div style={slideStyle}>
          <KText variant="heading4">Release planning</KText>
          <KText>Move confidently from scope to delivery.</KText>
        </div>
      </KCarousel>
    </div>
  );
}
