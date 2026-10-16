import { useState } from "react";
import {
  KButton,
  KCheckbox,
  KIcon,
  KInputOtp,
  KKbd,
  KKbdGroup,
  KNavigationMenu,
  KPagination,
  KPopover,
  KProgress,
  KQuestionnaire,
  KResponsiveDrawer,
  KSkeleton,
  KSlider,
  KSpinner,
  KSwitch,
  KTabs,
  KToast,
  KToastViewport,
} from "@k-design-system/ui";

const frame = {
  width: "min(100%, 720px)",
  padding: 24,
  boxSizing: "border-box" as const,
};
export function DrawerFixture() {
  const [open, setOpen] = useState(false);
  return (
    <div style={frame}>
      <KButton variant="secondary" onClick={() => setOpen(true)}>
        Open workspace
      </KButton>
      <KResponsiveDrawer
        open={open}
        onOpenChange={setOpen}
        title="Workspace settings"
        description="Sidebar on larger screens, bottom sheet on compact screens."
        actions={<KButton onClick={() => setOpen(false)}>Save changes</KButton>}
      >
        <p>Any consumer content can live here.</p>
      </KResponsiveDrawer>
    </div>
  );
}
export function OtpFixture() {
  const [value, setValue] = useState("123");
  return (
    <div style={frame}>
      <KInputOtp
        value={value}
        onValueChange={setValue}
        label="Verification code"
      />
    </div>
  );
}
export function KbdFixture() {
  return (
    <div style={frame}>
      Open commands with{" "}
      <KKbdGroup>
        <KKbd>Ctrl</KKbd>
        <span>+</span>
        <KKbd>K</KKbd>
      </KKbdGroup>
    </div>
  );
}
export function NavigationMenuFixture() {
  return (
    <div style={frame}>
      <KNavigationMenu
        items={[
          {
            id: "products",
            label: "Products",
            content: (
              <>
                <strong>Design system</strong>
                <span>Reusable components for every platform.</span>
              </>
            ),
          },
          { id: "docs", label: "Documentation", href: "#docs" },
          { id: "components", label: "Components", href: "#components" },
          { id: "resources", label: "Resources", href: "#resources" },
          { id: "changelog", label: "Changelog", href: "#changelog" },
          { id: "about", label: "About", href: "#about" },
        ]}
      />
    </div>
  );
}
export function PaginationFixture() {
  const [page, setPage] = useState(4);
  return (
    <div style={frame}>
      <KPagination page={page} pageCount={12} onPageChange={setPage} />
    </div>
  );
}
export function PopoverFixture() {
  return (
    <div style={frame}>
      <KPopover
        label="Project details"
        trigger={<KButton variant="secondary">Open popover</KButton>}
      >
        <strong>Project details</strong>
        <p style={{ marginBottom: 0 }}>Rich, consumer-defined content.</p>
      </KPopover>
    </div>
  );
}
export function ProgressFixture() {
  return (
    <div style={{ ...frame, display: "grid", gap: 20 }}>
      <KProgress value={68} label="Upload progress" />
      <KProgress label="Preparing workspace" />
    </div>
  );
}
export function QuestionnaireFixture() {
  const [step, setStep] = useState(0);
  const [done, setDone] = useState(false);
  const [componentLibrary, setComponentLibrary] = useState(true);
  const [decisions, setDecisions] = useState(true);
  const [startNow, setStartNow] = useState(true);
  return (
    <div style={frame}>
      {done ? (
        <p role="status">Plan saved.</p>
      ) : (
        <KQuestionnaire
          step={step}
          onStepChange={setStep}
          onComplete={() => setDone(true)}
          steps={[
            {
              id: "direction",
              title: "What should we build next?",
              description: "Choose a direction.",
              content: (
                <KCheckbox
                  label="Component library"
                  value={componentLibrary}
                  onValueChange={setComponentLibrary}
                />
              ),
            },
            {
              id: "updates",
              title: "What should updates include?",
              description: "Select all that apply.",
              optional: true,
              content: (
                <KCheckbox
                  label="Decisions and risks"
                  value={decisions}
                  onValueChange={setDecisions}
                />
              ),
            },
            {
              id: "start",
              title: "When should work begin?",
              content: (
                <KCheckbox
                  label="Start now"
                  value={startNow}
                  onValueChange={setStartNow}
                />
              ),
            },
          ]}
        />
      )}
    </div>
  );
}
export function SkeletonFixture() {
  return (
    <div
      style={{
        ...frame,
        display: "grid",
        gridTemplateColumns: "48px 1fr",
        gap: 12,
      }}
    >
      <KSkeleton circle style={{ width: 48, height: 48 }} />
      <div style={{ display: "grid", gap: 8 }}>
        <KSkeleton style={{ width: "42%" }} />
        <KSkeleton />
        <KSkeleton style={{ width: "72%" }} />
      </div>
    </div>
  );
}
export function SliderFixture() {
  const [value, setValue] = useState(38);
  return (
    <div style={frame}>
      <KSlider
        value={value}
        onValueChange={setValue}
        label="Volume"
        valueLabel={(v) => `${v}%`}
      />
      <p>{value}%</p>
    </div>
  );
}
export function SpinnerFixture() {
  return (
    <div style={{ ...frame, display: "flex", alignItems: "center", gap: 10 }}>
      <KSpinner label="Processing" /> Processing payment…
    </div>
  );
}
export function SwitchFixture() {
  const [checked, setChecked] = useState(true);
  return (
    <div style={{ ...frame, display: "flex", alignItems: "center", gap: 12 }}>
      <KSwitch
        checked={checked}
        onCheckedChange={setChecked}
        label="Share across devices"
      />
    </div>
  );
}
export function TabsFixture() {
  const [value, setValue] = useState("overview");
  return (
    <div style={frame}>
      <KTabs
        value={value}
        onValueChange={setValue}
        items={[
          {
            id: "overview",
            label: "Overview",
            icon: "folder",
            content: <p>Key metrics and recent activity.</p>,
          },
          {
            id: "analytics",
            label: "Analytics",
            icon: "info",
            content: <p>Analytics content.</p>,
          },
          {
            id: "activity",
            label: "Activity",
            icon: "calendar",
            content: <p>Recent workspace activity.</p>,
          },
          {
            id: "members",
            label: "Members",
            icon: "users",
            content: <p>Workspace members.</p>,
          },
          {
            id: "integrations",
            label: "Integrations",
            icon: "link",
            content: <p>Connected integrations.</p>,
          },
          {
            id: "settings",
            label: "Settings",
            icon: "settings",
            content: <p>Settings content.</p>,
          },
        ]}
      />
    </div>
  );
}
export function ToastFixture() {
  const [visible, setVisible] = useState(false);
  return (
    <div style={frame}>
      <KButton variant="secondary" onClick={() => setVisible(true)}>
        Show toast
      </KButton>
      {visible ? (
        <KToastViewport>
          <KToast
            tone="success"
            icon={<KIcon name="circle-check" />}
            title="Event created"
            description="Today at 09:00"
            action={
              <KButton variant="secondary" onClick={() => setVisible(false)}>
                View
              </KButton>
            }
            onDismiss={() => setVisible(false)}
          />
        </KToastViewport>
      ) : null}
    </div>
  );
}
