import 'package:flutter/foundation.dart';



@immutable

class KMapZoneEditorLabels {

  const KMapZoneEditorLabels({

    this.editor = 'Einsatzgebiet festlegen',

    this.intro =

        'Wähle den einfachsten Einstieg. Du kannst Gebiete später verfeinern.',

    this.zones = 'Meine Gebiete',

    this.zone = 'Zone',

    this.zonePlural = 'Zonen',

    this.addZone = 'Zone hinzufügen',

    this.closePanel = 'Zonen schließen',

    this.empty =

        'Lege fest, wo du arbeitest: mit einem Umkreis, einem Postleitzahlgebiet oder einer eigenen Fläche.',

    this.allZones = 'Alle Zonen anzeigen',

    this.all = 'Alle',

    this.finishEditing =

        'Schließe die laufende Bearbeitung ab oder brich sie ab, bevor du wechselst.',

    this.radiusTitle = 'Umkreis',

    this.radiusDescription =

        'Schnell starten: Mittelpunkt und Luftlinien-Radius festlegen.',

    this.postalTitle = 'Postleitzahlen',

    this.postalDescription = 'Vorhandene PLZ-Flächen auf der Karte auswählen.',

    this.polygonTitle = 'Freie Grenze',

    this.polygonDescription =

        'Ein individuelles Gebiet zeichnen und präzise anpassen.',

    this.back = 'Zurück',

    this.newZoneName = 'Neues Einsatzgebiet',

    this.zoneName = 'Name',

    this.radius = 'Radius',

    this.airDistance = 'Luftlinie',

    this.postalSearch = 'PLZ oder Ort suchen',

    this.postalEmpty = 'Keine passenden PLZ-Flächen in diesem Ausschnitt.',

    this.postalSelection = 'Ausgewählt',

    this.sampleData = 'Datenquelle',

    this.assignedPostalArea = 'Bereits zugeordnet',

    this.customArea = 'Individuelle Fläche',

    this.addVertexHint =

        'Tippe in die Karte oder auf ein Plus, um Punkte hinzuzufügen.',

    this.vertices = 'Eckpunkte',

    this.removePoint = 'Letzten Punkt entfernen',

    this.undo = 'Rückgängig',

    this.apply = 'Gebiet übernehmen',

    this.cancel = 'Abbrechen',

    this.invalidCoordinate = 'Die Koordinaten des Gebiets sind ungültig.',

    this.minimumVertices = 'Ein Gebiet benötigt mindestens drei Eckpunkte.',

    this.selfIntersection = 'Die Grenze darf sich nicht selbst schneiden.',

    this.zoneOverlap = 'Gebiete dürfen sich nicht überlappen.',

    this.externalChange =

        'Das Gebiet wurde inzwischen geändert. Bitte neu öffnen.',

    this.moveCenter = 'Mittelpunkt verschieben',

    this.moveZone = 'Gebiet verschieben',

    this.resizeRadius = 'Radius verändern',

    this.addPointAfter = 'Punkt hinzufügen nach',

    this.unsavedTitle = 'Änderungen speichern?',

    this.unsavedDescription =

        'Du hast ungespeicherte Änderungen. Speichere oder verwirf sie, bevor du wechselst.',

    this.continueEditing = 'Weiter bearbeiten',

    this.discard = 'Verwerfen',

    this.save = 'Speichern',

    this.zoneNameRequired = 'Gib der Zone einen Namen, bevor du speicherst.',

    this.createFirstZone = 'Erstelle deine erste Zone',

    this.acceptChanges = 'Übernehmen',

    this.editZoneProperties = 'Zoneneigenschaften bearbeiten',

    this.zoneProperties = 'Zoneneigenschaften',

    this.zonePropertiesDescription =

        'Passe Darstellung, Anfahrtskosten, Zuschlag und Verfügbarkeit der Zone an.',

    this.zoneColor = 'Farbe',

    this.done = 'Fertig',

    this.editZone = 'Zone bearbeiten',

    this.deleteZone = 'Zone löschen',

    this.deleteZoneTitle = 'Zone löschen?',

    this.deleteZoneDescription = 'Möchtest du „{name}“ wirklich löschen?',

    this.confirmDeleteZone = 'Löschen',

    this.travelCost = 'Anfahrtskosten',

    this.perKilometerTravelCost = 'Pro Kilometer',

    this.flatRateTravelCost = 'Pauschal pro Buchung',

    this.freeTravelCost = 'Kostenlos',

    this.copyTravelCost = 'Anfahrtskosten aus anderer Zone übernehmen',

    this.selectTravelCostZone = 'Zone auswählen',

    this.travelCostAmount = 'Betrag',

    this.surcharge = 'Zuschlag',

    this.requestRequired = 'Buchungen nur auf Anfrage',

    this.surchargeAmount = 'Zonenzuschlag',

    this.availability = 'Verfügbarkeit',

    this.alwaysAvailability = 'Ohne Datumsbegrenzung',

    this.recurringAvailability = 'Wiederkehrend',

    this.dateRangeAvailability = 'Fester Zeitraum',

    this.weekdays = 'Wochentage',

    this.recurrenceEvery = 'Alle',

    this.recurrenceUnit = 'Einheit',

    this.recurrenceDays = 'Tage',

    this.recurrenceWeeks = 'Wochen',

    this.recurrenceMonths = 'Monate',

    this.recurrenceYears = 'Jahre',

    this.recurrenceMonthlyMode = 'Monatliche Wiederholung',

    this.recurrenceMonthDate = 'Am gleichen Kalendertag',

    this.recurrenceMonthWeekday = 'Am gleichen Wochentag',

    this.showOccurrences = 'Nächste Termine anzeigen',

    this.intervalWeeks = 'Alle wie viele Wochen',

    this.startDate = 'Beginn',

    this.endDate = 'Ende',

    this.recurrenceDetails = 'Zeitraum und Einschränkungen',

    this.months = 'Nur in diesen Monaten',

    this.everyWeek = 'jede Woche',

    this.everyWeeks = 'alle {count} Wochen',

    this.recurrenceSummary = '{details}',

    this.recurrenceAnchorSummary = 'ab {date}',

    this.recurrenceEndSummary = 'bis {date}',

    this.recurrenceMonthsSummary = 'in {months}',

    this.nextOccurrences = 'Nächste Termine',

    this.noUpcomingOccurrences = 'Keine weiteren Termine in diesem Zeitraum.',

    this.overlapTitle = 'Überlappung übernehmen?',

    this.overlapDescription =

        'Die bearbeitete Zone hat Vorrang. Betroffene Zonen werden automatisch angepasst.',

    this.overlapReduced = 'wird verkleinert',

    this.overlapRemoved = 'wird entfernt',

    this.confirmOverlap = 'Anpassen und übernehmen',

    this.changesApplied = 'Zonen wurden angepasst.',

    this.dismiss = 'Hinweis schließen',

    this.invalidTravelCost = 'Gib einen gültigen Betrag ab 0 ein.',

    this.invalidSurcharge = 'Der Zuschlag muss mindestens 0 betragen.',

    this.chooseWeekday = 'Wähle mindestens einen Wochentag.',

    this.invalidInterval =

        'Das Wiederholungsintervall muss mindestens eine Woche sein.',

    this.invalidDateRange =

        'Wähle einen gültigen Zeitraum mit Beginn und Ende.',

    this.intervalAnchor = 'Wiederholung ab',

    this.intervalAnchorRequired =

        'Wähle ein Startdatum für ein mehrwöchiges Intervall.',

    this.invalidRecurrence =

        'Wähle Wochentage, Startdatum und eine unterstützte wöchentliche Wiederholung.',

    this.startWeekdayMismatch =

        'Das Startdatum muss auf einen ausgewählten Wochentag fallen.',

    this.move = 'Verschieben',

    this.draw = 'Zeichnen',

    this.selectZone = 'Gebiet auswählen',

  });



