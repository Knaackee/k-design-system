import { useEffect, useRef, useState } from "react";
import {
  KButton,
  KChatComposer,
  KDictationState,
  KIcon,
  KMenuButton,
  KStack,
} from "@k-design-system/ui";

/** Deterministic interaction preview. Never captures audio or sends a message. */
export function VoiceComposerFixture({ mobile = false }: { mobile?: boolean }) {
  const [value, setValue] = useState("");
  const [state, setState] = useState(KDictationState.ready);
  const [samples, setSamples] = useState<number[]>([]);
  const [result, setResult] = useState("");
  const [failNext, setFailNext] = useState(false);
  const [calling, setCalling] = useState(false);
  const pending = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(() => () => clearTimeout(pending.current), []);
  useEffect(() => {
    if (state !== KDictationState.recording) return;
    let frame = 0;
    const timer = setInterval(() => {
      frame++;
      const level =
        Math.abs(Math.sin(frame * 0.47) * Math.sin(frame * 0.13)) * 0.12;
      setSamples((previous) => [...previous.slice(-79), level]);
    }, 80);
    return () => clearInterval(timer);
  }, [state]);

  function finish(send: boolean) {
    if (state === KDictationState.processing) return;
    setState(KDictationState.processing);
    pending.current = setTimeout(() => {
      if (failNext) {
        setFailNext(false);
        setState(KDictationState.error);
        return;
      }
      const text = [
        value.trim(),
        "Erinnere mich morgen daran, den Entwurf zu prüfen.",
      ]
        .filter(Boolean)
        .join(" ");
      setState(KDictationState.ready);
      setSamples([]);
      if (send) {
        setResult(text);
        setValue("");
      } else setValue(text);
    }, 1200);
  }

  return (
    <div
      style={{
        width: "100%",
        maxWidth: mobile ? 360 : 920,
        margin: "auto",
        paddingBlock: "var(--k-space-section)",
      }}
    >
      <KStack gap="section" align="stretch">
        <div>
          <h2>Eine Zeile. Schreiben, diktieren, sprechen.</h2>
          <p>
            Interaktive Vorschau · simulierte Aufnahme, kein Mikrofonzugriff.
          </p>
        </div>
        <KChatComposer
          value={value}
          onValueChange={setValue}
          onSubmit={(text) => {
            setResult(text);
            setValue("");
          }}
          leadingTools={
            <KMenuButton
              label="Hinzufügen"
              overflow
              triggerContent={<KIcon name="plus" />}
              disabled={calling}
              actions={[
                {
                  id: "image",
                  label: "Bild auswählen",
                  iconContent: <KIcon name="image" />,
                  onSelect: () => setResult("Bildauswahl geöffnet (Vorschau)."),
                },
                {
                  id: "camera",
                  label: "Foto aufnehmen",
                  iconContent: <KIcon name="camera" />,
                  onSelect: () => setResult("Kamera geöffnet (Vorschau)."),
                },
                {
                  id: "document",
                  label: "Datei auswählen",
                  iconContent: <KIcon name="file" />,
                  onSelect: () =>
                    setResult("Dateiauswahl geöffnet (Vorschau)."),
                },
              ]}
            />
          }
          onStartCall={() => setCalling(true)}
          disabled={calling}
          voiceState={state}
          onVoiceInput={() => {
            if (
              state === KDictationState.recording ||
              state === KDictationState.error
            )
              finish(false);
            else {
              setSamples([]);
              setState(KDictationState.recording);
            }
          }}
          voiceCapture={{
            samples,
            error: "Nicht erkannt. Erneut versuchen.",
            onCancel: () => {
              clearTimeout(pending.current);
              setState(KDictationState.ready);
              setSamples([]);
            },
            onSend: () => finish(true),
          }}
          labels={{
            input: "Nachricht",
            placeholder: "Nachricht …",
            attach: "Datei hinzufügen",
            voice: "Diktat starten",
            stopVoice: "Aufnahme stoppen und Text prüfen",
            cancelVoice: "Aufnahme verwerfen",
            sendVoice: "Diktat direkt senden",
            processingVoice: "Wird transkribiert …",
            errorVoice: "Transkription erneut versuchen",
            call: "Telefonat starten",
            send: "Nachricht senden",
          }}
        />
        {calling ? (
          <KButton onClick={() => setCalling(false)}>
            Demo-Telefonat beenden
          </KButton>
        ) : null}
        <div
          role="status"
          style={{
            minHeight: "var(--k-size-control)",
            color: "var(--k-color-text-muted)",
          }}
        >
          {calling
            ? "Telefonat gestartet (Vorschau)."
            : result
              ? `Demo-Ergebnis: ${result}`
              : "Mikrofon: aufnehmen · Stopp: Text prüfen · Pfeil: direkt senden"}
        </div>
        <div>
          <KButton
            variant="ghost"
            aria-pressed={failNext}
            onClick={() => setFailNext((value) => !value)}
          >
            {failNext
              ? "Nächste Transkription schlägt fehl"
              : "Fehlerfall ausprobieren"}
          </KButton>
        </div>
      </KStack>
    </div>
  );
}
