# Foley review recordings

These 28 stereo 16-bit / 44.1 kHz WAV files were rendered by the official
`@foleyjs/core` 2.9.0 `toWav()` API. Settings: Default theme, transpose 0,
space 0.22. Source: [usefoley.dev](https://usefoley.dev/) and
[Foley source](https://github.com/eakbulut/foley). License: `LICENSE.foley`.

Storybook serves this directory through its existing static asset mount;
Widgetbook includes the identical files as Flutter assets. Both galleries read
the same `export-metadata.json` for names, families, descriptions and the six
recommended cues. Playback volume is
applied by each gallery player. Neither gallery synthesizes a substitute sound.

To regenerate, install `node-web-audio-api` in a temporary directory, set
`FOLEY_OFFLINE_MODULE` to its `index.js` and run
`node apps/storybook/scripts/export-foley.mjs` from the repository root. A fixed
seed stabilizes the generated noise and reverb. The Node renderer version used
for this set is recorded in the adjacent export metadata.

This is a gallery audition prototype. Consumers own event-to-cue mapping and
sound preferences. The UI packages acquire no audio dependency or automatic
global click/hover bindings. Native device behavior has not been verified here.
