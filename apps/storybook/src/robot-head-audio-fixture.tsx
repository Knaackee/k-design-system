import { useEffect, useRef, useState } from "react";
import {
  KButton,
  KField,
  KInput,
  KText,
  createKRobotHeadAudioReader,
  type KRobotHeadAudioFrame,
  type KRobotHeadAudioSource,
} from "@k-design-system/ui";

/** Demo owns the player/graph. The library receives samples only. */
export function RobotHeadAudioFixture({
  onSource,
  onPlaying,
}: {
  onSource: (source: KRobotHeadAudioSource | undefined) => void;
  onPlaying: (playing: boolean) => void;
}) {
  const element = useRef<HTMLAudioElement>(null);
  const graph = useRef<{
    context: AudioContext;
    source: MediaElementAudioSourceNode;
    analyser: AnalyserNode;
    read: () => KRobotHeadAudioFrame;
  } | null>(null);
  const objectUrl = useRef<string | null>(null);
  const active = useRef(false);
  const [fileName, setFileName] = useState("");
  const [error, setError] = useState("");
  const [enabled, setEnabled] = useState(false);
  const silence = useRef<KRobotHeadAudioFrame>({
    level: 0,
    bands: Array(12).fill(0),
  });
  const callbacks = useRef({ onSource, onPlaying });
  callbacks.current = { onSource, onPlaying };
  const publish = () =>
    callbacks.current.onSource(() =>
      active.current &&
      !element.current?.paused &&
      !element.current?.ended &&
      !element.current?.seeking &&
      (element.current?.readyState ?? 0) >= 3 &&
      graph.current?.context.state === "running"
        ? graph.current.read()
        : silence.current,
    );
  const prepare = async () => {
    const audio = element.current;
    if (!audio) return;
    if (!graph.current) {
      const context = new AudioContext();
      const source = context.createMediaElementSource(audio);
      const analyser = context.createAnalyser();
      analyser.fftSize = 1024;
      analyser.smoothingTimeConstant = 0.35;
      source.connect(analyser);
      analyser.connect(context.destination);
      graph.current = {
        context,
        source,
        analyser,
        read: createKRobotHeadAudioReader(analyser, { gain: 3 }),
      };
    }
    await graph.current.context.resume();
    publish();
  };
  useEffect(() => {
    const player = element.current;
    return () => {
      active.current = false;
      player?.pause();
      graph.current?.source.disconnect();
      graph.current?.analyser.disconnect();
      void graph.current?.context.close();
      if (objectUrl.current) URL.revokeObjectURL(objectUrl.current);
    };
  }, []);

  return (
    <section className="robot-demo__audio" aria-label="Audio ausprobieren">
      <KField
        label="Audiodatei auswählen"
        helperText="Wird ausschließlich lokal abgespielt. Kein Upload an einen Server."
      >
        <KInput
          type="file"
          accept="audio/*"
          onChange={(event) => {
            const file = event.target.files?.[0];
            if (!file || !element.current) return;
            element.current.pause();
            active.current = false;
            onPlaying(false);
            if (objectUrl.current) URL.revokeObjectURL(objectUrl.current);
            objectUrl.current = URL.createObjectURL(file);
            element.current.src = objectUrl.current;
            element.current.load();
            setFileName(file.name);
            setError("");
            setEnabled(true);
            publish();
          }}
        />
      </KField>
      <audio
        ref={element}
        controls
        aria-label="Lokale Audiodatei"
        preload="metadata"
        onPlay={() => {
          void prepare().then(
            () => {
              active.current = !element.current?.paused;
              onPlaying(active.current);
            },
            () => {
              element.current?.pause();
              setError("Audio konnte nicht gestartet werden.");
            },
          );
        }}
        onPause={() => {
          active.current = false;
          onPlaying(false);
        }}
        onEnded={() => {
          active.current = false;
          onPlaying(false);
        }}
        onError={() => {
          active.current = false;
          onPlaying(false);
          setError(
            "Diese Datei kann der Browser nicht abspielen. Bitte MP3, WAV oder Ogg probieren.",
          );
        }}
      />
      <div className="robot-demo__row">
        <KButton
          disabled={!enabled}
          onClick={() => {
            setError("");
            void prepare()
              .then(() => element.current?.play())
              .catch(() =>
                setError(
                  "Wiedergabe fehlgeschlagen. Bitte die Datei oder Browserfreigabe prüfen.",
                ),
              );
          }}
        >
          Abspielen
        </KButton>
        <KButton
          variant="secondary"
          onClick={() => {
            element.current?.pause();
            active.current = false;
            onPlaying(false);
            onSource(undefined);
            setEnabled(false);
          }}
        >
          Synthetische Animation
        </KButton>
      </div>
      {fileName && <KText variant="label">{fileName}</KText>}
      {error && <KText role="alert">{error}</KText>}
      <KText variant="label">
        Der Mund folgt der Lautstärke, der Equalizer den Frequenzbändern. Keine
        phonetische Lippen-Synchronisierung.
      </KText>
    </section>
  );
}
