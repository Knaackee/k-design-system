import { useEffect, useRef, useState } from "react";
import { KAvatarEditor, type KAvatarEditorImage } from "@k-design-system/ui";

export function AvatarEditorFixture({
  open,
  onOpenChange,
  onAvatarChange,
  includeSample = true,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAvatarChange: (src: string | undefined) => void;
  includeSample?: boolean;
}) {
  const [images, setImages] = useState<KAvatarEditorImage[]>(
    includeSample
      ? [
          {
            id: "portrait",
            src: "/image-cropper/jordan.png",
            alt: "Porträt Jordan",
          },
        ]
      : [],
  );
  const [selected, setSelected] = useState<string>();
  const owned = useRef<string[]>([]);
  useEffect(
    () => () => owned.current.forEach((src) => URL.revokeObjectURL(src)),
    [],
  );
  return (
    <KAvatarEditor
      open={open}
      onOpenChange={onOpenChange}
      images={images}
      cropLabels={{
        preview: "Bild zuschneiden",
        instructions:
          "Verschiebe das Bild oder verwende die Pfeiltasten für den Zuschnitt.",
        zoom: "Zoom",
        zoomIn: "Vergrößern",
        zoomOut: "Verkleinern",
        imageTooLarge: "Die Bildabmessungen sind zu groß.",
      }}
      selectedId={selected}
      labels={{
        title: "Dein Bild",
        choose: "Bild auswählen",
        camera: "Foto aufnehmen",
        capture: "Aufnehmen",
        remove: "Bild entfernen",
        omit: "Kein Bild verwenden",
        close: "Schließen",
        back: "Zurück",
        apply: "Bild verwenden",
        gallery: "Deine Bilder",
        error:
          "Das Bild oder die Kamera konnte nicht geöffnet werden. Bitte versuche es erneut.",
        invalidFile: "Bitte wähle ein JPG-, PNG- oder WebP-Bild bis 32 MB.",
        loading: "Kamera wird geöffnet …",
      }}
      onApply={(result) => {
        const src = URL.createObjectURL(result.blob);
        owned.current.push(src);
        setImages((v) => [
          ...v,
          { id: src, src, alt: `Eigenes Bild ${v.length}` },
        ]);
        setSelected(src);
        onAvatarChange(src);
      }}
      onOmit={() => {
        setSelected(undefined);
        onAvatarChange(undefined);
      }}
      onRemove={(id) => {
        setImages((v) => v.filter((image) => image.id !== id));
        if (selected === id) {
          setSelected(undefined);
          onAvatarChange(undefined);
        }
      }}
    />
  );
}
