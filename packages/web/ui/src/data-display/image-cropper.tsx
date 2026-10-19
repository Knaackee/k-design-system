import {
  useEffect,
  useId,
  useRef,
  useState,
  type HTMLAttributes,
  type KeyboardEvent,
  type PointerEvent,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KButton } from "../primitives/button.js";
import { KText } from "../primitives/text.js";
import { KSlider } from "../extended-components.js";
import {
  K_IMAGE_CROP_MAX_ZOOM,
  K_IMAGE_CROP_MIN_ZOOM,
  createKImageCrop,
  dragKImageCrop,
  kImageCropZoom,
  moveKImageCrop,
  normalizeKImageCrop,
  zoomKImageCrop,
  type KImageCropRect,
  type KImageCropSize,
} from "./image-crop-model.js";

const MAX_DECODED_IMAGE_PIXELS = 25_000_000;
const DEFAULT_OUTPUT_SIZE = 512;
const MAX_OUTPUT_SIZE = 4096;
const KEYBOARD_PAN_FRACTION = 0.02;
const KEYBOARD_FAST_PAN_FRACTION = 0.1;
const ZOOM_BUTTON_STEP = 0.1;

export interface KImageCropperLabels {
  preview: string;
  zoom: string;
  zoomOut: string;
  zoomIn: string;
  cancel: string;
  apply: string;
  instructions: string;
  error: string;
  imageError: string;
  imageTooLarge: string;
}

export interface KImageCropResult {
  blob: Blob;
  crop: KImageCropRect;
  width: number;
  height: number;
}

export interface KImageCropperProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "onError"
> {
  src: string;
  alt: string;
  outputSize?: number;
  initialCrop?: KImageCropRect;
  labels?: Partial<KImageCropperLabels>;
  disabled?: boolean;
  onCropChange?: (crop: KImageCropRect) => void;
  onCancel: () => void;
  onApply: (result: KImageCropResult) => void | Promise<void>;
}

const defaultLabels: KImageCropperLabels = {
  preview: "Image crop preview",
  zoom: "Zoom",
  zoomOut: "Zoom out",
  zoomIn: "Zoom in",
  cancel: "Cancel",
  apply: "Apply",
  instructions: "Drag the image or use the arrow keys to position the crop.",
  error: "The crop could not be applied. Try again.",
  imageError: "The image could not be loaded.",
  imageTooLarge: "The image dimensions are too large.",
};

function canvasToBlob(canvas: HTMLCanvasElement) {
  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) resolve(blob);
      else reject(new Error("Canvas export did not produce an image."));
    }, "image/png");
  });
}

async function exportCrop(
  image: HTMLImageElement,
  crop: KImageCropRect,
  outputSize: number,
) {
  const canvas = document.createElement("canvas");
  canvas.width = outputSize;
  canvas.height = outputSize;
  const context = canvas.getContext("2d");
  if (!context) throw new Error("Canvas rendering is unavailable.");
  context.drawImage(
    image,
    crop.x,
    crop.y,
    crop.size,
    crop.size,
    0,
    0,
    outputSize,
    outputSize,
  );
  return canvasToBlob(canvas);
}

