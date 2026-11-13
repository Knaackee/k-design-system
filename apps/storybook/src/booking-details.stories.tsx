import { useState } from "react";
import type { Meta } from "@storybook/react-vite";
import "./booking-details.css";
import {
  KAvatar,
  KBadge,
  KButton,
  KIcon,
  KIconButton,
  KInline,
  KList,
  KListItem,
  KMenuButton,
  KResponsiveDrawer,
  KStack,
  KText,
} from "@k-design-system/ui";

function BookingDetailsFixture({ resizable = false }: { resizable?: boolean }) {
  const [open, setOpen] = useState(true);
  const [confirm, setConfirm] = useState(false);
  const [cancelled, setCancelled] = useState(false);
  return (
    <div className="booking-details-fixture">
      <KStack gap="section">
        <KText variant="heading2">Buchungen</KText>
        <KButton onClick={() => setOpen(true)}>Anna Winter öffnen</KButton>
      </KStack>
      <KResponsiveDrawer
        detents={resizable ? ["half", "full"] : undefined}
        open={open}
        onOpenChange={setOpen}
        inline
        title="Buchungsdetails"
        closeLabel="Schließen"
        dismissible={!confirm}
        hero={
          <div
            style={{
              height: "100%",
              display: "grid",
              placeItems: "center",
              background: "var(--k-map-color-background)",
            }}
          >
            <KIcon name="map-pin" />
          </div>
        }
        floatingActions={
          <KMenuButton
            label="Mehr"
            actions={[
              { id: "refresh", label: "Aktualisieren", onSelect: () => {} },
            ]}
          />
        }
        heroOverlays={
          <>
            <KBadge>7 Min. · 2,2 km</KBadge>
            <KIconButton icon="maximize" label="Karte öffnen" />
          </>
        }
        footer={
          confirm ? (
            <KStack align="stretch">
              <KText variant="label">Termin absagen?</KText>
              <KText variant="bodySmall">
                Anna Winter wird benachrichtigt. Das lässt sich nicht rückgängig
                machen.
              </KText>
              <KInline gap="control">
                <KButton variant="ghost" onClick={() => setConfirm(false)}>
                  Behalten
                </KButton>
                <KButton
                  tone="destructive"
                  onClick={() => {
                    setConfirm(false);
                    setCancelled(true);
                  }}
                >
                  Absagen
                </KButton>
              </KInline>
            </KStack>
          ) : undefined
        }
      >
        <KStack gap="action" align="stretch">
          <KInline gap="control" wrap>
            <KAvatar alt="Anna Winter" size="small" />
            <KStack>
              <KText variant="heading3">Anna Winter</KText>
              <KText variant="bodySmall">Haarschnitt · 60 Min.</KText>
            </KStack>
            <KBadge variant={cancelled ? "destructive" : "success"}>
              {cancelled ? "Abgesagt" : "Bestätigt"}
            </KBadge>
          </KInline>
          <KInline gap="control" wrap>
            <KButton disabled={cancelled}>
              <KIcon name="route" />
              Route starten
            </KButton>
            <KButton variant="secondary">
              <KIcon name="map-pin" />
              Tagesplan
            </KButton>
          </KInline>
          <KList>
            <KListItem
              leadingIcon="clock"
              title="08:30–09:30"
              description="Mo., 23. November 2026"
            />
            {!cancelled && (
              <KListItem
                leadingIcon="car"
                title="Losfahren um 07:45"
                description="45 Min. vor Beginn · 7 Min. · 2,2 km"
              />
            )}
            <KListItem
              leadingIcon="map-pin"
              title="Torstraße 120, 10119 Berlin"
              description="Rosenthaler Vorstadt"
            />
            <KListItem
              leadingIcon="mail"
              title="demo.customer.1@example.invalid"
              description="E-Mail"
            />
            <KListItem
              leadingIcon="users"
              title="Kundenprofil"
              description="Frühere Termine und Notizen"
              onClick={() => {}}
            />
          </KList>
          {!cancelled && (
            <KList>
              <KListItem
                leadingIcon="x"
                title="Termin absagen"
                description="Anna Winter wird benachrichtigt."
                onClick={() => setConfirm(true)}
              />
            </KList>
          )}
        </KStack>
      </KResponsiveDrawer>
    </div>
  );
}

export default {
  title: "Overlays/BookingDetails",
  component: BookingDetailsFixture,
} satisfies Meta<typeof BookingDetailsFixture>;
export const BookingDetails = {
  name: "booking-details",
  parameters: { fixtureId: "booking-details" },
};

export const Detents = {
  name: "booking-details-detents",
  parameters: { fixtureId: "booking-details-detents" },
  render: () => <BookingDetailsFixture resizable />,
};
