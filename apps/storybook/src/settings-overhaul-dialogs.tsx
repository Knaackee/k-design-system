import { useEffect, useState, type ReactNode } from "react";
import {
  KButton,
  KField,
  KInput,
  KIcon,
  KStack,
  KProgress,
} from "@k-design-system/ui";

import markUrl from "./offer-overview-mark.svg";
import { ReviewAdaptiveDialog } from "./review-overlay-preference.js";

export function SettingsOverhaulDialog({
  title,
  presentationRootId,
  onClose,
  onComplete,
  children,
}: {
  title: string | null;
  presentationRootId: string;
  onClose: () => void;
  onComplete: (message: string) => void;
  children?: ReactNode;
}) {
  const [current, setCurrent] = useState("");
  const [password, setPassword] = useState("");
  const [repeat, setRepeat] = useState("");
  const [visible, setVisible] = useState(false);
  const [confirm, setConfirm] = useState("");
  const [download, setDownload] = useState<"idle" | "loading" | "ready">(
    "idle",
  );
  const [progress, setProgress] = useState(0);
  useEffect(() => {
    setCurrent("");
    setPassword("");
    setRepeat("");
    setVisible(false);
    setConfirm("");
    setDownload("idle");
    setProgress(0);
  }, [title]);
  useEffect(() => {
    if (download !== "loading") return;
    const timer = window.setInterval(
      () => setProgress((p) => Math.min(100, p + 10)),
      180,
    );
    return () => window.clearInterval(timer);
  }, [download]);
  useEffect(() => {
    if (progress === 100) setDownload("ready");
  }, [progress]);
  const centered = { justifyContent: "center" } as const;
  const checks = [
    { label: "Mindestens 12 Zeichen", ok: password.length >= 12 },
    {
      label: "Buchstaben und Zahlen",
      ok: /[A-Za-z]/.test(password) && /\d/.test(password),
    },
    {
      label: "Passwörter stimmen überein",
      ok: password.length > 0 && password === repeat,
    },
  ];
  return (
    <ReviewAdaptiveDialog
      presentationRootId={presentationRootId}
      open={!!title}
      onOpenChange={(v) => {
        if (!v) onClose();
      }}
      title={title ?? ""}
      closeLabel="Schließen"
      preferPageSheet={title !== "Abmelden?" && title !== "Konto löschen?"}
      showClose={title !== "Abmelden?" && title !== "Konto löschen?"}
      description={
        title === "Name bearbeiten"
          ? "Dein Profil, wie du es möchtest."
          : title === "E-Mail ändern"
            ? "Halte deine Kontaktdaten aktuell."
            : undefined
      }
      className={[
        "so-dialog",
        ["Abmelden?", "Konto löschen?", "Update verfügbar"].includes(
          title ?? "",
        )
          ? "so-dialog--focused"
          : "",
      ]
        .filter(Boolean)
        .join(" ")}
      bodyClassName="so-dialog-body"
    >
      {title === "Passwort ändern" ? (
        <KStack gap="control" align="stretch">
          <KField label="Aktuelles Passwort">
            <KInput
              autoComplete="current-password"
              type={visible ? "text" : "password"}
              value={current}
              onChange={(e) => setCurrent(e.target.value)}
            />
          </KField>
          <KField label="Neues Passwort">
            <KInput
              autoComplete="new-password"
              type={visible ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </KField>
          <KField label="Neues Passwort wiederholen">
            <KInput
              autoComplete="new-password"
              type={visible ? "text" : "password"}
              value={repeat}
              onChange={(e) => setRepeat(e.target.value)}
            />
          </KField>
          <KButton variant="ghost" onClick={() => setVisible(!visible)}>
            <KIcon name={visible ? "eye-off" : "eye"} size={18} />
            {visible ? "Passwörter verbergen" : "Passwörter anzeigen"}
          </KButton>
          <ul className="so-password-rules">
            {checks.map((c) => (
              <li key={c.label} data-ok={c.ok}>
                <span>
                  <KIcon name={c.ok ? "check" : "circle"} size={16} />
                </span>
                {c.label}
              </li>
            ))}
          </ul>
          <KButton
            fullWidth
            style={centered}
            disabled={!current || !checks.every((c) => c.ok)}
            onClick={() =>
              onComplete(
                "Passwortformular geprüft – kein echtes Passwort geändert.",
              )
            }
          >
            Passwort ändern
          </KButton>
        </KStack>
      ) : title === "Abmelden?" ? (
        <KStack gap="action" align="stretch">
          <p>
            Du wirst auf diesem Gerät abgemeldet. Deine Daten bleiben erhalten.
          </p>
          <KButton
            fullWidth
            style={centered}
            className="so-danger-action"
            onClick={() =>
              onComplete(
                "Abmelden in der Galerie bestätigt. Deine echte Sitzung bleibt erhalten.",
              )
            }
          >
            Abmelden
          </KButton>
          <KButton
            fullWidth
            style={centered}
            variant="secondary"
            onClick={onClose}
          >
            Abbrechen
          </KButton>
        </KStack>
      ) : title === "Konto löschen?" ? (
        <KStack gap="action" align="stretch">
          <p>
            Das Löschen deines Kontos betrifft auch deine Buchungsseite und die
            zugehörigen Daten.
          </p>
          <p className="so-muted">
            Designentwurf: Löschfristen und Wiederherstellung sind noch nicht
            freigegeben. Hier werden keine Daten gelöscht.
          </p>
          <KField label="Zum Bestätigen „LÖSCHEN“ eingeben">
            <KInput
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              autoComplete="off"
            />
          </KField>
          <KButton
            fullWidth
            style={centered}
            className="so-danger-action"
            disabled={confirm !== "LÖSCHEN"}
            onClick={() =>
              onComplete(
                "Bestätigung in der Vorschau geprüft – keine Löschung ausgelöst.",
              )
            }
          >
            Konto löschen
          </KButton>
          <KButton
            fullWidth
            style={centered}
            variant="secondary"
            onClick={onClose}
          >
            Abbrechen
          </KButton>
        </KStack>
      ) : title === "Update verfügbar" ? (
        <KStack gap="action" align="stretch">
          <div className="so-update-hero">
            <img src={markUrl} alt="" width={30} height={36} />
            <span>
              <b>Onzeit 0.1.1</b>
              <small>Installiert: 0.1.0+1 · 18 MB</small>
            </span>
          </div>
          {download === "idle" ? (
            <>
              <h3 className="so-section-title">Neu in dieser Version</h3>
              <ul className="so-release-list">
                <li>Fahrzeiten zwischen deinen Terminen auf „Heute“</li>
                <li>Feiertage nach Bundesland übernehmen</li>
                <li>Zonen: Zeiten aus einer anderen Zone übernehmen</li>
                <li>Fehlerbehebungen</li>
              </ul>
              <p className="so-muted">
                Der folgende Ablauf simuliert das Android-Update. Es wird keine
                Datei heruntergeladen oder installiert.
              </p>
              <KButton
                fullWidth
                style={centered}
                onClick={() => setDownload("loading")}
              >
                <KIcon name="download" size={18} />
                Herunterladen & installieren
              </KButton>
              <KButton
                fullWidth
                style={centered}
                variant="secondary"
                onClick={onClose}
              >
                Später
              </KButton>
            </>
          ) : download === "loading" ? (
            <>
              <div className="so-download-meta">
                <strong>Wird heruntergeladen …</strong>
                <span>{Math.round((18 * progress) / 100)} von 18 MB</span>
              </div>
              <KProgress
                aria-label="Demo-Download"
                value={progress}
                max={100}
              />
              <p>Du kannst Onzeit währenddessen weiter benutzen.</p>
              <KButton
                fullWidth
                style={centered}
                variant="secondary"
                onClick={() => {
                  setDownload("idle");
                  setProgress(0);
                }}
              >
                Abbrechen
              </KButton>
            </>
          ) : (
            <>
              <div className="so-ready">
                <KIcon name="check" />
                Download abgeschlossen · Simulation
              </div>
              <p>
                Auf Android würde anschließend die Installation angeboten.
                Offene Eingaben vorher speichern.
              </p>
              <KButton
                fullWidth
                style={centered}
                onClick={() =>
                  onComplete(
                    "Installationsschritt geprüft – es wurde keine App installiert.",
                  )
                }
              >
                Jetzt installieren
              </KButton>
              <KButton
                fullWidth
                style={centered}
                variant="secondary"
                onClick={onClose}
              >
                Beim nächsten Start
              </KButton>
            </>
          )}
        </KStack>
      ) : (
        children || (
          <p>
            Die Anwendung öffnet hier „{title}“. Die Designer-Vorlage enthält
            für diesen Bereich noch keine ausgearbeitete Inhaltsseite. Es werden
            keine verbindlichen Texte oder externe Dienste vorgetäuscht.
          </p>
        )
      )}
    </ReviewAdaptiveDialog>
  );
}