export function KImageCropper({
  src,
  alt,
  outputSize = DEFAULT_OUTPUT_SIZE,
  initialCrop,
  labels,
  disabled = false,
  onCropChange,
  onCancel,
  onApply,
  className,
  ...props
}: KImageCropperProps) {
  const copy = { ...defaultLabels, ...labels };
  const instructionsId = useId();
  const imageRef = useRef<HTMLImageElement>(null);
  const viewportRef = useRef<HTMLDivElement>(null);
  const dragRef = useRef<{ pointerId: number; x: number; y: number } | null>(
    null,
  );
  const [imageSize, setImageSize] = useState<KImageCropSize | null>(null);
  const [crop, setCrop] = useState<KImageCropRect | null>(null);
  const [applying, setApplying] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setImageSize(null);
    setCrop(null);
    setApplying(false);
    setError(null);
    dragRef.current = null;
  }, [src]);

  useEffect(() => {
    if (crop) onCropChange?.(crop);
  }, [crop, onCropChange]);

  const updateZoom = (zoom: number) => {
    if (!crop || !imageSize || disabled || applying) return;
    setCrop(zoomKImageCrop(crop, imageSize, zoom));
    setError(null);
  };

  const handlePointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const drag = dragRef.current;
    if (!drag || drag.pointerId !== event.pointerId || !crop || !imageSize)
      return;
    const viewportSize = event.currentTarget.getBoundingClientRect().width;
    setCrop(
      dragKImageCrop(
        crop,
        imageSize,
        event.clientX - drag.x,
        event.clientY - drag.y,
        viewportSize,
      ),
    );
    dragRef.current = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
    };
  };

  const endDrag = (event: PointerEvent<HTMLDivElement>) => {
    if (dragRef.current?.pointerId !== event.pointerId) return;
    dragRef.current = null;
    delete event.currentTarget.dataset.dragging;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (!crop || !imageSize || disabled || applying) return;
    const fraction = event.shiftKey
      ? KEYBOARD_FAST_PAN_FRACTION
      : KEYBOARD_PAN_FRACTION;
    const step = crop.size * fraction;
    const movement = {
      ArrowLeft: [-step, 0],
      ArrowRight: [step, 0],
      ArrowUp: [0, -step],
      ArrowDown: [0, step],
    }[event.key];
    if (!movement) return;
    event.preventDefault();
    setCrop(moveKImageCrop(crop, imageSize, movement[0], movement[1]));
    setError(null);
  };

  const apply = async () => {
    const image = imageRef.current;
    if (!image || !crop || applying || disabled) return;
    setApplying(true);
    setError(null);
    try {
      const safeOutputSize = Math.min(
        MAX_OUTPUT_SIZE,
        Math.max(1, Math.round(outputSize)),
      );
      const blob = await exportCrop(image, crop, safeOutputSize);
      await onApply({
        blob,
        crop,
        width: safeOutputSize,
        height: safeOutputSize,
      });
    } catch {
      setError(copy.error);
    } finally {
      setApplying(false);
    }
  };

  const zoom = crop && imageSize ? kImageCropZoom(crop, imageSize) : 1;
  const imageStyle =
    crop && imageSize
      ? {
          width: `${(imageSize.width / crop.size) * 100}%`,
          height: `${(imageSize.height / crop.size) * 100}%`,
          left: `${(-crop.x / crop.size) * 100}%`,
          top: `${(-crop.y / crop.size) * 100}%`,
        }
      : undefined;

  return (
    <div
      {...props}
      className={["k-image-cropper", className].filter(Boolean).join(" ")}
    >
      <div
        ref={viewportRef}
        className="k-image-cropper__viewport"
        role="group"
        aria-label={copy.preview}
        aria-describedby={instructionsId}
        tabIndex={crop && !disabled ? 0 : -1}
        data-disabled={disabled || undefined}
        onKeyDown={handleKeyDown}
        onPointerDown={(event) => {
          if (!crop || disabled || applying || event.button !== 0) return;
          dragRef.current = {
            pointerId: event.pointerId,
            x: event.clientX,
            y: event.clientY,
          };
          event.currentTarget.setPointerCapture(event.pointerId);
          event.currentTarget.dataset.dragging = "true";
        }}
        onPointerMove={handlePointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
      >
        <img
          ref={imageRef}
          src={src}
          alt={alt}
          draggable={false}
          style={imageStyle ? imageStyle : { visibility: "hidden" }}
          onLoad={(event) => {
            const nextSize = {
              width: event.currentTarget.naturalWidth,
              height: event.currentTarget.naturalHeight,
            };
            if (
              nextSize.width <= 0 ||
              nextSize.height <= 0 ||
              nextSize.width * nextSize.height > MAX_DECODED_IMAGE_PIXELS
            ) {
              setImageSize(null);
              setCrop(null);
              setError(copy.imageTooLarge);
              return;
            }
            setImageSize(nextSize);
            setCrop(
              initialCrop
                ? normalizeKImageCrop(initialCrop, nextSize)
                : createKImageCrop(nextSize),
            );
            setError(null);
          }}
          onError={() => {
            setImageSize(null);
            setCrop(null);
            setError(copy.imageError);
          }}
        />
      </div>
      <KText
        id={instructionsId}
        className="k-image-cropper__instructions"
        variant="caption"
      >
        {copy.instructions}
      </KText>
      <div className="k-image-cropper__zoom">
        <KIconButton
          icon="zoom-out"
          label={copy.zoomOut}
          disabled={
            !crop || disabled || applying || zoom <= K_IMAGE_CROP_MIN_ZOOM
          }
          onClick={() => updateZoom(zoom - ZOOM_BUTTON_STEP)}
        />
        <KSlider
          value={zoom}
          min={K_IMAGE_CROP_MIN_ZOOM}
          max={K_IMAGE_CROP_MAX_ZOOM}
          step={0.01}
          label={copy.zoom}
          disabled={!crop || disabled || applying}
          valueLabel={(value) => `${Math.round(value * 100)}%`}
          onValueChange={updateZoom}
        />
        <KIconButton
          icon="zoom-in"
          label={copy.zoomIn}
          disabled={
            !crop || disabled || applying || zoom >= K_IMAGE_CROP_MAX_ZOOM
          }
          onClick={() => updateZoom(zoom + ZOOM_BUTTON_STEP)}
        />
      </div>
      {error ? (
        <KText className="k-image-cropper__error" role="alert">
          {error}
        </KText>
      ) : null}
      <div className="k-image-cropper__actions">
        <KButton variant="secondary" disabled={applying} onClick={onCancel}>
          {copy.cancel}
        </KButton>
        <KButton
          loading={applying}
          disabled={!crop || disabled}
          onClick={() => void apply()}
        >
          {copy.apply}
        </KButton>
      </div>
    </div>
  );
}

export type { KImageCropRect } from "./image-crop-model.js";
