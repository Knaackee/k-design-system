import type { KIconName } from "@k-design-system/ui";

export const adminPages = {
  overview: [
    "Übersicht",
    "chart-no-axes-combined",
    "Alle Kennzahlen im gewählten Zeitraum.",
  ],
  customers: ["Kundenliste", "users", "7 Betriebe"],
  access: [
    "Zugang & Registrierung",
    "key-round",
    "Wer sich registrieren darf und wer Admin ist.",
  ],
  growth: ["Wachstum & Herkunft", "trending-up", "Woher neue Betriebe kommen."],
  subscriptions: [
    "Abos & Zahlungen",
    "credit-card",
    "Tarife, Abonnements und Rechnungen.",
  ],
  waitlist: [
    "Warteliste",
    "list",
    "Interessent:innen, die auf eine Einladung warten.",
  ],
  invitations: [
    "Versendete Einladungen",
    "mail",
    "Versand, Ablauf und Einlösung auf einen Blick.",
  ],
  applications: [
    "Bewerbungen",
    "star",
    "Menschen, die Onzeit empfehlen möchten.",
  ],
  partners: [
    "Partnerschaften",
    "link",
    "Aktive Ambassadors und ihre Empfehlungen.",
  ],
  operations: [
    "Betrieb & Integrationen",
    "server",
    "Zustand von Server und Diensten.",
  ],
  assistant: [
    "KI-Assistent",
    "sparkles",
    "Gilt für alle Nutzer:innen dieses Servers.",
  ],
  audit: [
    "Aktivitätsprotokoll",
    "clock",
    "Alle Admin-Aktionen, nicht änderbar.",
  ],
} satisfies Record<string, [string, KIconName, string]>;
export type AdminPage = keyof typeof adminPages;
export const adminGroups: [string, AdminPage[]][] = [
  ["", ["overview"]],
  ["Kunden & Betriebe", ["customers", "access", "growth", "subscriptions"]],
  ["Einladungen", ["waitlist", "invitations"]],
  ["Ambassadors", ["applications", "partners"]],
  ["System", ["operations", "assistant", "audit"]],
];
export const customers = [
  [
    "Mara Krüger",
    "Mara Hair Mobile",
    "mara@example.invalid",
    "Friseurin",
    "Pro",
    "Aktiv",
    "Leipzig",
    "12.03.2026",
    "214",
  ],
  [
    "Tom Becker",
    "Fit at Home",
    "tom@example.invalid",
    "Personal Trainer",
    "Solo",
    "Aktiv",
    "München",
    "02.05.2026",
    "96",
  ],
  [
    "Sophie Wagner",
    "Glow Nails",
    "sophie@example.invalid",
    "Nageldesign",
    "Pro",
    "Testphase",
    "Wien",
    "28.10.2026",
    "4",
  ],
  [
    "Lukas Hoffmann",
    "Bike Doc",
    "lukas@example.invalid",
    "Fahrrad-Service",
    "Team",
    "Aktiv",
    "Hamburg",
    "17.01.2026",
    "388",
  ],
  [
    "Nina Schulz",
    "Pfoten-Spa",
    "nina@example.invalid",
    "Hundefriseurin",
    "Solo",
    "Gesperrt",
    "Köln",
    "09.07.2026",
    "31",
  ],
  [
    "Denis Knaack",
    "Onzeit Demo",
    "denis@example.invalid",
    "Bike-Service",
    "Pro",
    "Aktiv",
    "Steinberg am See",
    "03.11.2026",
    "0",
  ],
  [
    "Aylin Demir",
    "Make-up by Aylin",
    "aylin@example.invalid",
    "Visagistin",
    "Pro",
    "Gekündigt",
    "Berlin",
    "21.02.2026",
    "142",
  ],
];
export const administrators = [
  ["Denis Knaack", "denis@example.invalid", "Owner"],
  ["Julia Roth", "julia@example.invalid", "Admin"],
  ["Ben Yilmaz", "ben@example.invalid", "Support"],
];
export const roles = [
  ["Owner", "Alles, inkl. Admins und Abrechnung"],
  ["Admin", "Kund:innen, Einladungen, Ambassadors, System"],
  ["Support", "Kund:innen ansehen, Einladungen erneut senden"],
  ["Lesen", "Nur Übersicht und Berichte"],
];
export const waitlist = [
  [
    "lea@example.invalid",
    "Friseurin",
    "Instagram",
    "DE",
    "04.11.2026",
    "Neu",
    "",
  ],
  [
    "mira@example.invalid",
    "Nageldesign",
    "Ambassador · @mirasnails",
    "DE",
    "03.11.2026",
    "Neu",
    "Kennt Sophie Wagner",
  ],
  [
    "tom.coach@example.invalid",
    "Personal Trainer",
    "Google",
    "EN",
    "03.11.2026",
    "Neu",
    "",
  ],
  [
    "sophie.massage@example.invalid",
    "Massage",
    "TikTok",
    "DE",
    "02.11.2026",
    "Freigegeben",
    "",
  ],
  [
    "spam@example.invalid",
    "–",
    "Direkt",
    "–",
    "31.10.2026",
    "Abgelehnt",
    "Spam",
  ],
];
export const invitations = [
  ["sophie.massage@example.invalid", "Zugestellt", "09.11.2026", "Offen"],
  ["denis.demo@example.invalid", "Zugestellt", "10.11.2026", "Eingelöst"],
  ["jan@example.invalid", "Fehlgeschlagen", "08.11.2026", "Offen"],
  ["carla@example.invalid", "Zugestellt", "27.10.2026", "Abgelaufen"],
];
export const applications = [
  [
    "Mira Lehmann",
    "@mirasnails · Instagram",
    "18.400",
    "Nails, Selbstständigkeit",
    "DE",
    "Ich zeige jede Woche, wie ich als mobile Nageldesignerin arbeite – Onzeit passt perfekt.",
    "Neu",
  ],
  [
    "Jonas Feld",
    "@bikejonas · YouTube",
    "42.000",
    "Fahrrad, Werkstatt",
    "DE",
    "Viele meiner Zuschauer machen mobile Reparaturen.",
    "In Prüfung",
  ],
  [
    "Elif Kaya",
    "@elif.hair · TikTok",
    "7.900",
    "Haare, Beauty",
    "TR",
    "Ich möchte Onzeit in der türkischen Community bekannt machen.",
    "Neu",
  ],
];
export const partners = [
  ["Sophie Wagner", "https://example.invalid/sophie", "46", "31", "Aktiv"],
  ["Lukas Hoffmann", "https://example.invalid/bikedoc", "28", "12", "Aktiv"],
  ["Mara Krüger", "https://example.invalid/mara", "9", "22", "Pausiert"],
];
export const systems = [
  ["Server", "Produktionsserver · v0.1.0+1", "Stabil"],
  ["E-Mail", "SMTP · 99,2 % zugestellt (7 Tage)", "Stabil"],
  ["Push", "FCM · 3 fehlgeschlagen heute", "Verzögert"],
  ["Synchronisierung", "Letzter Lauf vor 2 Min · 0 Konflikte", "Stabil"],
  ["Zahlungen", "Stripe · Webhooks aktiv", "Stabil"],
];
export const errors = [
  ["Push nicht zugestellt", "Token abgelaufen · 3 Geräte", "08:12"],
  [
    "Einladung nicht zustellbar",
    "jan@example.invalid · Mailbox voll",
    "gestern",
  ],
  ["Sync-Timeout", "Kund:in Lukas Hoffmann · automatisch erneut", "gestern"],
];
export const versions = [
  ["Android", "0.1.0+1", "78 %"],
  ["iOS", "0.1.0+1", "61 %"],
  ["Web", "2026.11.03", "100 %"],
];
export const logs = [
  [
    "Denis Knaack",
    "Kund:in gesperrt",
    "Nina Schulz",
    "04.11. 08:31",
    "Erfolgreich",
  ],
  [
    "Julia Roth",
    "Warteliste freigegeben",
    "sophie@example.invalid",
    "03.11. 17:02",
    "Erfolgreich",
  ],
  [
    "Ben Yilmaz",
    "Einladung erneut gesendet",
    "jan@example.invalid",
    "03.11. 15:44",
    "Fehlgeschlagen",
  ],
  [
    "Denis Knaack",
    "KI-Modell geändert",
    "Demo-Modell",
    "02.11. 21:10",
    "Erfolgreich",
  ],
  [
    "Julia Roth",
    "Ambassador angenommen",
    "Sophie Wagner",
    "01.11. 10:05",
    "Erfolgreich",
  ],
];
export const paymentFailures = [
  ["Aylin Demir", "Pro · 39,00 €", "Karte abgelaufen", "02.11.2026"],
  ["Tom Becker", "Solo · 19,00 €", "Unzureichende Deckung", "01.11.2026"],
];
export const invoices = [
  ["ONZ-2026-1184", "Lukas Hoffmann", "79,00 €", "Bezahlt"],
  ["ONZ-2026-1183", "Mara Krüger", "39,00 €", "Bezahlt"],
  ["ONZ-2026-1182", "Aylin Demir", "39,00 €", "Fehlgeschlagen"],
  ["ONZ-2026-1181", "Tom Becker", "19,00 €", "Offen"],
];
