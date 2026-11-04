import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { KAvatar, KButton, KStack } from "@k-design-system/ui";
import { AvatarEditorFixture } from "./avatar-editor-fixture.js";
function Editor() {
  const [open, setOpen] = useState(true);
  const [src, setSrc] = useState<string>();
  return (
    <KStack align="center" gap="action">
      <KAvatar alt="Dein Profil" src={src} size="large" />
      <KButton onClick={() => setOpen(true)}>Bild ändern</KButton>
      <AvatarEditorFixture
        open={open}
        onOpenChange={setOpen}
        onAvatarChange={setSrc}
      />
    </KStack>
  );
}
export default {
  title: "Patterns/AvatarEditor",
  component: Editor,
} satisfies Meta<typeof Editor>;
export const Gallery: StoryObj<typeof Editor> = {};
