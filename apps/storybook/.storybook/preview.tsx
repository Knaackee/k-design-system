import type { Decorator, Preview } from "@storybook/react-vite";
import "@k-design-system/tokens/tokens.css";
import "@k-design-system/ui/styles.css";
import "../src/gallery.css";

const withDesignTokens: Decorator = (Story, context) => {
  const brand = String(context.globals.brand ?? "orbit");
  const theme = String(context.globals.theme ?? "light");
  document.documentElement.dataset.brand = brand;
  document.documentElement.dataset.theme = theme;

  return (
    <main className="k-gallery" data-brand={brand} data-theme={theme}>
      <Story />
    </main>
  );
};

const preview: Preview = {
  decorators: [withDesignTokens],
  initialGlobals: {
    brand: "orbit",
    theme: "light",
  },
  globalTypes: {
    brand: {
      description: "Token brand",
      toolbar: {
        icon: "paintbrush",
        items: [
          { value: "orbit", title: "Orbit" },
          { value: "reference", title: "Reference" },
        ],
      },
    },
    theme: {
      description: "Color mode",
      toolbar: {
        icon: "mirror",
        items: [
          { value: "light", title: "Light" },
          { value: "dark", title: "Dark" },
        ],
      },
    },
  },
  parameters: {
    layout: "centered",
    a11y: {
      test: "error",
    },
  },
};

export default preview;