  final String editor;

  final String intro;

  final String zones;

  final String zone;

  final String zonePlural;

  final String addZone;

  final String closePanel;

  final String empty;

  final String allZones;

  final String all;

  final String finishEditing;

  final String radiusTitle;

  final String radiusDescription;

  final String postalTitle;

  final String postalDescription;

  final String polygonTitle;

  final String polygonDescription;

  final String back;

  final String newZoneName;

  final String zoneName;

  final String radius;

  final String airDistance;

  final String postalSearch;

  final String postalEmpty;

  final String postalSelection;

  final String sampleData;

  final String assignedPostalArea;

  final String customArea;

  final String addVertexHint;

  final String vertices;

  final String removePoint;

  final String undo;

  final String apply;

  final String cancel;

  final String invalidCoordinate;

  final String minimumVertices;

  final String selfIntersection;

  final String zoneOverlap;

  final String externalChange;

  final String moveCenter;

  final String moveZone;

  final String resizeRadius;

  final String addPointAfter;

  final String unsavedTitle;

  final String unsavedDescription;

  final String continueEditing;

  final String discard;

  final String save;

  final String zoneNameRequired;

  final String createFirstZone;

  final String acceptChanges;

  final String editZoneProperties;

  final String zoneProperties;

  final String zonePropertiesDescription;

  final String zoneColor;

  final String done;

  final String editZone;

  final String deleteZone;

  final String deleteZoneTitle;

  final String deleteZoneDescription;

  final String confirmDeleteZone;

  final String travelCost;

  final String perKilometerTravelCost;

  final String flatRateTravelCost;

  final String freeTravelCost;

  final String copyTravelCost;

  final String selectTravelCostZone;

  final String travelCostAmount;

  final String surcharge;

  final String requestRequired;

  final String surchargeAmount;

  final String availability;

  final String alwaysAvailability;

  final String recurringAvailability;

  final String dateRangeAvailability;

  final String weekdays;

  final String recurrenceEvery;

  final String recurrenceUnit;

  final String recurrenceDays;

  final String recurrenceWeeks;

  final String recurrenceMonths;

  final String recurrenceYears;

  final String recurrenceMonthlyMode;

  final String recurrenceMonthDate;

  final String recurrenceMonthWeekday;

  final String showOccurrences;

  final String intervalWeeks;

  final String startDate;

  final String endDate;

  final String recurrenceDetails;

  final String months;

  final String everyWeek;

  final String everyWeeks;

  final String recurrenceSummary;

  final String recurrenceAnchorSummary;

  final String recurrenceEndSummary;

  final String recurrenceMonthsSummary;

  final String nextOccurrences;

  final String noUpcomingOccurrences;

  final String overlapTitle;

  final String overlapDescription;

  final String overlapReduced;

  final String overlapRemoved;

  final String confirmOverlap;

  final String changesApplied;

  final String dismiss;

  final String invalidTravelCost;

  final String invalidSurcharge;

  final String chooseWeekday;

  final String invalidInterval;

  final String invalidDateRange;

  final String intervalAnchor;

  final String intervalAnchorRequired;

  final String invalidRecurrence;

  final String startWeekdayMismatch;

  final String move;

  final String draw;

  final String selectZone;



  String validationMessage(String code) => switch (code) {

    'minimum-vertices' => minimumVertices,

    'self-intersection' => selfIntersection,

    'zone-overlap' => zoneOverlap,

    'external-change' => externalChange,

    _ => invalidCoordinate,

  };

}
