import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KUserMenu,
  KText,
  KStack,
  KInline,
  type KUserMenuProps,
} from "@k-design-system/ui";

function UserMenuFixture(
  props: Pick<
    KUserMenuProps,
    | "userName"
    | "description"
    | "avatarSrc"
    | "avatarFallback"
    | "label"
    | "disabled"
  >,
) {
  const [result, setResult] = useState("No action selected");
  return (
    <KStack
      align="stretch"
      gap="section"
      style={{ width: "100%", minWidth: 0 }}
    >
      <KInline
        align="center"
        style={{
          justifyContent: "space-between",
          padding: "var(--k-space-card-padding)",
          borderBottom:
            "var(--k-border-width-default) solid var(--k-color-border-default)",
        }}
      >
        <KText variant="heading4">Workspace</KText>
        <KUserMenu
          {...props}
          actions={[
            {
              id: "profile",
              label: "Profile",
              icon: "user",
              onSelect: () => setResult("Profile selected"),
            },
            {
              id: "settings",
              label: "Settings",
              icon: "settings",
              onSelect: () => setResult("Settings selected"),
            },
            {
              id: "help",
              label: "Help & support",
              icon: "circle-question-mark",
              separatorBefore: true,
              onSelect: () => setResult("Help selected"),
            },
            {
              id: "sign-out",
              label: "Sign out",
              icon: "log-out",
              destructive: true,
              separatorBefore: true,
              onSelect: () => setResult("Sign out requested — demo only"),
            },
          ]}
        />
      </KInline>
      <div
        role="status"
        style={{ paddingInline: "var(--k-space-card-padding)" }}
      >
        <KText variant="bodySmall">{result}</KText>
      </div>
    </KStack>
  );
}
const meta = {
  title: "Actions/UserMenu",
  component: UserMenuFixture,
  args: {
    userName: "Alex Morgan",
    description: "alex@workspace.example",
    label: "User menu",
    disabled: false,
  },
  parameters: { fixtureId: "user-menu-account" },
} satisfies Meta<typeof UserMenuFixture>;
export default meta;
export const Account: StoryObj<typeof meta> = { name: "user-menu-account" };
export const LongIdentity: StoryObj<typeof meta> = {
  name: "user-menu-long-identity",
  args: {
    userName: "Alexandra Morgan-Hernández",
    description: "alexandra.morgan@international-workspace.example",
  },
  parameters: { fixtureId: "user-menu-long-identity" },
};
