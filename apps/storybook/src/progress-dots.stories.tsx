import type { Meta, StoryObj } from "@storybook/react-vite";
import { KProgressDots } from "@k-design-system/ui";
const meta = {
  title: "Navigation/ProgressDots",
  component: KProgressDots,
  args: {
    count: 4,
    activeIndex: 1,
    label: "Einrichtung",
    dotSize: 6,
    activeWidth: 20,
    gap: 12,
  },
  parameters: { layout: "centered" },
} satisfies Meta<typeof KProgressDots>;
export default meta;
export const Steps: StoryObj<typeof meta> = {};
