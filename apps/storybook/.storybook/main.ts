import type { StorybookConfig } from "@storybook/react-vite";

const config: StorybookConfig = {
  stories: ["../src/**/*.stories.@(ts|tsx)"],
  staticDirs: [{ from: "../../widgetbook/assets", to: "/" }],
  addons: ["@storybook/addon-a11y"],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  async viteFinal(config) {
    // The host may install the linked UI package with another React version.
    // All gallery components must share the renderer's hook dispatcher.
    config.resolve = {
      ...config.resolve,
      dedupe: [
        ...new Set([...(config.resolve?.dedupe ?? []), "react", "react-dom"]),
      ],
    };
    return config;
  },
  features: {
    sidebarOnboardingChecklist: false,
    menuOnboardingChecklist: false,
  },
};

export default config;
