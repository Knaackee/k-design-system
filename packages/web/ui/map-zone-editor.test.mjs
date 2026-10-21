import assert from "node:assert/strict";
import test from "node:test";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMapZoneEditor } from "./dist/editors/index.js";
import { kDefaultMapZoneEditorLabels } from "./dist/editors/map-zone-editor-labels.js";
import {
  screenSpacedRingHandles,
  selectableZoneForMapClick,
  updateDraftForPin,
} from "./dist/editors/map-zone-editor-map.js";
import { HomePanel } from "./dist/editors/map-zone-editor-panels.js";
import {
  createPostalZones,
  editorVisibleZones,
  isZoneChange,
  removeZone,
  updateZoneProperties,
} from "./dist/editors/map-zone-editor-state.js";
import {
  copyZoneTravelCost,
  createZoneWeeklyRRule,
  normalizeZoneSettings,
  parseZoneWeeklyRRule,
} from "./dist/editors/map-zone-editor-properties-state.js";
import { formatMapZoneTravelCost } from "./dist/editors/map-zone-editor-properties.js";
import {
  defaultZoneRecurrence,
  matchingDateInAnchorWeek,
  nextZoneOccurrences,
} from "./dist/editors/map-zone-editor-recurrence.js";
import { KMap } from "./dist/patterns/map.js";

const mapStyle = { version: 8, sources: {}, layers: [] };
const rectangle = (west, south, east, north) => [
  [west, south],
  [east, south],
  [east, north],
  [west, north],
];
const zones = [
  {
    id: "west",
    name: "Westen",
    coordinates: [
      [13.3, 52.5],
      [13.31, 52.5],
      [13.31, 52.51],
    ],
  },
  {
    id: "mitte",
    name: "Mitte",
    coordinates: [
      [13.38, 52.5],
      [13.39, 52.5],
      [13.39, 52.51],
    ],
  },
  {
    id: "ost",
    name: "Osten",
    coordinates: [
      [13.44, 52.5],
      [13.45, 52.5],
      [13.45, 52.51],
    ],
  },
];

const render = (props = {}) =>
  renderToStaticMarkup(
    React.createElement(KMapZoneEditor, {
      zones,
      selectedZoneId: null,
      mapProps: { mapStyle, center: [13.4, 52.5] },
      onChange: () => undefined,
      onSelect: () => undefined,
      ...props,
    }),
  );

