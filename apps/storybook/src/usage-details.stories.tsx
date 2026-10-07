import type { Meta, StoryObj } from "@storybook/react-vite";

import { KUsageDetails } from "@k-design-system/ui/patterns/usage-details";

export default {
  title: "Patterns/Usage details",
  component: KUsageDetails,
} satisfies Meta<typeof KUsageDetails>;

export const Subscription: StoryObj<typeof KUsageDetails> = {
  name: "usage-details-subscription",
  parameters: { fixtureId: "usage-details-subscription" },

  args: {
    title: "Account-Kontingent",
    sourceLabel: "Codex · Subscription-Kontingent",
    statusLabel: "Aktuell gemeldet",
    observedLabel: "Aktualisiert: 07.10.26, 14:00.",

    windows: [
      {
        id: "primary",
        label: "5 Stunden",
        valueLabel: "41 % frei",
        progress: 41,
        extraResetCount: 2,
        renewalLabel: "Nächste Aufladung in 1 Std. 20 Min.",
        renewalExact: "07.10.26, 15:20",
      },
      {
        id: "secondary",
        label: "7 Tage",
        valueLabel: "82 % frei",
        progress: 82,
        extraResetCount: 2,
        renewalLabel: "Nächste Aufladung in 3 Tagen",
        renewalExact: "10.10.26, 14:00",
      },
    ],

    balances: [
      {
        id: "credits",
        label: "Verfügbares Accountguthaben",
        valueLabel: "12,50 USD",
      },
    ],
    extraResetsLabel: "Zusatz-Resets",
    extraResets: [
      { id: "total", label: "Zusatz-Resets vorhanden", valueLabel: "2 Resets" },
      {
        id: "expiry",
        label: "Ablaufdatum: 01.11.26, 00:00",
        valueLabel: "1 Reset",
      },
      {
        id: "unknown",
        label: "Ablaufdatum nicht vom Anbieter gemeldet",
        valueLabel: "1 Reset",
      },
    ],
  },
};

export const Stale: StoryObj<typeof KUsageDetails> = {
  ...Subscription,
  name: "usage-details-stale",
  parameters: { fixtureId: "usage-details-stale" },
  args: {
    ...Subscription.args,
    statusLabel: "Veraltet · letzter Stand",
    observedLabel:
      "Aktualisiert: 07.10.26, 12:00. Aktuelle Restwerte unbekannt; angezeigt wird der letzte Stand.",
  },
};

export const Unknown: StoryObj<typeof KUsageDetails> = {
  name: "usage-details-unknown",
  parameters: { fixtureId: "usage-details-unknown" },
  args: {
    title: "Account-Kontingent",
    sourceLabel: "Anbieterabfrage",
    statusLabel: "Kontingent unbekannt",
    emptyMessage: "Die Anbieterabfrage war nicht verfügbar.",
    observedLabel: "Letzte Anbieterabfrage unbekannt",
  },
};

export const Narrow: StoryObj<typeof KUsageDetails> = {
  ...Subscription,
  name: "usage-details-narrow",
  parameters: { fixtureId: "usage-details-narrow" },
  decorators: [
    (Story) => (
      <div style={{ width: 320 }}>
        <Story />
      </div>
    ),
  ],
};
