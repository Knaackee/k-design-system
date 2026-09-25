import { useEffect, useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KThemeSwitcher,
  KStack,
  KInline,
  KText,
  KButton,
  type KThemeMode,
} from "@k-design-system/ui";

function ThemeSwitcherFixture() {
  const [value, setValue] = useState<KThemeMode>("system");
  const [systemDark, setSystemDark] = useState(
    () => matchMedia("(prefers-color-scheme: dark)").matches,
  );
  useEffect(() => {
    const media = matchMedia("(prefers-color-scheme: dark)");
    const update = () => setSystemDark(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const theme = value === "system" ? (systemDark ? "dark" : "light") : value;
  return (
    <section
      data-theme={theme}
      style={{
        background: "var(--k-color-surface-canvas)",
        color: "var(--k-color-text-primary)",
        padding: "var(--k-space-card-padding)",
        borderRadius: "var(--k-radius-card)",
      }}
    >
      <KStack gap="section" align="stretch">
        <KInline style={{ justifyContent: "space-between" }} align="center">
          <KText variant="heading3">Appearance</KText>
          <KThemeSwitcher value={value} onValueChange={setValue} />
        </KInline>
        <KText>
          Choose Light, Dark or System. The app owns the selected preference.
        </KText>
        <KText variant="bodySmall">
          Selected: {value} · Effective: {theme}
        </KText>
        <KInline gap="control">
          <KButton>Primary action</KButton>
          <KButton variant="secondary">Secondary action</KButton>
        </KInline>
      </KStack>
    </section>
  );
}
export default {
  title: "Actions/ThemeSwitcher",
  component: ThemeSwitcherFixture,
} satisfies Meta<typeof ThemeSwitcherFixture>;
export const Appearance: StoryObj<typeof ThemeSwitcherFixture> = {
  name: "theme-switcher-appearance",
  parameters: { fixtureId: "theme-switcher-appearance" },
};
