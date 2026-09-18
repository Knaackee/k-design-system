import type { Meta } from "@storybook/react-vite";
import { DisclosureFixture } from "./disclosure-fixture.js";

const meta = {
  title: "Primitives/Disclosure",
  component: DisclosureFixture,
} satisfies Meta<typeof DisclosureFixture>;
export default meta;

export const States = {
  name: "disclosure-states",
  parameters: { fixtureId: "disclosure-states" },
  render: () => <DisclosureFixture />,
};
