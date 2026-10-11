import { useId, useState, type ReactNode } from "react";
import { KPresentationPicture } from "./presentation-picture.js";
import { KAdaptiveDialog } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";
import { KCard } from "../primitives/card.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export interface KPresentationImage {
  src: string;
  alt: string;
  thumbnailSrc?: string;
  caption?: string;
}

export interface KPresentationGalleryProps {
  images: readonly KPresentationImage[];
  title?: string;
  selectedIndex: number | null;
  onSelectedIndexChange: (index: number | null) => void;
  closeLabel?: string;
  previousLabel?: string;
  nextLabel?: string;
}

/** Full-size selection stays with the consumer; thumbnails only request changes. */
export function KPresentationGallery({
  images,
  title = "Images",
  selectedIndex,
  onSelectedIndexChange,
  closeLabel = "Close",
  previousLabel = "Previous image",
  nextLabel = "Next image",
}: KPresentationGalleryProps) {
  const selected = selectedIndex === null ? undefined : images[selectedIndex];
  if (images.length === 0) return null;
  return (
    <KCard
      className="k-presentation-media k-presentation-gallery"
      aria-label={title}
    >
      <header className="k-presentation-media__heading">
        <KIcon name="image" />
        <strong>{title}</strong>
        <span className="k-presentation-media__meta">{images.length}</span>
      </header>
      <div
        className="k-presentation-gallery__grid"
        data-single={images.length === 1}
      >
        {images.map((image, index) => (
          <button
            key={`${image.src}-${index}`}
            type="button"
            className="k-presentation-gallery__thumbnail"
            aria-haspopup="dialog"
            aria-label={image.caption || image.alt || `${title} ${index + 1}`}
            onClick={() => onSelectedIndexChange(index)}
          >
            <KPresentationPicture
              src={image.thumbnailSrc || image.src}
              alt={image.alt}
              loading="lazy"
            />
            {image.caption && <span>{image.caption}</span>}
          </button>
        ))}
      </div>
      <KAdaptiveDialog
        open={Boolean(selected)}
        onOpenChange={(open) => {
          if (!open) onSelectedIndexChange(null);
        }}
        title={selected?.caption || title}
        closeLabel={closeLabel}
        className="k-presentation-gallery__dialog"
        actions={
          <KButton
            variant="secondary"
            onClick={() => onSelectedIndexChange(null)}
          >
            {closeLabel}
          </KButton>
        }
      >
        {selected && (
          <figure className="k-presentation-gallery__full">
            <KPresentationPicture src={selected.src} alt={selected.alt} />
            {selected.caption && <figcaption>{selected.caption}</figcaption>}
            {images.length > 1 && (
              <div className="k-presentation-gallery__navigation">
                <KButton
                  variant="ghost"
                  disabled={selectedIndex === 0}
                  aria-label={previousLabel}
                  onClick={() => onSelectedIndexChange(selectedIndex! - 1)}
                >
                  <KIcon name="chevron-left" />
                  {previousLabel}
                </KButton>
                <span className="k-presentation-media__meta" aria-live="polite">
                  {selectedIndex! + 1} / {images.length}
                </span>
                <KButton
                  variant="ghost"
                  disabled={selectedIndex === images.length - 1}
                  aria-label={nextLabel}
                  onClick={() => onSelectedIndexChange(selectedIndex! + 1)}
                >
                  {nextLabel}
                  <KIcon name="chevron-right" />
                </KButton>
              </div>
            )}
          </figure>
        )}
      </KAdaptiveDialog>
    </KCard>
  );
}

export type KPresentationVideoProps = {
  title: string;
  poster?: string;
  caption?: ReactNode;
  loadLabel?: string;
} & (
  | { src: string; youtubeVideoId?: never }
  | { youtubeVideoId: string; src?: never }
);

/** YouTube is contacted only after activation; neither player starts automatically. */
export function KPresentationVideo({
  title,
  poster,
  caption,
  loadLabel = "Load YouTube video",
  src,
  youtubeVideoId,
}: KPresentationVideoProps) {
  const titleId = useId();
  const [loadedVideoId, setLoadedVideoId] = useState<string | null>(null);
  const validVideoId =
    youtubeVideoId && /^[\w-]{11}$/.test(youtubeVideoId)
      ? youtubeVideoId
      : null;
  return (
    <KCard className="k-presentation-media" aria-labelledby={titleId}>
      <header className="k-presentation-media__heading">
        <KIcon name="video" />
        <strong id={titleId}>{title}</strong>
      </header>
      {src ? (
        <video
          className="k-presentation-video__player"
          controls
          playsInline
          preload="none"
          src={src}
          poster={poster}
          aria-label={title}
        />
      ) : validVideoId && loadedVideoId === validVideoId ? (
        <iframe
          className="k-presentation-video__player"
          title={title}
          src={`https://www.youtube-nocookie.com/embed/${validVideoId}?autoplay=0`}
          allow="encrypted-media; picture-in-picture; fullscreen"
          allowFullScreen
          referrerPolicy="strict-origin-when-cross-origin"
        />
      ) : (
        <div className="k-presentation-video__placeholder">
          {poster && (
            <KPresentationPicture src={poster} alt="" loading="lazy" />
          )}
          <KButton
            variant="secondary"
            disabled={!validVideoId}
            onClick={() => setLoadedVideoId(validVideoId)}
          >
            <KIcon name="play" />
            {loadLabel}
          </KButton>
        </div>
      )}
      {caption && (
        <div className="k-presentation-media__caption">{caption}</div>
      )}
    </KCard>
  );
}

export interface KPresentationAudioProps {
  src: string;
  title: string;
  meta?: ReactNode;
}

export function KPresentationAudio({
  src,
  title,
  meta,
}: KPresentationAudioProps) {
  const titleId = useId();
  return (
    <KCard
      className="k-presentation-media k-presentation-audio"
      aria-labelledby={titleId}
    >
      <header className="k-presentation-media__heading">
        <KIcon name="music" />
        <div>
          <strong id={titleId}>{title}</strong>
          {meta && <div className="k-presentation-media__meta">{meta}</div>}
        </div>
      </header>
      <audio controls preload="none" src={src} aria-label={title} />
    </KCard>
  );
}

export interface KPresentationFileProps {
  name: string;
  meta?: ReactNode;
  icon?: KIconName;
  onOpen?: () => void;
  onDownload?: () => void;
  openLabel?: string;
  downloadLabel?: string;
}

export function KPresentationFile({
  name,
  meta,
  icon = "file",
  onOpen,
  onDownload,
  openLabel = "Open",
  downloadLabel = "Download",
}: KPresentationFileProps) {
  const titleId = useId();
  return (
    <KCard
      className="k-presentation-media k-presentation-file"
      aria-labelledby={titleId}
    >
      <div className="k-presentation-file__details">
        <KIcon name={icon} size={24} />
        <div>
          <strong id={titleId}>{name}</strong>
          {meta && <div className="k-presentation-media__meta">{meta}</div>}
        </div>
      </div>
      {(onOpen || onDownload) && (
        <div className="k-presentation-file__actions">
          {onOpen && (
            <KButton
              variant="secondary"
              aria-label={`${openLabel}: ${name}`}
              onClick={onOpen}
            >
              <KIcon name="external-link" />
              {openLabel}
            </KButton>
          )}
          {onDownload && (
            <KButton
              variant="ghost"
              aria-label={`${downloadLabel}: ${name}`}
              onClick={onDownload}
            >
              <KIcon name="download" />
              {downloadLabel}
            </KButton>
          )}
        </div>
      )}
    </KCard>
  );
}