test("starts map-first with count and add controls while the panel stays closed", () => {
  const html = render();
  assert.match(html, /aria-expanded="false"/);
  assert.match(html, /aria-label="3 Zonen"/);
  assert.match(html, /aria-label="3 Zonen"[^>]*><span[^>]*class="k-icon/);
  assert.match(html, />Alle<\/span>/);
  assert.match(html, /aria-label="Zone hinzufügen"/);
  assert.doesNotMatch(html, /class="k-map-zone-editor__panel"/);
  assert.match(
    html,
    /class="k-map-zone-editor__properties-segment" aria-hidden="true"/,
  );
});

test("a concrete selection adds properties to the bounded bottom pill", () => {
  const html = render({ selectedZoneId: "mitte" });
  assert.match(html, />Mitte<\/span>/);
  assert.match(html, /aria-label="Zoneneigenschaften bearbeiten"/);
  assert.doesNotMatch(html, /k-map-zone-editor__name-bar/);
});

test("a single selected zone keeps the normal toolbar visible in SSR", () => {
  const html = render({ zones: [zones[1]], selectedZoneId: "mitte" });
  assert.match(
    html,
    /class="k-map-zone-editor__toolbar"[^>]*data-visible="true"/,
  );
  assert.match(
    html,
    /class="k-map-zone-editor__properties-segment"[^>]*data-visible="true"/,
  );
});

test("the zone list opens as a non-modal floating dialog above the usable toolbar", () => {
  const html = render({ defaultPanelOpen: true });
  assert.match(html, /class="k-map-zone-editor__floating-dialog"/);
  assert.match(html, /role="dialog"/);
  assert.match(html, /data-k-escape-boundary=""/);
  assert.match(html, /aria-expanded="true"/);
  assert.match(html, /Zone hinzufügen/);
  assert.doesNotMatch(html, /k-overlay-backdrop/);

  const emptyCreation = render({ zones: [], defaultPanelOpen: true });
  assert.match(emptyCreation, /class="k-map-zone-editor__toolbar"/);
  assert.match(emptyCreation, /class="k-map-zone-editor__floating-dialog"/);
});

test("saved-zone dialog content always starts with the overview action", () => {
  const html = renderToStaticMarkup(
    React.createElement(HomePanel, {
      labels: kDefaultMapZoneEditorLabels,
      zones,
      selectedZoneId: null,
      createMode: false,
      editingZoneId: null,
      disabled: false,
      onSelect: () => undefined,
      onEdit: () => undefined,
      onDelete: () => undefined,
      onShowAll: () => undefined,
      onStartRadius: () => undefined,
      onStartPostal: () => undefined,
      onStartPolygon: () => undefined,
    }),
  );
  assert.match(html, /Alle Zonen anzeigen/);
  assert.match(html, /aria-pressed="true"[^>]*><span/);
  assert.match(html, /aria-label="Zone bearbeiten: Mitte"/);
  assert.match(html, /aria-label="Zone löschen: Mitte"/);
  assert.doesNotMatch(html, /Schnell starten: Mittelpunkt/);
});

test("removing a zone is immutable and preserves every other saved edit", () => {
  const edited = zones.map((zone) =>
    zone.id === "west" ? { ...zone, name: "West neu" } : zone,
  );
  const remaining = removeZone(edited, "mitte");
  assert.deepEqual(
    remaining.map(({ id, name }) => ({ id, name })),
    [
      { id: "west", name: "West neu" },
      { id: "ost", name: "Osten" },
    ],
  );
  assert.equal(edited.length, 3);
});

test("properties update only their target and preserve geometry", () => {
  const updated = updateZoneProperties(zones, "mitte", {
    name: "Mitte neu",
    color: "#ef4444",
  });
  assert.equal(updated[0], zones[0]);
  assert.deepEqual(updated[1].coordinates, zones[1].coordinates);
  assert.equal(updated[1].name, "Mitte neu");
  assert.equal(updated[1].color, "#ef4444");
});

test("postal code used as its own label is not duplicated in new zone names", () => {
  const area = {
    id: "postal-92449",
    country: "DE",
    code: "92449",
    label: "92449",
    coordinates: rectangle(12.1, 49.2, 12.2, 49.3),
    sourceLabel: "Synthetic",
    sourceVersion: "v1",
  };
  const preview = editorVisibleZones("postal", [], null, [area], []);
  const committed = createPostalZones([], [area], [area.id], undefined);
  assert.equal(preview[0].name, "92449");
  assert.equal(committed[0].name, "92449");
});

test("pin drag previews update geometry without mutating the source zone", () => {
  const original = {
    ...zones[0],
    kind: "postal",
    coordinates: zones[0].coordinates.map((point) => [...point]),
  };
  const preview = updateDraftForPin(original, "zone-vertex-1", [13.5, 52.6]);
  assert.deepEqual(preview.coordinates[1], [13.5, 52.6]);
  assert.equal(preview.kind, "polygon");
  assert.deepEqual(original.coordinates[1], [13.31, 52.5]);
  assert.equal(isZoneChange(original, original), false);
  assert.equal(isZoneChange(original, preview), true);
});

test("dense zone handles keep their original indices and the active drag", () => {
  const ring = Array.from({ length: 8 }, (_, index) => [
    13.4 + index * 0.0001,
    52.5,
  ]);
  const snapshot = structuredClone(ring);
  const handles = screenSpacedRingHandles(
    ring,
    ring.map((_, index) => index),
    14,
    { kind: "midpoint", index: 6 },
  );
  assert.deepEqual(handles, { vertices: [], midpoints: [6] });
  assert.deepEqual(ring, snapshot);
});

test("short edges prioritize distributed vertices over overlapping midpoints", () => {
  const ring = Array.from({ length: 80 }, (_, index) => [
    13.4 + index * 0.0001,
    52.5,
  ]);
  const handles = screenSpacedRingHandles(
    ring,
    ring.map((_, index) => index),
    14,
  );
  assert.ok(handles.vertices.length > 1);
  assert.ok(handles.vertices.length < ring.length);
  assert.deepEqual(handles.midpoints, []);
});

test("separate rings share one screen-space occupancy budget", () => {
  const occupied = [];
  const first = screenSpacedRingHandles(
    rectangle(13.3, 52.4, 13.5, 52.6),
    [0],
    14,
    undefined,
    44,
    occupied,
  );
  const second = screenSpacedRingHandles(
    rectangle(13.30001, 52.40001, 13.50001, 52.60001),
    [0],
    14,
    undefined,
    44,
    occupied,
  );
  const activeSecond = screenSpacedRingHandles(
    rectangle(13.30001, 52.40001, 13.50001, 52.60001),
    [0],
    14,
    { kind: "midpoint", index: 0 },
    44,
    occupied,
  );
  assert.deepEqual(first.vertices, [0]);
  assert.deepEqual(second, { vertices: [], midpoints: [] });
  assert.deepEqual(activeSecond, { vertices: [], midpoints: [0] });
});

test("well-separated zone handles remain available", () => {
  const ring = rectangle(13.3, 52.4, 13.5, 52.6);
  assert.deepEqual(screenSpacedRingHandles(ring, [0, 1, 2, 3], 14), {
    vertices: [0, 1, 2, 3],
    midpoints: [0, 1, 2, 3],
  });
});

test("multipart and hole vertex edits target one ring while moving preserves all rings", () => {
  const multipart = {
    id: "multi",
    name: "Multi",
    coordinates: rectangle(0, 0, 4, 4),
    polygons: [
      {
        outer: rectangle(0, 0, 4, 4),
        holes: [rectangle(1, 1, 2, 2)],
      },
      { outer: rectangle(5, 0, 6, 1) },
    ],
  };
  const edited = updateDraftForPin(multipart, "zone-vertex-0-1-2", [2.5, 2.5]);
  assert.deepEqual(edited.polygons[0].holes[0][2], [2.5, 2.5]);
  assert.deepEqual(edited.polygons[1], multipart.polygons[1]);
  const moved = updateDraftForPin(multipart, "zone-move", [4, 2]);
  assert.equal(moved.polygons.length, 2);
  assert.equal(moved.polygons[0].holes.length, 1);
  const delta = moved.polygons[0].outer[0].map(
    (coordinate, index) => coordinate - multipart.polygons[0].outer[0][index],
  );
  assert.deepEqual(
    moved.polygons[1].outer[0],
    multipart.polygons[1].outer[0].map(
      (coordinate, index) => coordinate + delta[index],
    ),
  );
  assert.deepEqual(
    moved.polygons[0].holes[0][0],
    multipart.polygons[0].holes[0][0].map(
      (coordinate, index) => coordinate + delta[index],
    ),
  );
});

test("zone settings default and reject invalid enabled values", () => {
  for (const kind of ["per-kilometer", "flat-rate"]) {
    assert.equal(
      normalizeZoneSettings(
        { travelCost: { kind, amount: 0, currency: "EUR" } },
        undefined,
      ).error,
      null,
    );
    assert.equal(
      normalizeZoneSettings(
        { travelCost: { kind, amount: -1, currency: "EUR" } },
        undefined,
      ).error,
      "travel-cost",
    );
  }
  const options = {
    weekdayOptions: [
      { value: "MO", label: "Monday" },
      { value: "TU", label: "Tuesday" },
    ],
    currency: "EUR",
    timeZone: "Europe/Berlin",
    defaultTravelCost: {
      kind: "per-kilometer",
      amount: 0.7,
      currency: "EUR",
    },
  };
  assert.deepEqual(normalizeZoneSettings(undefined, options), {
    settings: { travelCost: options.defaultTravelCost },
    error: null,
  });
  for (const kind of ["per-kilometer", "flat-rate"])
    assert.equal(
      normalizeZoneSettings(
        { travelCost: { kind, amount: Number.NaN, currency: "EUR" } },
        options,
      ).error,
      "travel-cost",
    );
  assert.equal(
    normalizeZoneSettings({ travelCost: { kind: "free" } }, options).error,
    null,
  );
  assert.equal(
    normalizeZoneSettings(
      {
        availability: {
          kind: "recurring",
          rrule: "FREQ=WEEKLY;BYDAY=",
          startDate: "2026-10-19",
          timeZone: "Europe/Berlin",
        },
      },
      options,
    ).error,
    "weekdays",
  );
  assert.equal(
    normalizeZoneSettings(
      {
        availability: {
          kind: "recurring",
          rrule: "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO",
          startDate: "",
          timeZone: "Europe/Berlin",
        },
      },
      options,
    ).error,
    "recurrence",
  );
  assert.equal(
    normalizeZoneSettings(
      {
        availability: {
          kind: "recurring",
          rrule: "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO",
          startDate: "2026-10-20",
          timeZone: "Europe/Berlin",
        },
      },
      options,
    ).error,
    "start-weekday",
  );
  assert.equal(
    normalizeZoneSettings(
      {
        availability: {
          kind: "date-range",
          from: "2026-10-22",
          to: "2026-10-21",
        },
      },
      options,
    ).error,
    "date-range",
  );
  assert.equal(
    normalizeZoneSettings(
      { surcharge: { amount: Number.NaN, currency: "EUR" } },
      options,
    ).error,
    "surcharge",
  );
});

test("zone travel costs can be copied independently and display their rate in source options", () => {
  const original = {
    name: "Mitte",
    color: "#155dfc",
    settings: { travelCost: { kind: "free" } },
    surchargeEnabled: false,
    travelAmounts: { "per-kilometer": "", "flat-rate": "" },
  };
  const source = { kind: "per-kilometer", amount: 0, currency: "EUR" };
  const copied = copyZoneTravelCost(original, source);
  assert.deepEqual(copied.settings.travelCost, source);
  assert.equal(copied.travelAmounts["per-kilometer"], 0);
  assert.notEqual(copied.settings.travelCost, source);
  assert.deepEqual(original.settings.travelCost, { kind: "free" });
  assert.match(
    formatMapZoneTravelCost(source, "Kostenlos", "de-DE"),
    /0,00\s?€\/km/,
  );
  assert.equal(
    formatMapZoneTravelCost({ kind: "free" }, "Kostenlos", "de-DE"),
    "Kostenlos",
  );
});

test("weekly RRULE helpers preserve only the supported deterministic subset", () => {
  assert.equal(
    createZoneWeeklyRRule({
      weekdayIds: ["MO", "MO", "WE"],
      intervalWeeks: 2,
      monthIds: [12, 1, 12],
      endDate: "2027-01-31",
    }),
    "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;BYMONTH=1,12;UNTIL=20270131",
  );
  assert.deepEqual(
    parseZoneWeeklyRRule(
      "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,MO,WE;BYMONTH=1,12;UNTIL=20270131",
    ),
    {
      weekdayIds: ["MO", "WE"],
      intervalWeeks: 2,
      monthIds: [1, 12],
      endDate: "2027-01-31",
    },
  );
  assert.equal(parseZoneWeeklyRRule("FREQ=MONTHLY;FREQ=WEEKLY;BYDAY=MO"), null);
  assert.equal(parseZoneWeeklyRRule("FREQ=WEEKLY;BYDAY=MO;COUNT=4"), null);
  assert.equal(parseZoneWeeklyRRule("FREQ=WEEKLY;BYDAY=MO;BYMONTH="), null);
  assert.equal(parseZoneWeeklyRRule("FREQ=WEEKLY;BYDAY=MO;UNTIL="), null);
  assert.equal(
    parseZoneWeeklyRRule(
      createZoneWeeklyRRule({ weekdayIds: ["MO"], intervalWeeks: 0 }),
    ),
    null,
  );
  assert.equal(
    parseZoneWeeklyRRule(
      createZoneWeeklyRRule({ weekdayIds: ["MO"], intervalWeeks: Number.NaN }),
    ),
    null,
  );
});

test("recurrence anchors follow weekday edits until the date is edited explicitly", () => {
  assert.equal(matchingDateInAnchorWeek("", ["WE"]), "");
  assert.equal(matchingDateInAnchorWeek("2026-10-19", ["WE"]), "2026-10-21");
  assert.equal(
    matchingDateInAnchorWeek("2026-10-19", ["MO"], [11]),
    "2026-11-02",
  );
  assert.deepEqual(
    defaultZoneRecurrence(
      "Europe/Berlin",
      ["MO"],
      new Date("2026-10-21T10:00:00Z"),
    ),
    {
      kind: "recurring",
      rrule: "FREQ=WEEKLY;BYDAY=MO",
      startDate: "2026-10-26",
      timeZone: "Europe/Berlin",
    },
  );
});

test("next occurrences combine months and week intervals with an inclusive end", () => {
  const availability = {
    kind: "recurring",
    rrule: "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;BYMONTH=1,2;UNTIL=20260228",
    startDate: "2026-01-05",
    timeZone: "Europe/Berlin",
  };
  assert.deepEqual(
    nextZoneOccurrences(availability, new Date("2026-01-05T08:00:00Z")),
    ["2026-01-05", "2026-01-07", "2026-01-19"],
  );
  assert.deepEqual(
    nextZoneOccurrences(
      {
        ...availability,
        rrule: "FREQ=WEEKLY;BYDAY=MO;UNTIL=20260105",
      },
      new Date("2026-01-04T08:00:00Z"),
    ),
    ["2026-01-05"],
  );
});

test("occurrence preview uses today's date in the configured timezone", () => {
  const now = new Date("2026-01-04T23:30:00Z");
  assert.deepEqual(
    nextZoneOccurrences(
      {
        kind: "recurring",
        rrule: "FREQ=WEEKLY;BYDAY=MO",
        startDate: "2026-01-05",
        timeZone: "Europe/Berlin",
      },
      now,
      1,
    ),
    ["2026-01-05"],
  );
  assert.deepEqual(
    nextZoneOccurrences(
      {
        kind: "recurring",
        rrule: "FREQ=WEEKLY;BYDAY=SU",
        startDate: "2026-01-04",
        timeZone: "America/New_York",
      },
      now,
      1,
    ),
    ["2026-01-04"],
  );
});

test("recurrence start must satisfy weekday and month restrictions", () => {
  assert.equal(
    normalizeZoneSettings({
      availability: {
        kind: "recurring",
        rrule: "FREQ=WEEKLY;BYDAY=MO;BYMONTH=11",
        startDate: "2026-10-19",
        timeZone: "Europe/Berlin",
      },
    }).error,
    "recurrence",
  );
});

test("map clicks can switch away from a current draft but ignore its own shape", () => {
  assert.equal(selectableZoneForMapClick(zones, zones[0], zones[0].id), null);
  assert.equal(
    selectableZoneForMapClick(zones, zones[0], zones[1].id),
    zones[1],
  );
});

test("empty editor gives three centered starts without the selection pill", () => {
  const html = render({ zones: [] });
  assert.match(html, /data-empty="true"/);
  assert.match(html, /Erstelle deine erste Zone/);
  assert.match(html, />Umkreis<\/strong>/);
  assert.match(html, />Postleitzahlen<\/strong>/);
  assert.match(html, />Freie Grenze<\/strong>/);
  assert.doesNotMatch(html, /class="k-map-zone-editor__toolbar"/);
});

test("automatic framing options reject unsafe limits", () => {
  assert.throws(
    () =>
      renderToStaticMarkup(
        React.createElement(KMap, {
          mapStyle,
          center: [13.4, 52.5],
          fitContent: true,
          fitCoordinates: zones[0].coordinates,
          fitMaxZoom: -1,
        }),
      ),
    /fitMaxZoom/,
  );
  assert.throws(
    () =>
      renderToStaticMarkup(
        React.createElement(KMap, {
          mapStyle,
          center: [13.4, 52.5],
          fitContent: true,
          fitCoordinates: zones[0].coordinates,
          fitDurationMs: Number.NaN,
        }),
      ),
    /fitDurationMs/,
  );
});

test("recurrence units preserve calendar dates and skip missing month days", () => {
  const preview = (rrule, startDate) =>
    nextZoneOccurrences(
      { kind: "recurring", rrule, startDate, timeZone: "UTC" },
      new Date(startDate + "T00:00:00Z"),
    );
  assert.deepEqual(preview("FREQ=DAILY;INTERVAL=3", "2026-01-01"), [
    "2026-01-01",
    "2026-01-04",
    "2026-01-07",
  ]);
  assert.deepEqual(preview("FREQ=MONTHLY", "2026-01-31"), [
    "2026-01-31",
    "2026-03-31",
    "2026-05-31",
  ]);
  assert.deepEqual(preview("FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2", "2026-01-12"), [
    "2026-01-12",
    "2026-02-09",
    "2026-03-09",
  ]);
  assert.deepEqual(preview("FREQ=YEARLY", "2024-02-29"), [
    "2024-02-29",
    "2028-02-29",
    "2032-02-29",
  ]);
  for (const frequency of ["DAILY", "MONTHLY", "YEARLY"]) {
    const rule = createZoneWeeklyRRule({
      frequency,
      intervalWeeks: 3,
      weekdayIds: [],
      monthIds: [],
    });
    assert.equal(parseZoneWeeklyRRule(rule).frequency, frequency);
    assert.equal(
      normalizeZoneSettings({
        availability: {
          kind: "recurring",
          rrule: rule,
          startDate: "2026-01-12",
          timeZone: "UTC",
        },
      }).error,
      null,
    );
  }
});
