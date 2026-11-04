import { useEffect, useRef, useState } from "react";
import { KAdaptiveDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import {
  KImageCropper,
  type KImageCropResult,
  type KImageCropperLabels,
} from "../data-display/image-cropper.js";

export interface KAvatarEditorImage {
  id: string;
  src: string;
  alt: string;
}
export interface KAvatarEditorLabels {
  title: string;
  choose: string;
  camera: string;
  capture: string;
  remove: string;
  omit: string;
  close: string;
  back: string;
  apply: string;
  gallery: string;
  error: string;
  invalidFile: string;
  loading: string;
}
const defaults: KAvatarEditorLabels = {
  title: "Your image",
  choose: "Choose image",
  camera: "Take photo",
  capture: "Capture",
  remove: "Remove image",
  omit: "Use no image",
  close: "Close",
  back: "Back",
  apply: "Use image",
  gallery: "Gallery",
  error: "The image or camera could not be opened. Please try again.",
  invalidFile: "Choose a JPEG, PNG or WebP image within the file size limit.",
  loading: "Opening camera…",
};
export interface KAvatarEditorProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  images: readonly KAvatarEditorImage[];
  selectedId?: string;
  onApply: (
    result: KImageCropResult,
    source: KAvatarEditorImage,
  ) => void | Promise<void>;
  onOmit: () => void | Promise<void>;
  onRemove?: (id: string) => void;
  /** Native hosts can supply their own capture flow. */
  onCamera?: () => Promise<File | null>;
  maxFileBytes?: number;
  labels?: Partial<KAvatarEditorLabels>;
  cropLabels?: Partial<KImageCropperLabels>;
}
/** Controlled gallery and crop flow. Persistence and remote uploads belong to the host. */
export function KAvatarEditor({
  open,
  onOpenChange,
  images,
  selectedId,
  onApply,
  onOmit,
  onRemove,
  onCamera,
  maxFileBytes = 32 * 1024 * 1024,
  cropLabels,
  labels,
}: KAvatarEditorProps) {
  const t = { ...defaults, ...labels };
  const [draft, setDraft] = useState<KAvatarEditorImage | null>(null);
  const [camera, setCamera] = useState(false);
  const [ready, setReady] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const video = useRef<HTMLVideoElement>(null);
  const stream = useRef<MediaStream | null>(null);
  const generation = useRef(0);
  const urls = useRef<string[]>([]);
  function stop() {
    generation.current++;
    stream.current?.getTracks().forEach((track) => track.stop());
    stream.current = null;
    setCamera(false);
    setReady(false);
  }
  useEffect(() => {
    if (!open) {
      stop();
      setDraft(null);
      setError("");
      urls.current.forEach((url) => URL.revokeObjectURL(url));
      urls.current = [];
    }
  }, [open]);
  useEffect(
    () => () => {
      generation.current++;
      stream.current?.getTracks().forEach((track) => track.stop());
      urls.current.forEach((url) => URL.revokeObjectURL(url));
    },
    [],
  );
  function choose(file?: File) {
    if (!file) return;
    if (
      !["image/jpeg", "image/png", "image/webp"].includes(file.type) ||
      file.size > maxFileBytes
    ) {
      setError(t.invalidFile);
      return;
    }
    const src = URL.createObjectURL(file);
    urls.current.push(src);
    setError("");
    setDraft({ id: src, src, alt: file.name });
  }
  async function startCamera() {
    setError("");
    const request = ++generation.current;
    try {
      if (onCamera) {
        const file = await onCamera();
        if (request === generation.current && file) choose(file);
        return;
      }
      setCamera(true);
      const media = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user" },
        audio: false,
      });
      if (request !== generation.current) {
        media.getTracks().forEach((track) => track.stop());
        return;
      }
      stream.current = media;
      if (video.current) video.current.srcObject = media;
    } catch {
      if (request === generation.current) {
        stop();
        setError(t.error);
      }
    }
  }
  async function capture() {
    const source = video.current;
    if (!source?.videoWidth || !ready) return;
    const request = generation.current;
    const canvas = document.createElement("canvas");
    canvas.width = source.videoWidth;
    canvas.height = source.videoHeight;
    canvas.getContext("2d")?.drawImage(source, 0, 0);
    canvas.toBlob((blob) => {
      if (request !== generation.current) return;
      stop();
      if (blob) choose(new File([blob], "photo.png", { type: "image/png" }));
      else setError(t.error);
    }, "image/png");
  }
  async function commit(action: () => void | Promise<void>) {
    setBusy(true);
    setError("");
    try {
      await action();
      onOpenChange(false);
    } catch {
      setError(t.error);
    } finally {
      setBusy(false);
    }
  }
  return (
    <KAdaptiveDialog
      open={open}
      onOpenChange={onOpenChange}
      dismissible={!busy}
      title={t.title}
      closeLabel={t.close}
      actions={
        !draft && !camera ? (
          <div className="k-avatar-editor-actions">
            <div className="k-avatar-editor-sources">
              <KButton
                variant="secondary"
                disabled={busy}
                className="k-avatar-editor-source"
                onClick={() => input.current?.click()}
              >
                <span>
                  <KIcon name="image" size={30} />
                  {t.choose}
                </span>
              </KButton>
              <KButton
                variant="secondary"
                disabled={busy}
                className="k-avatar-editor-source"
                onClick={() => void startCamera()}
              >
                <span>
                  <KIcon name="camera" size={30} />
                  {t.camera}
                </span>
              </KButton>
            </div>
            <KButton
              variant="ghost"
              disabled={busy}
              className="k-avatar-editor-omit"
              onClick={() => void commit(onOmit)}
            >
              {t.omit}
            </KButton>
          </div>
        ) : undefined
      }
    >
      <input
        hidden
        ref={input}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={(event) => {
          choose(event.target.files?.[0]);
          event.target.value = "";
        }}
      />
      {error && <p role="alert">{error}</p>}
      {camera ? (
        <div className="k-avatar-editor-camera">
          <video
            ref={video}
            autoPlay
            playsInline
            muted
            onLoadedData={() => setReady(true)}
            aria-label={t.camera}
          />
          {!ready && <p role="status">{t.loading}</p>}
          <KButton disabled={!ready} onClick={() => void capture()}>
            {t.capture}
          </KButton>
          <KButton variant="ghost" onClick={stop}>
            {t.back}
          </KButton>
        </div>
      ) : draft ? (
        <KImageCropper
          src={draft.src}
          alt={draft.alt}
          shape="round"
          disabled={busy}
          labels={{
            ...cropLabels,
            apply: t.apply,
            cancel: t.back,
            error: t.error,
            imageError: t.error,
          }}
          onCancel={() => setDraft(null)}
          onApply={(result) => commit(() => onApply(result, draft))}
        />
      ) : (
        <div className="k-avatar-editor-gallery" aria-label={t.gallery}>
          {images.map((image) => (
            <div key={image.id}>
              <KButton
                variant="ghost"
                className="k-avatar-editor-image"
                aria-label={image.alt}
                aria-pressed={selectedId === image.id}
                onClick={() => {
                  setError("");
                  setDraft(image);
                }}
              >
                <img src={image.src} alt="" />
              </KButton>
              {onRemove && (
                <KButton
                  variant="ghost"
                  aria-label={`${t.remove}: ${image.alt}`}
                  onClick={() => onRemove(image.id)}
                >
                  <KIcon name="trash" size={16} />
                </KButton>
              )}
            </div>
          ))}
        </div>
      )}
    </KAdaptiveDialog>
  );
}
