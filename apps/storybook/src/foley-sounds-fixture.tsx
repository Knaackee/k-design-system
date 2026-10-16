import { useEffect, useRef, useState } from "react";
import {
  KButton,
  KIcon,
  KSlider,
  KSwitch,
  KSurface,
  KText,
  type KIconName,
} from "@k-design-system/ui";
import "./foley-sounds-fixture.css";

import rawMetadata from "../../widgetbook/assets/foley/export-metadata.json?raw";
interface Cue {
  id: string;
  name: string;
  family: string;
  category: string;
  description: string;
  recommended: boolean;
}
const cues = Object.values(
  (JSON.parse(rawMetadata) as { recordings: Record<string, Cue> }).recordings,
);
const recommended = [
  "tap",
  "swoosh",
  "bubble",
  "success",
  "warning",
  "complete",
].map((id) => cues.find((cue) => cue.id === id)!);
const groups = [...new Set(cues.map((cue) => cue.family))];
const icons: Record<string, KIconName> = {
  pointer: "mouse-pointer-2",
  press: "mouse-pointer-2",
  toggle: "toggle-left",
  feedback: "circle-check",
  notify: "bell",
  motion: "move-right",
  state: "flag",
};

export function FoleySoundsFixture() {
  const player = useRef<HTMLAudioElement | null>(null);
  const request = useRef(0);
  const [expanded, setExpanded] = useState(false);
  const [volume, setVolume] = useState(50);
  const [muted, setMuted] = useState(false);
  const [eventsEnabled, setEventsEnabled] = useState(true);
  const [chatEnabled, setChatEnabled] = useState(true);
  const [toolsEnabled, setToolsEnabled] = useState(true);
  const [eventStatus, setEventStatus] = useState(
    "Bereit für ein Beispielereignis.",
  );
  const [active, setActive] = useState<string | null>(null);
  const [status, setStatus] = useState(
    "Bereit zum Anhören. Wähle einen Klang.",
  );

  useEffect(
    () => () => {
      request.current += 1;
      player.current?.pause();
    },
    [],
  );

  function changeVolume(value: number) {
    setVolume(value);
    if (player.current) player.current.volume = value / 100;
    if (value === 0) stopPreview();
  }

  function stopPreview() {
    request.current += 1;
    player.current?.pause();
    if (active) setStatus("Wiedergabe beendet.");
    setActive(null);
  }

  function toggleMute() {
    const next = !muted;
    setMuted(next);
    if (player.current) player.current.muted = next;
    if (next) stopPreview();
    setStatus(next ? "Ton ist stummgeschaltet." : "Ton ist eingeschaltet.");
  }

  function eventPreview(
    category: "chat" | "tools",
    cueId: string,
    message: string,
  ) {
    setEventStatus(message);
    if (
      !eventsEnabled ||
      !(category === "chat" ? chatEnabled : toolsEnabled) ||
      muted ||
      volume === 0
    )
      return;
    const cue = cues.find((item) => item.id === cueId);
    if (cue) void audition(cue);
  }

  async function audition(cue: (typeof cues)[number]) {
    const current = ++request.current;
    player.current?.pause();
    const audio = new Audio(`/foley/${cue.id}.wav`);
    player.current = audio;
    audio.volume = volume / 100;
    audio.muted = muted;
    setActive(cue.id);
    setStatus(`${cue.name} wird abgespielt.`);
    audio.onended = () => {
      if (current !== request.current) return;
      setActive(null);
      setStatus(`${cue.name} angehört.`);
    };
    try {
      await audio.play();
    } catch {
      if (current !== request.current) return;
      setActive(null);
      setStatus(
        "Klang konnte nicht abgespielt werden. Bitte erneut versuchen.",
      );
    }
  }

  const renderCue = (cue: Cue) => (
    <KSurface
      as="article"
      radius="card"
      key={cue.id}
      className="foley-review__card"
      data-playing={active === cue.id || undefined}
    >
      <div className="foley-review__card-top">
        <KIcon name={icons[cue.family]} />
        <KText variant="caption">{cue.category}</KText>
      </div>
      <KText as="h2" variant="heading4">
        {cue.name}
      </KText>
      <KText variant="bodySmall" className="foley-review__description">
        {cue.description}
      </KText>
      <KButton
        variant="secondary"
        disabled={muted || volume === 0}
        onClick={() => void audition(cue)}
        aria-label={`${cue.name} anhören`}
      >
        <KIcon name="play" /> {active === cue.id ? "Erneut anhören" : "Anhören"}
      </KButton>
    </KSurface>
  );

  return (
    <main className="foley-review" data-fixture-id="foley-sounds-review">
      <header className="foley-review__header">
        <KText variant="caption">FOLEY · KLANGPALETTE</KText>
        <KText as="h1" variant="heading2">
          Kleine Klänge. Klares Feedback.
        </KText>
        <KText>
          28 kurze Signale für bewusste Momente. Sechs Favoriten als Einstieg.
        </KText>
      </header>
      <KSurface tone="subtle" className="foley-review__controls">
        <div className="foley-review__volume">
          <KText variant="label">Lautstärke · {volume}%</KText>
          <KSlider
            label="Lautstärke"
            value={volume}
            onValueChange={changeVolume}
            valueLabel={(value) => `${value}%`}
          />
        </div>
        <KButton variant="secondary" aria-pressed={muted} onClick={toggleMute}>
          <KIcon name={muted ? "volume-x" : "volume-2"} />
          {muted ? "Ton einschalten" : "Stummschalten"}
        </KButton>
      </KSurface>
      <KSurface
        as="section"
        className="foley-review__events"
        aria-label="Ereignistöne"
      >
        <KText as="h2" variant="heading4">
          Ereignistöne
        </KText>
        <KText variant="bodySmall">
          Feedback für Chat und Tool-Aktivitäten. Jederzeit abschaltbar.
        </KText>
        <div className="foley-review__event-switches">
          <div className="foley-review__event-switch">
            <KText variant="label">Ereignistöne aktivieren</KText>
            <KSwitch
              showLabel={false}
              label="Ereignistöne aktivieren"
              checked={eventsEnabled}
              onCheckedChange={(value) => {
                setEventsEnabled(value);
                if (!value) stopPreview();
              }}
            />
          </div>
          <div className="foley-review__event-switch">
            <KText variant="label">Chat</KText>
            <KSwitch
              showLabel={false}
              label="Chat"
              checked={chatEnabled}
              disabled={!eventsEnabled}
              onCheckedChange={(value) => {
                setChatEnabled(value);
                if (!value) stopPreview();
              }}
            />
          </div>
          <div className="foley-review__event-switch">
            <KText variant="label">Tool-Aktivitäten</KText>
            <KSwitch
              showLabel={false}
              label="Tool-Aktivitäten"
              checked={toolsEnabled}
              disabled={!eventsEnabled}
              onCheckedChange={(value) => {
                setToolsEnabled(value);
                if (!value) stopPreview();
              }}
            />
          </div>
        </div>
        <div className="foley-review__event-actions">
          <KButton
            variant="secondary"
            onClick={() =>
              eventPreview("chat", "bubble", "Nachricht empfangen.")
            }
          >
            Nachricht empfangen
          </KButton>
          <KButton
            variant="secondary"
            onClick={() =>
              eventPreview("chat", "warning", "Rückfrage gestellt.")
            }
          >
            Rückfrage
          </KButton>
          <KButton
            variant="secondary"
            onClick={() =>
              eventPreview("tools", "ready", "Suche abgeschlossen.")
            }
          >
            Suche abgeschlossen
          </KButton>
          <KButton
            variant="secondary"
            onClick={() =>
              eventPreview("tools", "tick", "Suche fehlgeschlagen.")
            }
          >
            Suche fehlgeschlagen
          </KButton>
        </div>
        <KText role="status" aria-live="polite" variant="bodySmall">
          {eventStatus}
        </KText>
      </KSurface>
      <KText as="h2" variant="heading4" className="foley-review__section-title">
        Empfohlene Klänge
      </KText>
      <div className="foley-review__grid">{recommended.map(renderCue)}</div>
      <div className="foley-review__all">
        <KButton
          variant="secondary"
          aria-expanded={expanded}
          aria-controls="foley-all-cues"
          onClick={() => setExpanded(!expanded)}
        >
          <KIcon name={expanded ? "chevron-up" : "chevron-down"} />
          {expanded ? "Weitere Klänge ausblenden" : "Alle 28 Klänge entdecken"}
        </KButton>
        {expanded && (
          <section id="foley-all-cues" aria-label="Weitere Klänge">
            {groups.map((family) => {
              const group = cues.filter(
                (cue) => cue.family === family && !cue.recommended,
              );
              return (
                <section key={family} className="foley-review__family">
                  <KText
                    as="h2"
                    variant="heading4"
                    className="foley-review__section-title"
                  >
                    {group[0].category}
                  </KText>
                  <div className="foley-review__grid">
                    {group.map(renderCue)}
                  </div>
                </section>
              );
            })}
          </section>
        )}
      </div>
      <KText
        role="status"
        aria-live="polite"
        variant="bodySmall"
        className="foley-review__status"
      >
        {status}
      </KText>
      <footer className="foley-review__footer">
        <KText variant="caption">
          Klänge ergänzen sichtbares Feedback. Sie starten nur auf Klick.
        </KText>
        <KText variant="caption">
          Foley · Default · gleiche WAV-Aufnahmen auf Web und Flutter.
        </KText>
      </footer>
    </main>
  );
}
