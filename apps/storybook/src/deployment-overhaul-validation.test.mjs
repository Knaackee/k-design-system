import assert from "node:assert/strict";
import test from "node:test";
import {
  isEinsatzDate,
  isEinsatzEntryValid,
  isEinsatzZoneValid,
  postalCodeError,
} from "./deployment-overhaul-validation.ts";

const appointment = {
  id: "example",
  kind: "private",
  title: "Termin",
  date: "2026-11-09",
  until: "2026-11-09",
  from: "12:00",
  to: "13:00",
  allDay: false,
  address: "Beispielstraße 3",
  mode: "car",
  minutes: 15,
};
const zone = {
  id: "zone",
  name: "Umkreis",
  type: "radius",
  radius: 15,
  postal: [],
  days: ["Mo"],
  from: "09:00",
  to: "18:00",
  fee: "0",
  lead: "1 Tag",
  active: true,
  color: "#0ea5e9",
};

test("missing and invalid dates cannot enter the exception list", () => {
  for (const date of ["", "2026-02-30", "not-a-date"]) {
    assert.equal(isEinsatzDate(date), false);
    assert.equal(isEinsatzEntryValid({ ...appointment, date }, false), false);
    assert.equal(
      isEinsatzEntryValid({ ...appointment, until: date }, false),
      false,
    );
  }
  assert.equal(isEinsatzEntryValid(appointment, false), true);
});
test("postal zones validate new entries and preserve leading zeros", () => {
  assert.equal(postalCodeError(" 01067 ", []), "");
  assert.notEqual(postalCodeError("93047", ["93047"]), "");
  for (const value of ["", "9304", "930471", "ABCDE", "93 047"]) {
    assert.notEqual(postalCodeError(value, []), "");
  }
  assert.equal(
    isEinsatzZoneValid({ ...zone, type: "postal", postal: ["01067"] }),
    true,
  );
  for (const postal of [[], ["93047", "93047"], ["ABCDE"]]) {
    assert.equal(
      isEinsatzZoneValid({ ...zone, type: "postal", postal }),
      false,
    );
  }
});
test("appointments and transport require times and a location", () => {
  for (const from of ["", "25:00", "12:99"]) {
    assert.equal(isEinsatzEntryValid({ ...appointment, from }, false), false);
    assert.equal(isEinsatzEntryValid({ ...appointment, from }, true), false);
  }
  assert.equal(isEinsatzEntryValid({ ...appointment, to: "" }, false), false);
  assert.equal(
    isEinsatzEntryValid({ ...appointment, address: " " }, false),
    false,
  );
  assert.equal(
    isEinsatzEntryValid({ ...appointment, address: " " }, true),
    false,
  );
  assert.equal(
    isEinsatzEntryValid({ ...appointment, minutes: NaN }, true),
    false,
  );
  assert.equal(isEinsatzEntryValid(appointment, true), true);
});
test("all-day absence needs dates, timed ranges must be ordered", () => {
  assert.equal(
    isEinsatzEntryValid(
      {
        ...appointment,
        kind: "absence",
        allDay: true,
        from: "",
        to: "",
        address: "",
      },
      false,
    ),
    true,
  );
  assert.equal(
    isEinsatzEntryValid({ ...appointment, from: "14:00" }, false),
    false,
  );
  assert.equal(
    isEinsatzEntryValid({ ...appointment, until: "2026-11-08" }, false),
    false,
  );
  assert.equal(
    isEinsatzEntryValid(
      { ...appointment, until: "2026-11-10", from: "20:00", to: "08:00" },
      false,
    ),
    true,
  );
});
test("zone hours cannot be blank or inverted", () => {
  assert.equal(isEinsatzZoneValid(zone), true);
  for (const patch of [
    { from: "" },
    { to: "" },
    { to: "08:00" },
    { days: [] },
    { fee: "-1" },
    { fee: "" },
  ]) {
    assert.equal(isEinsatzZoneValid({ ...zone, ...patch }), false);
  }
});
