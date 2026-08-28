import type { Decorator, Preview } from "@storybook/react-vite";
import "@k-design-system/tokens/tokens.css";
import "@k-design-system/ui/styles.css";
import "../src/gallery.css";

const withDesignTokens: Decorator = (Story, context) => {
  const brand = String(context.globals.brand ?? "orbit");
  const theme = String(context.globals.theme ?? "light");
  const presentation = String(context.globals.presentation ?? "productive");
  const density = String(context.globals.density ?? "standard");
  const typeScale = String(context.globals.typeScale ?? "compact");
  const inputMode = String(context.globals.inputMode ?? "pointer");
  const windowClass = String(context.globals.windowClass ?? "compact");
  const textScale = Number(context.globals.textScale ?? 1);
  document.documentElement.dataset.brand = brand;
  document.documentElement.dataset.theme = theme;
  document.documentElement.dataset.presentation = presentation;
  document.documentElement.dataset.density = density;
  document.documentElement.dataset.typeScale = typeScale;
  document.documentElement.dataset.inputMode = inputMode;
  document.documentElement.dataset.windowClass = windowClass;
  document.documentElement.style.setProperty(
    "--k-text-scale",
    String(textScale),
  );

  return (
    <main
      className="k-gallery"
      data-brand={brand}
      data-theme={theme}
      data-presentation={presentation}
      data-density={density}
      data-type-scale={typeScale}
      data-input-mode={inputMode}
      data-window-class={windowClass}
    >
      <Story />
    </main>
  );
};

const preview: Preview = {
  decorators: [withDesignTokens],
  initialGlobals: {
    brand: "orbit",
    theme: "light",
    presentation: "productive",
    density: "standard",
    typeScale: "compact",
    inputMode: "pointer",
    windowClass: "compact",
    textScale: 1,
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
    presentation: {
      description: "Product or editorial presentation",
      toolbar: {
        icon: "component",
        items: [
          { value: "productive", title: "Productive" },
          { value: "expressive", title: "Expressive" },
        ],
      },
    },
    density: {
      description: "Visual component density",
      toolbar: {
        icon: "grow",
        items: [
          { value: "dense", title: "Dense" },
          { value: "standard", title: "Standard" },
          { value: "spacious", title: "Spacious" },
        ],
      },
    },
    typeScale: {
      description: "Base typography scale",
      toolbar: {
        icon: "paragraph",
        items: [
          { value: "compact", title: "Compact · 14" },
          { value: "standard", title: "Standard · 16" },
        ],
      },
    },
    inputMode: {
      description: "Pointer or touch interaction target",
      toolbar: {
        icon: "mobile",
        items: [
          { value: "pointer", title: "Pointer" },
          { value: "touch", title: "Touch" },
        ],
      },
    },
    windowClass: {
      description: "Available window width class",
      toolbar: {
        icon: "browser",
        items: [
          { value: "compact", title: "Compact · <600" },
          { value: "medium", title: "Medium · 600–839" },
          { value: "expanded", title: "Expanded · 840–1199" },
          { value: "large", title: "Large · 1200–1599" },
          { value: "extra-large", title: "Extra large · ≥1600" },
        ],
      },
    },
    textScale: {
      description: "Accessibility text-scale preview",
      toolbar: {
        icon: "zoom",
        items: [
          { value: 1, title: "Text 100%" },
          { value: 1.25, title: "Text 125%" },
          { value: 1.5, title: "Text 150%" },
          { value: 2, title: "Text 200%" },
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
