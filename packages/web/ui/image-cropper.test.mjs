import assert from "node:assert/strict";
import test from "node:test";
import {
  clampKImageCrop,
  createKImageCrop,
  dragKImageCrop,
  kImageCropZoom,
  moveKImageCrop,
  normalizeKImageCrop,
  zoomKImageCrop,
} from "./dist/data-display/image-crop-model.js";

test("centers the largest square crop in a landscape image", () => {
  assert.deepEqual(createKImageCrop({ width: 1600, height: 900 }), {
    x: 350,
    y: 0,
    size: 900,
  });
});

test("zoom keeps the crop center stable and reports the resulting zoom", () => {
  const image = { width: 1600, height: 900 };
  const crop = zoomKImageCrop(createKImageCrop(image), image, 2);

  assert.deepEqual(crop, { x: 575, y: 225, size: 450 });
  assert.equal(kImageCropZoom(crop, image), 2);
});

test("clamps movement so the crop can never reveal an empty margin", () => {
  const image = { width: 1000, height: 800 };
  const crop = { x: 100, y: 100, size: 400 };

  assert.deepEqual(moveKImageCrop(crop, image, -1000, 1000), {
    x: 0,
    y: 400,
    size: 400,
  });
  assert.deepEqual(clampKImageCrop({ x: 900, y: -50, size: 900 }, image), {
    x: 200,
    y: 0,
    size: 800,
  });
});

test("maps pointer movement through the crop scale across viewport sizes", () => {
  const image = { width: 1200, height: 800 };
  const crop = { x: 400, y: 200, size: 400 };

  const compact = dragKImageCrop(crop, image, 20, -10, 200);
  const wide = dragKImageCrop(crop, image, 40, -20, 400);

  assert.deepEqual(compact, { x: 360, y: 220, size: 400 });
  assert.deepEqual(wide, compact);
});

test("normalizes a restored crop to the supported zoom and image edges", () => {
  const image = { width: 1200, height: 900 };

  assert.deepEqual(
    normalizeKImageCrop({ x: 1100, y: -100, size: 100 }, image),
    { x: 900, y: 0, size: 300 },
  );
  assert.deepEqual(normalizeKImageCrop({ x: 500, y: 500, size: 1200 }, image), {
    x: 300,
    y: 0,
    size: 900,
  });
});
