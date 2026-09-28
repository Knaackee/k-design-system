import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import {
  KButton,
  KField,
  KInput,
  KLink,
  KStack,
  KText,
} from "@k-design-system/ui";
import "./login-showcase.css";

function AssetryLogin() {
  const [message, setMessage] = useState("");
  return (
    <div className="login-showcase" lang="de">
      <section
        className="login-showcase-context"
        data-theme="dark"
        aria-labelledby="login-context-title"
      >
        <KText variant="heading3">Assetry</KText>
        <KStack gap="action" className="login-showcase-copy">
          <KText variant="caption">PORTFOLIO INTELLIGENCE</KText>
          <KText id="login-context-title" variant="heading1">
            Mehr aus deinen Immobilien machen.
          </KText>
          <KText>
            Assetry zeigt dir, wo sich Investitionen lohnen und wie du
            Betriebskosten nachhaltig senken kannst.
          </KText>
        </KStack>
      </section>
      <section
        className="login-showcase-panel"
        aria-labelledby="showcase-login-title"
      >
        <KStack
          align="stretch"
          gap="section"
          className="login-showcase-content"
        >
          <KStack gap="action">
            <KText variant="caption">GESCHÜTZTER BEREICH</KText>
            <KText as="h2" id="showcase-login-title" variant="heading1">
              Anmelden
            </KText>
            <KText>
              Nutze die Zugangsdaten, die dir für Assetry bereitgestellt wurden.
            </KText>
          </KStack>
          <form
            data-density="spacious"
            onSubmit={(event) => {
              event.preventDefault();
              setMessage(
                "Demo: Eingaben geprüft. Es wurden keine Zugangsdaten gesendet.",
              );
            }}
          >
            <KStack gap="action" align="stretch">
              <KField label="Benutzername" required>
                <KInput name="username" autoComplete="off" />
              </KField>
              <KField label="Passwort" required>
                <KInput
                  name="password"
                  type="password"
                  minLength={12}
                  autoComplete="off"
                />
              </KField>
              <KButton
                type="submit"
                fullWidth
                className="login-showcase-submit"
              >
                Anmelden
              </KButton>
              <KLink
                href="#login-demo-status"
                variant="standalone"
                className="login-showcase-recovery"
                onClick={(event) => {
                  event.preventDefault();
                  setMessage(
                    "Demo: Hier würde die Passwort-Wiederherstellung geöffnet.",
                  );
                }}
              >
                Passwort vergessen?
              </KLink>
            </KStack>
          </form>
          <KText variant="bodySmall">
            Noch kein Zugang? Kontaktiere deine Assetry-Ansprechperson.
          </KText>
          <KText id="login-demo-status" role="status" aria-live="polite">
            {message || "Showcase – bitte nur Testdaten eingeben."}
          </KText>
        </KStack>
      </section>
    </div>
  );
}

const meta = {
  title: "Showcase/Login",
  component: AssetryLogin,
  parameters: { layout: "fullscreen", fixtureId: "showcase-login-assetry" },
} satisfies Meta<typeof AssetryLogin>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Assetry: Story = {};
