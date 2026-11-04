import { useState } from "react";
import {
  KAccordion,
  KContainer,
  KDisclosure,
  KIcon,
  KOverflowMenu,
  KStack,
  KText,
} from "@k-design-system/ui";

export function DisclosureFixture({
  accordion = false,
}: {
  accordion?: boolean;
}) {
  const [message, setMessage] = useState("No action selected");
  const actions = (section: string) => (
    <KOverflowMenu
      label={`More actions for ${section}`}
      actions={[
        {
          id: "rename",
          label: "Rename",
          icon: "pen",
          onSelect: () => setMessage(`Rename ${section}`),
        },
        {
          id: "copy",
          label: "Copy link",
          icon: "link",
          onSelect: () => setMessage(`Copy link for ${section}`),
        },
      ]}
    />
  );

  return (
    <KContainer>
      <KStack gap="section" align="stretch" style={{ maxWidth: 640 }}>
        <KText variant="heading4">
          {accordion ? "Accordion" : "Disclosure"}
        </KText>
        {accordion ? (
          <KAccordion
            aria-label="Project sections"
            defaultValue={["overview"]}
            items={[
              {
                id: "overview",
                title: "Overview",
                leadingIcon: <KIcon name="folder" size={20} />,
                titleIcon: <KIcon name="star" size={20} />,
                actions: actions("Overview"),
                content: <KText>Project details and ownership.</KText>,
              },
              {
                id: "activity",
                title: "Activity",
                leadingIcon: <KIcon name="clock" size={20} />,
                actions: (
                  <>
                    <KText variant="caption">3 items</KText>
                    {actions("Activity")}
                  </>
                ),
                content: <KText>Recent updates and decisions.</KText>,
              },
            ]}
          />
        ) : (
          <KDisclosure
            title="Project settings"
            leadingIcon={<KIcon name="settings" size={20} />}
            titleIcon={<KIcon name="star" size={20} />}
            actions={actions("Project settings")}
            defaultOpen
          >
            <KText>Configure the shared project defaults here.</KText>
          </KDisclosure>
        )}
        <KText variant="bodySmall" role="status">
          {message}
        </KText>
      </KStack>
    </KContainer>
  );
}
