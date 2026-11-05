import type { Decorator, Preview } from "@storybook/react-vite";
import { useSyncExternalStore } from "react";
import {
  KLocalizationProvider,
  resolveKAdaptive,
  setKTextScale,
  kIsAndroid,
  kIsAppleTouch,
} from "@k-design-system/ui";
import type { KAdaptiveOverrides } from "@k-design-system/ui";
import type { StoryIndexEntry } from "storybook/internal/types";
import "@k-design-system/tokens/tokens.css";
import "@k-design-system/ui/styles.css";
import "../src/gallery.css";

// Re-resolve "auto" axes when the preview viewport or pointer changes.
const subscribeViewport = (notify: () => void) => {
  const coarse = window.matchMedia("(pointer: coarse)");
  window.addEventListener("resize", notify);
  coarse.addEventListener("change", notify);
  return () => {
    window.removeEventListener("resize", notify);
    coarse.removeEventListener("change", notify);
  };
};
const viewportKey = () =>
  `${window.innerWidth}:${window.matchMedia("(pointer: coarse)").matches}`;

const withDesignTokens: Decorator = (Story, context) => {
  useSyncExternalStore(subscribeViewport, viewportKey);
  const language = String(context.globals.language ?? "en");
  document.documentElement.lang = language;
  const brand = String(context.globals.brand ?? "orbit");
  const theme = String(context.globals.theme ?? "light");
  const density = String(context.globals.density ?? "standard");
  // Decision 0010: "auto" resolves like a real device from the preview
  // viewport and primary pointer; explicit toolbar values are overrides.
  const pick = (key: string) => {
    const value = String(context.globals[key] ?? "auto");
    return value === "auto" ? undefined : value;
  };
  const resolved = resolveKAdaptive(
    {
      width: window.innerWidth,
      coarsePointer: window.matchMedia("(pointer: coarse)").matches,
      reduceMotion: window.matchMedia("(prefers-reduced-motion: reduce)")
        .matches,
      appleTouch: kIsAppleTouch(),
      android: kIsAndroid(),
    },
    {
      density: pick("density"),
      typeScale: pick("typeScale"),
      inputMode: pick("inputMode"),
      windowClass: pick("windowClass"),
      motion: pick("motion"),
      style: pick("style"),
    } as KAdaptiveOverrides,
  );
  const typeScale = resolved.typeScale;
  const inputMode = resolved.inputMode;
  const windowClass = resolved.windowClass;
  const textScale = Number(context.globals.textScale ?? 1);
  document.documentElement.dataset.brand = brand;
  document.documentElement.dataset.theme = theme;
  document.documentElement.dataset.density = density;
  document.documentElement.dataset.typeScale = typeScale;
  document.documentElement.dataset.inputMode = inputMode;
  document.documentElement.dataset.windowClass = windowClass;
  document.documentElement.dataset.motion = resolved.motion;
  document.documentElement.dataset.style = resolved.style;
  setKTextScale(document.documentElement, textScale);

  return (
    <main
      className="k-gallery"
      data-brand={brand}
      data-theme={theme}
      data-density={density}
      data-type-scale={typeScale}
      data-input-mode={inputMode}
      data-window-class={windowClass}
      data-motion={resolved.motion}
      data-style={resolved.style}
    >
      <KLocalizationProvider locale={language}>
        <Story />
      </KLocalizationProvider>
    </main>
  );
};

// Storybook evaluates storySort as plain JavaScript; type it through its context.
const preview: Preview & {
  parameters: {
    options: {
      storySort: (a: StoryIndexEntry, b: StoryIndexEntry) => number;
    };
  };
} = {
  decorators: [withDesignTokens],
  initialGlobals: {
    language: "en",
    brand: "orbit",
    theme: "light",
    density: "standard",
    typeScale: "auto",
    inputMode: "auto",
    windowClass: "auto",
    motion: "auto",
    style: "auto",
    textScale: 1,
  },
  globalTypes: {
    language: {
      description:
        "Component language (gallery example content stays unchanged)",
      toolbar: {
        icon: "globe",
        dynamicTitle: true,
        items: [
          "en",
          "de",
          "fr",
          "es",
          "it",
          "pt",
          "nl",
          "pl",
          "cs",
          "sv",
          "da",
          "nb",
          "fi",
          "tr",
        ],
      },
    },
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
          { value: "auto", title: "Type · auto (window)" },
          { value: "mobile", title: "Mobile · 16, phone headings" },
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
          { value: "auto", title: "Input · auto (pointer media)" },
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
          { value: "auto", title: "Window · auto (viewport)" },
          { value: "compact", title: "Compact · <600" },
          { value: "medium", title: "Medium · 600–839" },
          { value: "expanded", title: "Expanded · 840–1199" },
          { value: "large", title: "Large · 1200–1599" },
          { value: "extra-large", title: "Extra large · ≥1600" },
        ],
      },
    },
    motion: {
      description: "Motion style (Decision 0011); auto follows reduce motion",
      toolbar: {
        icon: "play",
        items: [
          { value: "auto", title: "Motion: auto (Apple)" },
          { value: "apple", title: "Motion: Apple" },
          { value: "expressive", title: "Motion: Expressive" },
          { value: "reduced", title: "Motion: reduced" },
        ],
      },
    },
    style: {
      description: "Style preset (Decision 0014): structure and rhythm",
      toolbar: {
        icon: "paintbrush",
        items: [
          { value: "auto", title: "Style: auto (platform)" },
          { value: "linear", title: "Style: Linear" },
          { value: "apple", title: "Style: Apple" },
          { value: "material", title: "Style: Material" },
        ],
      },
    },
    textScale: {
      description: "Accessibility text-scale preview",
      toolbar: {
        icon: "zoom",
        items: [
          { value: "1", title: "Text 100%" },
          { value: "1.15", title: "Text 115% (common Android default)" },
          { value: "1.3", title: "Text 130%" },
          { value: "1.5", title: "Text 150%" },
          { value: "2", title: "Text 200%" },
          { value: "3", title: "Text 300%" },
        ],
      },
    },
  },
  parameters: {
    layout: "fullscreen",
    options: {
      // Match Widgetbook at every level, independent of file/registration order.
      storySort: (a, b) => {
        const left = `${a.title}/${a.name}`.toLowerCase();
        const right = `${b.title}/${b.name}`.toLowerCase();
        return left < right ? -1 : left > right ? 1 : 0;
      },
    },
    a11y: {
      test: "error",
    },
  },
};

export default preview;
