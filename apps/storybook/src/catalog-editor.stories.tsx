import type { Meta, StoryObj } from "@storybook/react-vite";
import { CatalogEditor } from "./catalog-editor-fixture.js";
const meta = {
  title: "Patterns/CatalogEditor",
  component: CatalogEditor,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof CatalogEditor>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Service: Story = { args: { kind: "service" } };
export const Product: Story = { args: { kind: "product" } };
export const Stock: Story = {
  args: { kind: "product", initialPanel: "stock" },
};
export const Recommendations: Story = {
  args: { initialPanel: "recommendations" },
};
export const ServiceDark: Story = { ...Service, globals: { theme: "dark" } };
export const ProductDark: Story = { ...Product, globals: { theme: "dark" } };

const phone = {
  parameters: {
    viewport: {
      options: {
        phone: {
          name: "Phone · 390 × 844",
          styles: { width: "390px", height: "844px" },
        },
      },
    },
  },
  globals: {
    viewport: { value: "phone", isRotated: false },
    inputMode: "touch",
  },
};
export const ServiceMobile: Story = { ...Service, ...phone };
export const ProductMobile: Story = { ...Product, ...phone };
export const ProductMobileDark: Story = {
  ...Product,
  ...phone,
  globals: { ...phone.globals, theme: "dark" },
};
