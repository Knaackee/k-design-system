import { useState } from "react";
import { KButton, KField, KInput, KStack, KIcon } from "@k-design-system/ui";
export function ProfileDialog({
  title,
  onDone,
}: {
  title: string;
  onDone: (message: string) => void;
}) {
  const [email, setEmail] = useState("denis@example.com");
  const [password, setPassword] = useState("");
  const [repeat, setRepeat] = useState("");
  const [current, setCurrent] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [visible, setVisible] = useState(false);
  if (title === "E-Mail ändern")
    return (
      <KStack gap="action" align="stretch">
        <KField label="Neue E-Mail-Adresse">
          <KInput
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </KField>
        <p className="sg-muted">
          Die neue Adresse muss in der Anwendung per E-Mail bestätigt werden.
          Hier wird keine E-Mail verschickt.
        </p>
        <KButton
          disabled={!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)}
          onClick={() => onDone("E-Mail-Änderung in der Vorschau bestätigt.")}
        >
          Bestätigung anfordern
        </KButton>
      </KStack>
    );
  if (title === "Passwort ändern")
    return (
      <KStack gap="action" align="stretch">
        <KField label="Aktuelles Passwort">
          <KInput
            type="password"
            value={current}
            autoComplete="off"
            onChange={(e) => setCurrent(e.target.value)}
          />
        </KField>
        <KField label="Neues Passwort">
          <KInput
            type={visible ? "text" : "password"}
            value={password}
            autoComplete="off"
            onChange={(e) => setPassword(e.target.value)}
          />
        </KField>
        <KField label="Passwort wiederholen">
          <KInput
            type={visible ? "text" : "password"}
            value={repeat}
            autoComplete="off"
            onChange={(e) => setRepeat(e.target.value)}
          />
        </KField>
        <KButton variant="ghost" onClick={() => setVisible(!visible)}>
          <KIcon name={visible ? "eye-off" : "eye"} />
          {visible ? "Passwort verbergen" : "Passwort anzeigen"}
        </KButton>
        <div className="sg-check-list">
          {[
            [password.length >= 8, "Mindestens 8 Zeichen"],
            [
              /[A-Z]/.test(password) && /[a-z]/.test(password),
              "Groß- und Kleinbuchstaben",
            ],
            [/[0-9]/.test(password), "Mindestens eine Zahl"],
            [!!password && password === repeat, "Passwörter stimmen überein"],
          ].map(([ok, label]) => (
            <span
              key={String(label)}
              className={ok ? "sg-success" : "sg-muted"}
            >
              <KIcon name={ok ? "circle-check" : "circle"} size={20} /> {label}
            </span>
          ))}
        </div>
        <KButton
          disabled={
            !current ||
            password.length < 8 ||
            password !== repeat ||
            !/[A-Z]/.test(password) ||
            !/[a-z]/.test(password) ||
            !/[0-9]/.test(password)
          }
          onClick={() =>
            onDone(
              "Passwortänderung simuliert. Es wurde kein Passwort gespeichert.",
            )
          }
        >
          Passwort ändern
        </KButton>
      </KStack>
    );
  if (title === "Konto löschen?")
    return (
      <KStack gap="action" align="stretch">
        <p>
          Diese Aktion entfernt in der Anwendung das Konto. In der Galerie wird
          nichts gelöscht.
        </p>
        <KField label="Zum Bestätigen „LÖSCHEN“ eingeben">
          <KInput
            value={confirmation}
            onChange={(e) => setConfirmation(e.target.value)}
          />
        </KField>
        <KButton
          variant="secondary"
          className="sg-danger"
          disabled={confirmation.trim().toUpperCase() !== "LÖSCHEN"}
          onClick={() => onDone("Kontolöschung in der Vorschau bestätigt.")}
        >
          Konto löschen
        </KButton>
      </KStack>
    );
  return (
    <KStack gap="action" align="stretch">
      <p>Du wirst auf diesem Gerät abgemeldet. Deine Daten bleiben erhalten.</p>
      <KButton
        variant="secondary"
        className="sg-danger"
        onClick={() =>
          onDone("Abmelden simuliert. Deine Sitzung bleibt bestehen.")
        }
      >
        Abmelden
      </KButton>
    </KStack>
  );
}
