import { AvatarEditorFixture } from "./avatar-editor-fixture";

import { KBookingFlowChoice } from "@k-design-system/ui";

import { useState } from "react";

import type { Meta, StoryObj } from "@storybook/react-vite";

import {
  KAdaptiveDialog,
  KAlertDialog,
  KBookingPageLayout,
  KBookingPageSection,
  KBookingPageCard,
  KBookingPageStatus,
  KBookingThemePicker,
  KButton,
  KField,
  KIcon,
  KInput,
  KTextarea,
  KStack,
  KSwitch,
  KSelect,
  KQrCode,
} from "@k-design-system/ui";

import "./booking-page-management-fixture.css";

const designs = [
  ["clear", "Klar"],
  ["editorial", "Editorial"],
  ["handwritten", "Notizbuch"],
  ["bold", "Pop"],
  ["soft", "Pastell"],
  ["natural", "Retro"],
  ["immersive", "Vollbild"],
  ["night", "Nacht"],
  ["postcard", "Postkarte"],
  ["bento", "Bento"],
  ["monogram", "Monogramm"],
].map(([id, label]) => ({ id, label, image: `/booking-themes/${id}.webp` }));

function BookingPageManagement({
  mobile = false,
  dark = false,
}: {
  mobile?: boolean;
  dark?: boolean;
}) {
  const [portrait, setPortrait] = useState<string | undefined>(
    "/booking-themes/portrait.webp",
  );

  const [shape, setShape] = useState("square");

  const [theme, setTheme] = useState("handwritten"),
    [online, setOnline] = useState(true),
    [dialog, setDialog] = useState(""),
    [dirty, setDirty] = useState(false),
    [slug, setSlug] = useState("mila-berger"),
    [phone, setPhone] = useState(false),
    [flow, setFlow] = useState("guided"),
    [color, setColor] = useState("#0c679f"),
    [notice, setNotice] = useState("");

  const [fields, setFields] = useState({
    greeting: "Schön, dass du da bist!",
    text: "Schnitt, Farbe oder Styling – ich komme zu dir nach Hause. Gemeinsam finden wir deinen Look.",
    signature: "Deine Mila",
    button: "Angebote auswählen",
    name: "Mila · Hair at Home",
    description: "Mobiler Friseur-Service in Berlin und Umgebung.",
    email: "",
  });

  const change = (key: keyof typeof fields, value: string) => {
    setFields((v) => ({ ...v, [key]: value }));
    setDirty(true);
  };

  const field = (
    key: keyof typeof fields,
    label: string,
    multiline = false,
  ) => (
    <KField label={label}>
      {multiline ? (
        <KTextarea
          value={fields[key]}
          onChange={(e) => change(key, e.target.value)}
        />
      ) : (
        <KInput
          value={fields[key]}
          onChange={(e) => change(key, e.target.value)}
        />
      )}
    </KField>
  );

  const preview = (
    <img
      src={`/booking-themes/${theme}.webp`}
      alt="Buchungsseite im gewählten Design"
    />
  );

  return (
    <div
      className="booking-management-fixture"
      data-theme={dark ? "dark" : "light"}
      style={mobile ? { maxWidth: 390 } : undefined}
    >
      <KBookingPageLayout
        preview={preview}
        previewAction={
          <KButton variant="ghost" onClick={() => setDialog("preview")}>
            Öffnen
            <KIcon name="external-link" size={15} />
          </KButton>
        }
        previewHelp="Kund:innen sehen Änderungen erst nach dem Veröffentlichen."
      >
        <header>
          <h1>Buchungsseite</h1>
          <p>So sehen dich Kund:innen, wenn sie bei dir buchen.</p>
        </header>
        <KBookingPageStatus
          online={online}
          url={`onzeit.com/u/${slug}`}
          thumbnail={preview}
          addressAction={
            <KButton variant="ghost" onClick={() => setDialog("address")}>
              Adresse ändern
            </KButton>
          }
        >
          {[
            ["share", "Teilen"],
            ["copy", "Kopieren"],
            ["qr-code", "QR-Code"],
            ["eye", "Vorschau"],
          ].map(([icon, label]) => (
            <KButton
              key={label}
              variant={label === "Teilen" ? "primary" : "secondary"}
              onClick={() =>
                label === "Kopieren"
                  ? setNotice("Demo-Link kopiert")
                  : setDialog(label === "Vorschau" ? "preview" : "qr")
              }
            >
              <KIcon name={icon as "share"} size={19} />
              {label}
            </KButton>
          ))}
        </KBookingPageStatus>

        <KBookingPageSection
          title="Aussehen"
          subtitle="Design, Farbe, Bilder"
          defaultOpen
        >
          <KBookingPageCard>
            <KStack gap="control" align="stretch">
              <KField label="Design">
                <KBookingThemePicker
                  options={designs}
                  value={theme}
                  onChange={(v) => {
                    setTheme(v);
                    setDirty(true);
                  }}
                />
              </KField>
              <KField label="Markenfarbe">
                <div className="booking-management-colors">
                  {[
                    "#0c679f",
                    "#7c3aed",
                    "#db2777",
                    "#ea580c",
                    "#047857",
                    "#0f766e",
                    "#92400e",
                    "#18181b",
                  ].map((c) => (
                    <KButton
                      key={c}
                      variant="ghost"
                      aria-label={`Farbe ${c}`}
                      aria-pressed={c === color}
                      onClick={() => {
                        setColor(c);
                        setDirty(true);
                      }}
                    >
                      <span style={{ background: c }}>
                        {c === color ? <KIcon name="check" size={16} /> : null}
                      </span>
                    </KButton>
                  ))}
                </div>
              </KField>
            </KStack>
          </KBookingPageCard>

          <KBookingPageCard>
            <div className="booking-management-media">
              <img
                src={portrait}
                alt="Willkommensbild"
                style={{ borderRadius: shape === "round" ? "50%" : 14 }}
              />
              <div>
                <strong>Willkommensbild</strong>
                <small>Großes Bild oben auf der Seite</small>
                <KButton variant="secondary" onClick={() => setDialog("image")}>
                  Ändern
                </KButton>
              </div>
            </div>
            <div className="booking-management-media">
              <KIcon name="image" size={40} />
              <div>
                <strong>Logo</strong>
                <small>Klein neben deinem Namen</small>
                <KButton variant="secondary" onClick={() => setDialog("image")}>
                  Hinzufügen
                </KButton>
              </div>
            </div>
          </KBookingPageCard>
        </KBookingPageSection>

        <KBookingPageSection
          title="Willkommen"
          subtitle="Begrüßung, Text, Knopf"
          defaultOpen
        >
          <KBookingPageCard>
            <KStack gap="control" align="stretch">
              {field("greeting", "Begrüßung")}
              {field("text", "Willkommenstext", true)}
              {field("signature", "Gruß am Ende (optional)")}
              {field("button", "Text auf dem Knopf")}
            </KStack>
          </KBookingPageCard>
        </KBookingPageSection>

        <KBookingPageSection
          title="Betrieb"
          subtitle="Name, Beschreibung, Kontakt"
        >
          <KBookingPageCard>
            <KStack gap="control" align="stretch">
              {field("name", "Name deines Betriebs")}
              {field("description", "Kurzbeschreibung", true)}
              {field("email", "Kontakt-E-Mail (optional)")}
            </KStack>
          </KBookingPageCard>
        </KBookingPageSection>

        <KBookingPageSection
          title="Buchungsablauf"
          subtitle="Auswahl, Angaben, Texte"
        >
          <KBookingPageCard>
            <KStack gap="control" align="stretch">
              <KBookingFlowChoice
                value={flow}
                onChange={(v) => {
                  setFlow(v);
                  setDirty(true);
                }}
              />
              <KSwitch
                label="Telefonnummer verlangen"
                checked={phone}
                onCheckedChange={(v) => {
                  setPhone(v);
                  setDirty(true);
                }}
              />
              <KButton
                variant="ghost"
                fullWidth
                onClick={() => setDialog("texts")}
              >
                Texte beim Einsatzort
                <KIcon name="chevron-right" size={18} />
              </KButton>
            </KStack>
          </KBookingPageCard>
        </KBookingPageSection>

        <KBookingPageSection title="Sichtbarkeit" defaultOpen>
          <KBookingPageCard>
            <KButton
              variant="ghost"
              fullWidth
              onClick={() => setDialog("offline")}
            >
              <KIcon name="power" size={18} />
              {online ? "Seite offline nehmen" : "Seite wieder online stellen"}
            </KButton>
          </KBookingPageCard>
        </KBookingPageSection>

        {dirty && (
          <div className="booking-management-save">
            <span>Unveröffentlichte Änderungen</span>
            <KButton
              variant="secondary"
              onClick={() => {
                setDirty(false);
                setNotice("Demo-Änderungen verworfen.");
              }}
            >
              Verwerfen
            </KButton>
            <KButton
              onClick={() => {
                setDirty(false);
                setNotice("Demo veröffentlicht – keine echten Daten geändert.");
              }}
            >
              Veröffentlichen
            </KButton>
          </div>
        )}
        {notice && <p role="status">{notice}</p>}
      </KBookingPageLayout>
      <KAdaptiveDialog
        open={!!dialog && dialog !== "offline" && dialog !== "image"}
        onOpenChange={(o) => !o && setDialog("")}
        title={
          {
            preview: "Vorschau",
            address: "Adresse ändern",
            qr: "QR-Code",
            texts: "Texte beim Einsatzort",
            image: "Dein Bild",
          }[dialog] ?? ""
        }
        closeLabel="Schließen"
      >
        {dialog === "preview" && (
          <div className="k-booking-page-phone">{preview}</div>
        )}
        {dialog === "qr" && (
          <KQrCode
            label="Buchungsseite öffnen"
            data={`https://onzeit.com/u/${slug}`}
            size={260}
          />
        )}
        {dialog === "address" && (
          <KStack gap="control" align="stretch">
            <KField
              label="Webadresse"
              helperText="Diese Galerie prüft keine echte Verfügbarkeit."
            >
              <KInput value={slug} onChange={(e) => setSlug(e.target.value)} />
            </KField>
            <KButton
              disabled={!/^[a-z0-9-]{3,48}$/.test(slug)}
              onClick={() => setDialog("")}
            >
              Adresse übernehmen
            </KButton>
          </KStack>
        )}
        {dialog === "texts" && (
          <KStack gap="control" align="stretch">
            {[
              "Überschrift",
              "Beschreibung",
              "Adresse suchen",
              "Standort verwenden",
            ].map((label) => (
              <KField key={label} label={label}>
                <KInput
                  placeholder="Standardtext"
                  onChange={() => setDirty(true)}
                />
              </KField>
            ))}
          </KStack>
        )}
        {dialog === "image" && (
          <p>
            Die Anwendung bindet hier ihren vorhandenen Bilddialog mit Auswahl,
            Kamera und Zuschnitt an.
          </p>
        )}
      </KAdaptiveDialog>
      <AvatarEditorFixture
        open={dialog === "image"}
        onOpenChange={(o) => !o && setDialog("")}
        onAvatarChange={(src) => {
          setPortrait(src);
          setDirty(true);
        }}
      />
      <KAlertDialog
        open={dialog === "offline"}
        onOpenChange={(o) => !o && setDialog("")}
        title={
          online ? "Seite offline nehmen?" : "Seite wieder online stellen?"
        }
        description="Bestehende Termine bleiben erhalten. Diese Galerie ändert keine echten Daten."
        cancelLabel="Abbrechen"
        actionLabel={online ? "Offline nehmen" : "Online stellen"}
        destructive={online}
        onAction={() => {
          setOnline(!online);
          setDialog("");
        }}
      />
    </div>
  );
}

const meta = {
  title: "Patterns/BookingPageManagement",
  component: BookingPageManagement,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof BookingPageManagement>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Overview: Story = {};
export const Dark: Story = { args: { dark: true } };
export const Mobile: Story = { args: { mobile: true } };
export const MobileDark: Story = { args: { mobile: true, dark: true } };
