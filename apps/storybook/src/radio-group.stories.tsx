import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KRadioGroup, KStack, KText } from "@k-design-system/ui";

function RadioFixture() {
  const [value, setValue] = useState<string | null>("all");
  return (
    <div style={{ padding: "var(--k-space-card-padding)" }}>
      <KRadioGroup
        label="Notifications"
        value={value}
        onValueChange={setValue}
        items={[
          { value: "all", label: "All updates" },
          { value: "important", label: "Important updates only" },
          { value: "none", label: "No updates" },
          {
            value: "managed",
            label: "Managed by administrator",
            disabled: true,
          },
        ]}
      />
    </div>
  );
}
export default {
  title: "Forms/RadioGroup",
  component: RadioFixture,
  parameters: { fixtureId: "radio-group-options" },
} satisfies Meta<typeof RadioFixture>;
export const Options: StoryObj<typeof RadioFixture> = {
  name: "radio-group-options",
};

function SegmentedFixture() {
  const [status, setStatus] = useState<string | null>("draft");
  const [precision, setPrecision] = useState<string | null>("exact");
  return (
    <div style={{ padding: "var(--k-space-card-padding)" }}>
      <KStack gap="section" align="stretch">
        <KRadioGroup
          label="Status"
          appearance="segmented"
          value={status}
          onValueChange={setStatus}
          items={[
            { value: "draft", label: "Draft" },
            { value: "active", label: "Active" },
            { value: "archived", label: "Archived", disabled: true },
          ]}
        />
        <KRadioGroup
          label="Construction date"
          appearance="segmented"
          value={precision}
          onValueChange={setPrecision}
          items={[
            { value: "exact", label: "Exact year" },
            { value: "range", label: "Known period" },
            { value: "estimate", label: "Estimated construction period" },
          ]}
        />
        <KText>{`Selected: ${status} / ${precision}`}</KText>
      </KStack>
    </div>
  );
}
export const Segmented: StoryObj<typeof RadioFixture> = {
  name: "segmented-single-selection",
  parameters: { fixtureId: "segmented-single-selection" },
  render: () => <SegmentedFixture />,
};
