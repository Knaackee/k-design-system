import type { Meta, StoryObj } from "@storybook/react-vite";
import { AttachmentFixture } from "./basic-component-fixtures.js";
const meta = {
  title: "Data display/Attachment",
  component: AttachmentFixture,
} satisfies Meta<typeof AttachmentFixture>;
export default meta;
export const States: StoryObj<typeof meta> = {
  name: "attachment-states",
  parameters: { fixtureId: "attachment-states" },
};
