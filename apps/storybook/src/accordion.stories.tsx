import type { Meta } from "@storybook/react-vite";
import { DisclosureFixture } from "./disclosure-fixture.js";

const meta = {
  title: "Primitives/Accordion",
  component: DisclosureFixture,
} satisfies Meta<typeof DisclosureFixture>;
export default meta;

export const Sections = {
  name: "accordion-sections",
  parameters: { fixtureId: "accordion-sections" },
  render: () => <DisclosureFixture accordion />,
};
