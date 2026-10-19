export interface KImageCropRect {
  x: number;
  y: number;
  size: number;
}

export interface KImageCropSize {
  width: number;
  height: number;
}

export const K_IMAGE_CROP_MIN_ZOOM = 1;
export const K_IMAGE_CROP_MAX_ZOOM = 3;

const clamp = (value: number, minimum: number, maximum: number) =>
  Math.min(maximum, Math.max(minimum, value));

export function kImageCropZoom(crop: KImageCropRect, image: KImageCropSize) {
  return Math.min(image.width, image.height) / crop.size;
}

export function createKImageCrop(
  image: KImageCropSize,
  zoom = K_IMAGE_CROP_MIN_ZOOM,
): KImageCropRect {
  const safeZoom = clamp(zoom, K_IMAGE_CROP_MIN_ZOOM, K_IMAGE_CROP_MAX_ZOOM);
  const size = Math.min(image.width, image.height) / safeZoom;
  return {
    x: (image.width - size) / 2,
    y: (image.height - size) / 2,
    size,
  };
}

export function clampKImageCrop(
  crop: KImageCropRect,
  image: KImageCropSize,
): KImageCropRect {
  const size = clamp(crop.size, 1, Math.min(image.width, image.height));
  return {
    x: clamp(crop.x, 0, image.width - size),
    y: clamp(crop.y, 0, image.height - size),
    size,
  };
}

export function normalizeKImageCrop(
  crop: KImageCropRect,
  image: KImageCropSize,
): KImageCropRect {
  const maximumSize = Math.min(image.width, image.height);
  const size = clamp(
    crop.size,
    maximumSize / K_IMAGE_CROP_MAX_ZOOM,
    maximumSize,
  );
  return clampKImageCrop({ ...crop, size }, image);
}

export function zoomKImageCrop(
  crop: KImageCropRect,
  image: KImageCropSize,
  zoom: number,
): KImageCropRect {
  const centerX = crop.x + crop.size / 2;
  const centerY = crop.y + crop.size / 2;
  const safeZoom = clamp(zoom, K_IMAGE_CROP_MIN_ZOOM, K_IMAGE_CROP_MAX_ZOOM);
  const size = Math.min(image.width, image.height) / safeZoom;
  return clampKImageCrop(
    { x: centerX - size / 2, y: centerY - size / 2, size },
    image,
  );
}

export function moveKImageCrop(
  crop: KImageCropRect,
  image: KImageCropSize,
  deltaX: number,
  deltaY: number,
): KImageCropRect {
  return clampKImageCrop(
    { ...crop, x: crop.x + deltaX, y: crop.y + deltaY },
    image,
  );
}

export function dragKImageCrop(
  crop: KImageCropRect,
  image: KImageCropSize,
  pointerDeltaX: number,
  pointerDeltaY: number,
  viewportSize: number,
): KImageCropRect {
  if (viewportSize <= 0) return crop;
  const sourcePixelsPerViewportPixel = crop.size / viewportSize;
  return moveKImageCrop(
    crop,
    image,
    -pointerDeltaX * sourcePixelsPerViewportPixel,
    -pointerDeltaY * sourcePixelsPerViewportPixel,
  );
}
