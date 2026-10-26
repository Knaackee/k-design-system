import { useEffect, useRef, useState } from "react";
import {
  KButton,
  KProgressDots,
  KField,
  KIcon,
  KInline,
  KInput,
  KRadioGroup,
  KStack,
  KText,
} from "@k-design-system/ui";
import { SettingsAppFixture } from "./settings-app-fixture.js";
import "./onboarding-app-fixture.css";

const steps = [
  "Willkommen",
  "Dein Profil",
  "Dein Workspace",
  "Dein Team",
  "Bereit zum Start",
];

/** Consumer-owned onboarding example: no account creation or invitations are sent. */
export function OnboardingAppFixture() {
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [workspace, setWorkspace] = useState("");
  const [mode, setMode] = useState("create");
  const [code, setCode] = useState("");
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);
  const root = useRef<HTMLElement>(null);
  const heading = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const viewport = window.visualViewport;
    if (!viewport) return;
    const update = () => {
      const keyboard =
        window.innerHeight - viewport.height > 120 &&
        root.current?.contains(document.activeElement) &&
        document.activeElement instanceof HTMLInputElement;
      root.current?.toggleAttribute("data-keyboard", Boolean(keyboard));
      root.current?.style.setProperty(
        "--onboarding-visible-height",
        `${viewport.height}px`,
      );
    };
    update();
    viewport.addEventListener("resize", update);
    document.addEventListener("focusin", update);
    document.addEventListener("focusout", update);
    return () => {
      viewport.removeEventListener("resize", update);
      document.removeEventListener("focusin", update);
      document.removeEventListener("focusout", update);
    };
  }, []);
  useEffect(() => {
    heading.current?.focus();
  }, [step]);
  function advance(skip = false) {
    if (step === 1 && !name.trim())
      return setError("Bitte gib deinen Namen ein.");
    if (step === 2 && !(mode === "create" ? workspace : code).trim())
      return setError(
        mode === "create"
          ? "Bitte benenne deinen Workspace."
          : "Bitte gib einen Einladungscode ein.",
      );
    if (
      step === 3 &&
      !skip &&
      email &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    )
      return setError("Bitte gib eine gültige E-Mail-Adresse ein.");
    if (skip) setEmail("");
    setError("");
    setStep(step + 1);
  }
  if (done)
    return (
      <SettingsAppFixture
        emptyWorkspace
        workspaceName={mode === "create" ? workspace.trim() : "Team Workspace"}
      />
    );
  return (
    <main className="onboarding-app" ref={root}>
      <header className="onboarding-app__brand">
        <KInline gap="control">
          <KIcon name="orbit" />
          <KText variant="heading5">Orbit</KText>
        </KInline>
        <KText variant="caption">Workspace einrichten</KText>
      </header>
      <form
        className="onboarding-app__form"
        onSubmit={(event) => {
          event.preventDefault();
          if (step === 4) setDone(true);
          else advance();
        }}
      >
        <section className="onboarding-app__stage">
          <div className="onboarding-app__content">
            <KStack gap="section" align="stretch">
              <KStack gap="control" align="stretch">
                <div className="onboarding-app__symbol" aria-hidden="true">
                  <KIcon
                    name={
                      (
                        [
                          "orbit",
                          "user",
                          "building",
                          "users",
                          "circle-check",
                        ] as const
                      )[step]!
                    }
                    size={32}
                  />
                </div>
                <div
                  ref={heading}
                  tabIndex={-1}
                  className="onboarding-app__heading"
                >
                  <KText as="h1" variant="heading2">
                    {steps[step]}
                  </KText>
                </div>
                <KText variant="bodySmall">
                  {
                    [
                      "Ein gemeinsamer Ort für Projekte und Zusammenarbeit.",
                      "So erkennen dich deine Teammitglieder.",
                      "Erstelle einen Arbeitsbereich oder tritt einem Team bei.",
                      "Zusammen geht es leichter. Diesen Schritt kannst du überspringen.",
                      "Dein Arbeitsbereich ist vorbereitet.",
                    ][step]
                  }
                </KText>
              </KStack>
              {step === 0 && (
                <KStack gap="action" align="stretch">
                  {[
                    ["user", "Dein Profil", "Zeige deinem Team, wer du bist."],
                    [
                      "building",
                      "Dein Workspace",
                      "Ein Ort für eure Projekte und Aufgaben.",
                    ],
                    [
                      "users",
                      "Dein Team",
                      "Lade andere ein – jetzt oder später.",
                    ],
                  ].map(([icon, title, description]) => (
                    <div className="onboarding-app__benefit" key={title}>
                      <KIcon name={icon as "user" | "building" | "users"} />
                      <KStack gap="control">
                        <KText variant="label">{title}</KText>
                        <KText variant="bodySmall">{description}</KText>
                      </KStack>
                    </div>
                  ))}
                </KStack>
              )}
              {step === 1 && (
                <KField
                  label="Dein Name"
                  required
                  errorText={error || undefined}
                >
                  <KInput
                    className="onboarding-app__control"
                    autoComplete="name"
                    value={name}
                    onChange={(e) => {
                      setName(e.target.value);
                      setError("");
                    }}
                  />
                </KField>
              )}
              {step === 2 && (
                <KStack gap="section" align="stretch">
                  <KRadioGroup
                    label="Arbeitsbereich"
                    value={mode}
                    onValueChange={(value) => {
                      setMode(value);
                      setError("");
                    }}
                    items={[
                      { value: "create", label: "Workspace erstellen" },
                      { value: "join", label: "Mit Einladung beitreten" },
                    ]}
                  />
                  {mode === "create" ? (
                    <KField
                      label="Workspace-Name"
                      required
                      errorText={error || undefined}
                    >
                      <KInput
                        className="onboarding-app__control"
                        value={workspace}
                        onChange={(e) => {
                          setWorkspace(e.target.value);
                          setError("");
                        }}
                      />
                    </KField>
                  ) : (
                    <KField
                      label="Einladungscode"
                      required
                      helperText="In dieser Demo wird jeder nicht leere Code akzeptiert."
                      errorText={error || undefined}
                    >
                      <KInput
                        className="onboarding-app__control"
                        value={code}
                        onChange={(e) => {
                          setCode(e.target.value);
                          setError("");
                        }}
                      />
                    </KField>
                  )}
                </KStack>
              )}
              {step === 3 && (
                <KField
                  label="E-Mail-Adresse"
                  helperText="Optional. Die Einladung wird hier nur vorgemerkt."
                  errorText={error || undefined}
                >
                  <KInput
                    className="onboarding-app__control"
                    value={email}
                    autoComplete="email"
                    inputMode="email"
                    onChange={(e) => {
                      setEmail(e.target.value);
                      setError("");
                    }}
                  />
                </KField>
              )}
              {step === 4 && (
                <KStack gap="action">
                  <KText>Profil: {name}</KText>
                  <KText>
                    Workspace:{" "}
                    {mode === "create" ? workspace : "Team Workspace"}
                  </KText>
                  <KText>
                    {email
                      ? `Einladung vorgemerkt: ${email}`
                      : "Du kannst dein Team später einladen."}
                  </KText>
                </KStack>
              )}
            </KStack>
          </div>
        </section>
        <footer className="onboarding-app__footer">
          <div className="onboarding-app__footer-content">
            <KProgressDots
              activeIndex={step}
              count={steps.length}
              label="Einrichtung"
              className="onboarding-app__progress"
            />
            <div className="onboarding-app__actions">
              <div>
                {step > 0 && (
                  <KButton
                    className="onboarding-app__control"
                    type="button"
                    variant="ghost"
                    onClick={() => {
                      setError("");
                      setStep(step - 1);
                    }}
                  >
                    Zurück
                  </KButton>
                )}
              </div>
              <div className="onboarding-app__forward">
                <KButton className="onboarding-app__control" type="submit">
                  {step === 0
                    ? "Loslegen"
                    : step === 4
                      ? "Zum Workspace"
                      : "Weiter"}
                </KButton>
                {step === 3 && (
                  <KButton
                    className="onboarding-app__control"
                    type="button"
                    variant="ghost"
                    onClick={() => advance(true)}
                  >
                    Überspringen
                  </KButton>
                )}
              </div>
            </div>
            <KText variant="caption" className="onboarding-app__demo-note">
              Demo: Keine Konten oder Einladungen werden erstellt.
            </KText>
          </div>
        </footer>
      </form>
    </main>
  );
}
