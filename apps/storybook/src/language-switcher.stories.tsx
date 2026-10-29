import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KLanguageSwitcher,
  KThemeSwitcher,
  KInline,
  KStack,
  KText,
  type KThemeMode,
} from "@k-design-system/ui";

const languages = [
  { value: "de", label: "Deutsch", flag: "🇩🇪" },
  { value: "en", label: "English", flag: "🇬🇧" },
  { value: "fr", label: "Français", flag: "🇫🇷" },
  { value: "es", label: "Español", flag: "🇪🇸" },
  { value: "it", label: "Italiano", flag: "🇮🇹" },
];
const copy: Record<string, [string, string]> = {
  de: [
    "Willkommen bei Onzeit",
    "Dein Unternehmen. Dein Alltag. Deine Sprache.",
  ],
  en: ["Welcome to Onzeit", "Your business. Your day. Your language."],
  fr: [
    "Bienvenue chez Onzeit",
    "Votre entreprise. Votre quotidien. Votre langue.",
  ],
  es: [
    "Te damos la bienvenida a Onzeit",
    "Tu negocio. Tu día a día. Tu idioma.",
  ],
  it: [
    "Benvenuto su Onzeit",
    "La tua attività. La tua giornata. La tua lingua.",
  ],
};
function LanguageFixture({
  flags = false,
  disabled = false,
}: {
  flags?: boolean;
  disabled?: boolean;
}) {
  const [language, setLanguage] = useState("de");
  const [theme, setTheme] = useState<KThemeMode>("light");
  return (
    <section
      data-theme={theme === "system" ? undefined : theme}
      style={{
        maxWidth: 720,
        width: "100%",
        boxSizing: "border-box",
        padding: "var(--k-space-card-padding)",
        borderRadius: "var(--k-radius-card)",
        background: "var(--k-color-surface-canvas)",
        color: "var(--k-color-text-primary)",
      }}
    >
      <KStack gap="section" align="stretch">
        <KInline
          gap="control"
          align="center"
          wrap
          style={{ justifyContent: "space-between" }}
        >
          <KText variant="heading3">onzeit</KText>
          <KInline gap="control" align="center">
            <KLanguageSwitcher
              value={language}
              onValueChange={setLanguage}
              languages={languages.map(({ flag, ...item }) => ({
                ...item,
                flag: flags ? flag : undefined,
              }))}
              label="Sprache / Language"
              disabled={disabled}
            />
            <KThemeSwitcher value={theme} onValueChange={setTheme} />
          </KInline>
        </KInline>
        <KStack gap="control" lang={language}>
          <KText variant="heading2">{copy[language]![0]}</KText>
          <KText>{copy[language]![1]}</KText>
        </KStack>
      </KStack>
    </section>
  );
}
export default {
  title: "Actions/LanguageSwitcher",
  component: LanguageFixture,
} satisfies Meta<typeof LanguageFixture>;
type Story = StoryObj<typeof LanguageFixture>;
export const Default: Story = {
  parameters: { fixtureId: "language-switcher-default" },
};
export const WithFlags: Story = {
  args: { flags: true },
  parameters: { fixtureId: "language-switcher-flags" },
};
export const Disabled: Story = {
  args: { disabled: true },
  parameters: { fixtureId: "language-switcher-disabled" },
};
