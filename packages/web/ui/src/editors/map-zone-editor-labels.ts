export interface KMapZoneEditorLabels {
  editor: string;

  intro: string;

  zones: string;

  zone: string;

  zonePlural: string;

  addZone: string;

  closePanel: string;

  empty: string;

  allZones: string;

  all: string;

  finishEditing: string;

  radiusTitle: string;

  radiusDescription: string;

  postalTitle: string;

  postalDescription: string;

  polygonTitle: string;

  polygonDescription: string;

  back: string;

  newZoneName: string;

  zoneName: string;

  radius: string;

  airDistance: string;

  postalSearch: string;

  postalEmpty: string;

  postalSelection: string;

  sampleData: string;

  assignedPostalArea: string;

  customArea: string;

  addVertexHint: string;

  vertices: string;

  removePoint: string;

  undo: string;

  apply: string;

  cancel: string;

  invalidCoordinate: string;

  minimumVertices: string;

  selfIntersection: string;

  zoneOverlap: string;

  externalChange: string;

  moveCenter: string;

  moveZone: string;

  resizeRadius: string;

  addPointAfter: string;

  unsavedTitle: string;

  unsavedDescription: string;

  continueEditing: string;

  discard: string;

  save: string;

  zoneNameRequired: string;

  createFirstZone: string;

  acceptChanges: string;

  editZoneProperties: string;

  zoneProperties: string;

  zonePropertiesDescription: string;

  zoneColor: string;

  done: string;

  editZone: string;

  deleteZone: string;

  deleteZoneTitle: string;

  deleteZoneDescription: string;

  confirmDeleteZone: string;

  travelCost: string;

  perKilometerTravelCost: string;

  flatRateTravelCost: string;

  freeTravelCost: string;

  copyTravelCost: string;

  chooseTravelCostSource: string;

  travelCostAmount: string;

  requestRequired: string;

  surcharge: string;

  surchargeAmount: string;

  availability: string;

  alwaysAvailability: string;

  recurringAvailability: string;

  dateRangeAvailability: string;

  weekdays: string;

  recurrenceEvery?: string;

  recurrenceUnit?: string;

  recurrenceUnits?: {
    daily: string;

    weekly: string;

    monthly: string;

    yearly: string;
  };

  recurrenceMonthlyMode?: string;

  recurrenceMonthDate?: string;

  recurrenceMonthWeekday?: string;

  occurrenceHint?: string;
  showOccurrences?: string;

  intervalWeeks: string;

  startDate: string;

  endDate: string;

  recurrenceDetails: string;

  months: string;

  everyWeek: string;

  everyWeeks: string;

  recurrenceSummary: string;

  recurrenceAnchorSummary: string;

  recurrenceEndSummary: string;

  recurrenceMonthsSummary: string;

  nextOccurrences: string;

  noUpcomingOccurrences: string;

  overlapTitle: string;

  overlapDescription: string;

  overlapReduced: string;

  overlapRemoved: string;

  confirmOverlap: string;

  changesApplied: string;

  dismiss: string;

  invalidTravelCost: string;

  invalidSurcharge: string;

  chooseWeekday: string;

  invalidInterval: string;

  invalidDateRange: string;

  intervalAnchor: string;

  intervalAnchorRequired: string;

  invalidRecurrence: string;

  startWeekdayMismatch: string;
}

