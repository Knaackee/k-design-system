// Run with FOLEY_OFFLINE_MODULE pointing to an installed node-web-audio-api
// index.js. The renderer is a development tool, not a gallery dependency.
import { mkdir, writeFile, copyFile, readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { pathToFileURL } from "node:url";
import { set, toWav, version, cues } from "@foleyjs/core";

const recommended = [
  "tap",
  "swoosh",
  "bubble",
  "success",
  "warning",
  "complete",
];
const categories = {
  pointer: "Zeiger & Fokus",
  press: "Interaktion",
  toggle: "Umschalten",
  feedback: "Feedback",
  notify: "Nachricht",
  motion: "Bewegung",
  state: "Status & Abschluss",
};
const descriptions = {
  tick: "Eine kleine Stufe begleiten, etwa einen Regler verändern.",
  hover: "Einen Fokuswechsel mit einem leichten Ton begleiten.",
  glide: "Den Wechsel auf ein größeres Ziel begleiten.",
  pop: "Ein kleines Element sichtbar werden lassen.",
  press: "Das Drücken eines Bedienelements bestätigen.",
  release: "Das Loslassen eines Bedienelements begleiten.",
  tap: "Eine bewusste Aktion bestätigen, etwa einen Eintrag auswählen.",
  thock: "Eine Eingabe mit einem gedämpften Tastenton begleiten.",
  on: "Das Aktivieren einer Einstellung bestätigen.",
  off: "Das Deaktivieren einer Einstellung bestätigen.",
  switch: "Einen bewussten Moduswechsel markieren.",
  latch: "Das Einrasten oder Fixieren eines Elements bestätigen.",
  success: "Eine erfolgreiche Aktion bestätigen, etwa Änderungen speichern.",
  error:
    "Eine fehlgeschlagene Aktion zusammen mit einem sichtbaren Fehler melden.",
  warning: "Auf einen prüfbaren Hinweis aufmerksam machen.",
  denied: "Eine erreichte Grenze oder nicht verfügbare Aktion signalisieren.",
  chime: "Eine wichtige neue Information ankündigen.",
  ping: "Auf einen kurzen neuen Hinweis aufmerksam machen.",
  bell: "Eine Erinnerung mit einem weichen Glockenton begleiten.",
  bubble: "Auf eine neue Nachricht hinweisen, ohne zu unterbrechen.",
  swoosh: "Einen Wechsel begleiten, etwa ein Panel öffnen.",
  whoosh: "Das Schließen oder Verlassen einer Fläche begleiten.",
  drop: "Das Ablegen eines Elements bestätigen.",
  rise: "Den Beginn oder Fortschritt eines Vorgangs begleiten.",
  loading: "Einen laufenden Vorgang mit drei kurzen Impulsen begleiten.",
  ready: "Die Bereitschaft eines Vorgangs signalisieren.",
  complete: "Den Abschluss eines längeren Vorgangs markieren.",
  sparkle: "Einen besonderen Erfolg mit einem leichten Glanz markieren.",
};

if (!process.env.FOLEY_OFFLINE_MODULE) {
  throw new Error("Set FOLEY_OFFLINE_MODULE to node-web-audio-api's index.js");
}
const { OfflineAudioContext } = await import(
  pathToFileURL(process.env.FOLEY_OFFLINE_MODULE).href
);
globalThis.OfflineAudioContext = OfflineAudioContext;
const destination = new URL("../../widgetbook/assets/foley/", import.meta.url);
await mkdir(destination, { recursive: true });
set({ theme: "default", transpose: 0, space: 0.22 });
const renderer = JSON.parse(
  await readFile(
    new URL("./package.json", pathToFileURL(process.env.FOLEY_OFFLINE_MODULE)),
    "utf8",
  ),
);
const metadata = {
  source: `@foleyjs/core ${version}`,
  renderer: `${renderer.name} ${renderer.version}`,
  theme: "default",
  transpose: 0,
  space: 0.22,
  seed: 20261010,
  recordings: {},
};
const originalRandom = Math.random;
try {
  for (const cue of Object.keys(cues)) {
    // Offline exports omit pitch humanization, but noise/reverb still use random
    // samples. A fixed per-cue seed makes re-export reproducible in this renderer.
    let seed = 20261010;
    Math.random = () => {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      return seed / 4294967296;
    };
    const wav = await toWav(cue);
    const bytes = Buffer.from(await wav.arrayBuffer());
    await writeFile(new URL(`${cue}.wav`, destination), bytes);
    metadata.recordings[cue] = {
      id: cue,
      name: cue[0].toUpperCase() + cue.slice(1),
      family: cues[cue].family,
      category: categories[cues[cue].family],
      description: descriptions[cue],
      recommended: recommended.includes(cue),
      bytes: bytes.length,
      seconds: (bytes.length - 44) / (44100 * 4),
      sha256: createHash("sha256").update(bytes).digest("hex"),
    };
    console.log(`${cue}: ${wav.size} bytes (@foleyjs/core ${version})`);
  }
} finally {
  Math.random = originalRandom;
}
await copyFile(
  new URL("../node_modules/@foleyjs/core/LICENSE", import.meta.url),
  new URL("LICENSE.foley", destination),
);
await writeFile(
  new URL("export-metadata.json", destination),
  `${JSON.stringify(metadata, null, 2)}\n`,
);
