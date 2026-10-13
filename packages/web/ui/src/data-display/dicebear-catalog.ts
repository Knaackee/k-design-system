import { OptionsDescriptor, Style } from "@dicebear/core";

export function getKDiceBearOptions(
  style: Style,
): ReturnType<OptionsDescriptor["toJSON"]> {
  return new OptionsDescriptor(style).toJSON();
}

// Individual imports keep definitions out of the initial consumer bundle.
const loaders = {
  "adventurer-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/adventurer-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/adventurer-neutral.json"),
  adventurer: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/adventurer.json", { with: { type: "json" } })
      : import("@dicebear/styles/adventurer.json"),
  "big-ears-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/big-ears-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/big-ears-neutral.json"),
  "big-ears": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/big-ears.json", { with: { type: "json" } })
      : import("@dicebear/styles/big-ears.json"),
  "big-smile": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/big-smile.json", { with: { type: "json" } })
      : import("@dicebear/styles/big-smile.json"),
  blobs: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/blobs.json", { with: { type: "json" } })
      : import("@dicebear/styles/blobs.json"),
  cameo: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/cameo.json", { with: { type: "json" } })
      : import("@dicebear/styles/cameo.json"),
  clay: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/clay.json", { with: { type: "json" } })
      : import("@dicebear/styles/clay.json"),
  constellation: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/constellation.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/constellation.json"),
  critters: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/critters.json", { with: { type: "json" } })
      : import("@dicebear/styles/critters.json"),
  "croodles-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/croodles-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/croodles-neutral.json"),
  croodles: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/croodles.json", { with: { type: "json" } })
      : import("@dicebear/styles/croodles.json"),
  cutouts: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/cutouts.json", { with: { type: "json" } })
      : import("@dicebear/styles/cutouts.json"),
  disco: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/disco.json", { with: { type: "json" } })
      : import("@dicebear/styles/disco.json"),
  dylan: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/dylan.json", { with: { type: "json" } })
      : import("@dicebear/styles/dylan.json"),
  "fun-emoji": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/fun-emoji.json", { with: { type: "json" } })
      : import("@dicebear/styles/fun-emoji.json"),
  gaze: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/gaze.json", { with: { type: "json" } })
      : import("@dicebear/styles/gaze.json"),
  glass: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/glass.json", { with: { type: "json" } })
      : import("@dicebear/styles/glass.json"),
  glyphs: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/glyphs.json", { with: { type: "json" } })
      : import("@dicebear/styles/glyphs.json"),
  icons: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/icons.json", { with: { type: "json" } })
      : import("@dicebear/styles/icons.json"),
  identicon: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/identicon.json", { with: { type: "json" } })
      : import("@dicebear/styles/identicon.json"),
  "initial-face": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/initial-face.json", { with: { type: "json" } })
      : import("@dicebear/styles/initial-face.json"),
  initials: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/initials.json", { with: { type: "json" } })
      : import("@dicebear/styles/initials.json"),
  landscape: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/landscape.json", { with: { type: "json" } })
      : import("@dicebear/styles/landscape.json"),
  "line-face": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/line-face.json", { with: { type: "json" } })
      : import("@dicebear/styles/line-face.json"),
  loops: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/loops.json", { with: { type: "json" } })
      : import("@dicebear/styles/loops.json"),
  "lorelei-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/lorelei-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/lorelei-neutral.json"),
  lorelei: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/lorelei.json", { with: { type: "json" } })
      : import("@dicebear/styles/lorelei.json"),
  marbles: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/marbles.json", { with: { type: "json" } })
      : import("@dicebear/styles/marbles.json"),
  micah: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/micah.json", { with: { type: "json" } })
      : import("@dicebear/styles/micah.json"),
  miniavs: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/miniavs.json", { with: { type: "json" } })
      : import("@dicebear/styles/miniavs.json"),
  moods: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/moods.json", { with: { type: "json" } })
      : import("@dicebear/styles/moods.json"),
  "notionists-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/notionists-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/notionists-neutral.json"),
  notionists: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/notionists.json", { with: { type: "json" } })
      : import("@dicebear/styles/notionists.json"),
  "open-peeps": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/open-peeps.json", { with: { type: "json" } })
      : import("@dicebear/styles/open-peeps.json"),
  patchwork: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/patchwork.json", { with: { type: "json" } })
      : import("@dicebear/styles/patchwork.json"),
  personas: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/personas.json", { with: { type: "json" } })
      : import("@dicebear/styles/personas.json"),
  "pixel-art-neutral": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/pixel-art-neutral.json", {
          with: { type: "json" },
        })
      : import("@dicebear/styles/pixel-art-neutral.json"),
  "pixel-art": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/pixel-art.json", { with: { type: "json" } })
      : import("@dicebear/styles/pixel-art.json"),
  pixelbot: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/pixelbot.json", { with: { type: "json" } })
      : import("@dicebear/styles/pixelbot.json"),
  planets: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/planets.json", { with: { type: "json" } })
      : import("@dicebear/styles/planets.json"),
  rings: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/rings.json", { with: { type: "json" } })
      : import("@dicebear/styles/rings.json"),
  shadows: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/shadows.json", { with: { type: "json" } })
      : import("@dicebear/styles/shadows.json"),
  "shape-grid": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/shape-grid.json", { with: { type: "json" } })
      : import("@dicebear/styles/shape-grid.json"),
  shapes: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/shapes.json", { with: { type: "json" } })
      : import("@dicebear/styles/shapes.json"),
  slice: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/slice.json", { with: { type: "json" } })
      : import("@dicebear/styles/slice.json"),
  sprouts: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/sprouts.json", { with: { type: "json" } })
      : import("@dicebear/styles/sprouts.json"),
  squircles: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/squircles.json", { with: { type: "json" } })
      : import("@dicebear/styles/squircles.json"),
  stack: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/stack.json", { with: { type: "json" } })
      : import("@dicebear/styles/stack.json"),
  stripes: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/stripes.json", { with: { type: "json" } })
      : import("@dicebear/styles/stripes.json"),
  thumbs: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/thumbs.json", { with: { type: "json" } })
      : import("@dicebear/styles/thumbs.json"),
  "toon-head": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/toon-head.json", { with: { type: "json" } })
      : import("@dicebear/styles/toon-head.json"),
  triangles: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/triangles.json", { with: { type: "json" } })
      : import("@dicebear/styles/triangles.json"),
  "voxel-art": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/voxel-art.json", { with: { type: "json" } })
      : import("@dicebear/styles/voxel-art.json"),
  "voxel-bot": () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/voxel-bot.json", { with: { type: "json" } })
      : import("@dicebear/styles/voxel-bot.json"),
  waves: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/waves.json", { with: { type: "json" } })
      : import("@dicebear/styles/waves.json"),
  weave: () =>
    typeof window === "undefined"
      ? import("@dicebear/styles/weave.json", { with: { type: "json" } })
      : import("@dicebear/styles/weave.json"),
} as const;

export type KDiceBearStyleId = keyof typeof loaders;
export const kDiceBearStyleIds = Object.freeze(
  Object.keys(loaders) as KDiceBearStyleId[],
);

const styles = new Map<KDiceBearStyleId, Promise<Style>>();

export function loadKDiceBearStyle(id: KDiceBearStyleId): Promise<Style> {
  if (!Object.hasOwn(loaders, id)) {
    return Promise.reject(new Error(`Unsupported DiceBear style: ${id}`));
  }
  let loaded = styles.get(id);
  if (!loaded) {
    loaded = loaders[id]().then(
      ({ default: definition }) => new Style(definition),
    );
    styles.set(id, loaded);
    loaded.catch(() => styles.delete(id));
  }
  return loaded;
}