export const kDefaultMapZoneEditorLabels: KMapZoneEditorLabels = {
  editor: "Einsatzgebiet festlegen",

  intro: "Wähle den einfachsten Einstieg. Du kannst Gebiete später verfeinern.",

  zones: "Meine Gebiete",

  zone: "Zone",

  zonePlural: "Zonen",

  addZone: "Zone hinzufügen",

  closePanel: "Zonen schließen",

  empty:
    "Lege fest, wo du arbeitest: mit einem Umkreis, einem Postleitzahlgebiet oder einer eigenen Fläche.",

  allZones: "Alle Zonen anzeigen",

  all: "Alle",

  finishEditing:
    "Schließe die laufende Bearbeitung ab oder brich sie ab, bevor du wechselst.",

  radiusTitle: "Umkreis",

  radiusDescription:
    "Schnell starten: Mittelpunkt und Luftlinien-Radius festlegen.",

  postalTitle: "Postleitzahlen",

  postalDescription: "Vorhandene PLZ-Flächen auf der Karte auswählen.",

  polygonTitle: "Freie Grenze",

  polygonDescription: "Ein individuelles Gebiet zeichnen und präzise anpassen.",

  back: "Zurück",

  newZoneName: "Neues Einsatzgebiet",

  zoneName: "Name",

  radius: "Radius",

  airDistance: "Luftlinie",

  postalSearch: "PLZ oder Ort suchen",

  postalEmpty: "Keine passenden PLZ-Flächen in diesem Ausschnitt.",

  postalSelection: "Ausgewählt",

  sampleData: "Datenquelle",

  assignedPostalArea: "Bereits zugeordnet",

  customArea: "Individuelle Fläche",

  addVertexHint:
    "Tippe in die Karte oder auf ein Plus, um Punkte hinzuzufügen.",

  vertices: "Eckpunkte",

  removePoint: "Letzten Punkt entfernen",

  undo: "Rückgängig",

  apply: "Gebiet übernehmen",

  cancel: "Abbrechen",

  invalidCoordinate: "Die Koordinaten des Gebiets sind ungültig.",

  minimumVertices: "Ein Gebiet benötigt mindestens drei Eckpunkte.",

  selfIntersection: "Die Grenze darf sich nicht selbst schneiden.",

  zoneOverlap: "Gebiete dürfen sich nicht überlappen.",

  externalChange: "Das Gebiet wurde inzwischen geändert. Bitte neu öffnen.",

  moveCenter: "Mittelpunkt verschieben",

  moveZone: "Gebiet verschieben",

  resizeRadius: "Radius verändern",

  addPointAfter: "Punkt hinzufügen nach",

  unsavedTitle: "Änderungen speichern?",

  unsavedDescription:
    "Du hast ungespeicherte Änderungen. Speichere oder verwirf sie, bevor du wechselst.",

  continueEditing: "Weiter bearbeiten",

  discard: "Verwerfen",

  save: "Speichern",

  zoneNameRequired: "Gib der Zone einen Namen, bevor du speicherst.",

  createFirstZone: "Erstelle deine erste Zone",

  acceptChanges: "Übernehmen",

  editZoneProperties: "Zoneneigenschaften bearbeiten",

  zoneProperties: "Zoneneigenschaften",

  zonePropertiesDescription:
    "Passe Darstellung, Anfahrtskosten, Zuschlag und Verfügbarkeit der Zone an.",

  zoneColor: "Farbe",

  done: "Fertig",

  editZone: "Zone bearbeiten",

  deleteZone: "Zone löschen",

  deleteZoneTitle: "Zone löschen?",

  deleteZoneDescription: "Möchtest du „{name}“ wirklich löschen?",

  confirmDeleteZone: "Löschen",

  travelCost: "Anfahrtskosten",

  perKilometerTravelCost: "Pro Kilometer",

  flatRateTravelCost: "Pauschal pro Buchung",

  freeTravelCost: "Kostenlos",

  copyTravelCost: "Anfahrtskosten aus anderer Zone übernehmen",

  chooseTravelCostSource: "Zone auswählen",

  travelCostAmount: "Betrag",

  requestRequired: "Buchungen nur auf Anfrage",

  surcharge: "Zonenzuschlag",

  surchargeAmount: "Betrag",

  availability: "Verfügbarkeit",

  alwaysAvailability: "Ohne Datumsbegrenzung",

  recurringAvailability: "Wiederkehrend",

  dateRangeAvailability: "Fester Zeitraum",

  weekdays: "Wochentage",

  intervalWeeks: "Alle wie viele Wochen",

  startDate: "Beginn",

  endDate: "Ende",

  recurrenceDetails: "Zeitraum und Einschränkungen",

  months: "Nur in diesen Monaten",

  everyWeek: "jede Woche",

  everyWeeks: "alle {count} Wochen",

  recurrenceSummary: "{details}",

  recurrenceAnchorSummary: "ab {date}",

  recurrenceEndSummary: "bis {date}",

  recurrenceMonthsSummary: "in {months}",

  nextOccurrences: "Nächste Termine",

  noUpcomingOccurrences: "Keine weiteren Termine in diesem Zeitraum.",

  overlapTitle: "Überlappung übernehmen?",

  overlapDescription:
    "Die bearbeitete Zone hat Vorrang. Betroffene Zonen werden automatisch angepasst.",

  overlapReduced: "wird verkleinert",

  overlapRemoved: "wird entfernt",

  confirmOverlap: "Anpassen und übernehmen",

  changesApplied: "Zonen wurden angepasst.",

  dismiss: "Hinweis schließen",

  invalidTravelCost: "Gib einen gültigen Betrag ab 0 ein.",

  invalidSurcharge: "Der Zuschlag muss mindestens 0 betragen.",

  chooseWeekday: "Wähle mindestens einen Wochentag.",

  invalidInterval:
    "Das Wiederholungsintervall muss mindestens eine Woche sein.",

  invalidDateRange: "Wähle einen gültigen Zeitraum mit Beginn und Ende.",

  intervalAnchor: "Wiederholung ab",

  intervalAnchorRequired:
    "Wähle ein Startdatum für ein mehrwöchiges Intervall.",

  invalidRecurrence:
    "Wähle Wochentage, Startdatum und eine unterstützte wöchentliche Wiederholung.",

  startWeekdayMismatch:
    "Das Startdatum muss auf einen ausgewählten Wochentag fallen.",
};
